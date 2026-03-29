import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../data/db.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';
import '../models/listing.dart';
import '../models/pantry_item.dart';
import '../services/pantry_notification_service.dart';
import '../services/local_notification_service.dart';
import 'post_listing_screen.dart';
import 'profile_screen.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen>
    with SingleTickerProviderStateMixin {
  static final RegExp _ymdPattern = RegExp(
    r'(\d{4})[./-](\d{1,2})[./-](\d{1,2})',
  );
  static final RegExp _mdyOrDmyPattern = RegExp(
    r'(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})',
  );
  static final RegExp _monthYearPattern = RegExp(
    r'\b(\d{1,2})[./-](\d{2,4})\b',
  );
  static final RegExp _monthNamePattern = RegExp(
    r'\b(\d{1,2})\s*(jan|january|feb|february|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|sept|september|oct|october|nov|november|dec|december)\s*(\d{2,4})\b',
    caseSensitive: false,
  );
  static final RegExp _spacedMonthNamePattern = RegExp(
    r'\b(\d{1,2})\s+(jan|january|feb|february|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|sept|september|oct|october|nov|november|dec|december)\s+(\d{2,4})\b',
    caseSensitive: false,
  );

  // FIXED: Adjusted to not use negative lookahead at the end and strictly look for 2 digits for the year
  static final RegExp _compactMonthNamePattern = RegExp(
    r'(?<!\d)(\d{1,2})(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)(\d{2})',
    caseSensitive: false,
  );

  final ImagePicker _imagePicker = ImagePicker();
  List<PantryItem> myPantry = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  String? _deviceId;
  bool _notifPermissionRequested = false;

  // Highlight state
  String? _highlightedItemId;
  late final AnimationController _highlightController;
  late final Animation<double> _highlightAnim;
  final Map<String, GlobalKey> _itemKeys = {};
  String? _lastHandledHighlight;
  final ScrollController _expiredScrollController = ScrollController();
  final ScrollController _expiringScrollController = ScrollController();

  static List<String> get _categories => FreshCycleTheme.foodCategories;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _highlightAnim = CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    );
    _loadPantry();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = context.read<NavigationProvider>();
    nav.removeListener(_onNavChanged);
    nav.addListener(_onNavChanged);
  }

  void _onNavChanged() {
    final nav = context.read<NavigationProvider>();
    final itemId = nav.pantryHighlightItemId;
    if (itemId != null && itemId != _lastHandledHighlight) {
      _lastHandledHighlight = itemId;
      nav.clearPantryHighlight();
      _triggerHighlight(itemId);
    }
  }

  void _triggerHighlight(String itemId) {
    setState(() => _highlightedItemId = itemId);
    _highlightController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final item = myPantry.firstWhere(
        (i) => i.id == itemId,
        orElse: () => myPantry.first,
      );
      final expiry = DateTime(
        item.computedExpiryDate.year,
        item.computedExpiryDate.month,
        item.computedExpiryDate.day,
      );
      final isExpired = expiry.isBefore(today);

      if (isExpired) {
        final expiredItems = myPantry.where((i) {
          final e = DateTime(
            i.computedExpiryDate.year,
            i.computedExpiryDate.month,
            i.computedExpiryDate.day,
          );
          return e.isBefore(today);
        }).toList();
        final idx = expiredItems.indexWhere((i) => i.id == itemId);
        if (idx >= 0 && _expiredScrollController.hasClients) {
          _expiredScrollController.animateTo(
            idx * 152.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      } else {
        final expiringItems = myPantry.where((i) {
          final e = DateTime(
            i.computedExpiryDate.year,
            i.computedExpiryDate.month,
            i.computedExpiryDate.day,
          );
          final d = e.difference(today).inDays;
          return !e.isBefore(today) && d <= 3;
        }).toList();
        final idx = expiringItems.indexWhere((i) => i.id == itemId);
        if (idx >= 0 && _expiringScrollController.hasClients) {
          _expiringScrollController.animateTo(
            idx * 152.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      }
    });

    // Clear highlight after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _highlightController.stop();
        _highlightController.reset();
        setState(() => _highlightedItemId = null);
      }
    });
  }

  @override
  void dispose() {
    context.read<NavigationProvider>().removeListener(_onNavChanged);
    _highlightController.dispose();
    _expiredScrollController.dispose();
    _expiringScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPantry() async {
    setState(() => _isLoading = true);
    try {
      _deviceId ??= await DB.getDeviceId();
      final authUser = DB.getCurrentUser();

      List<Map<String, dynamic>> rows;

      if (authUser != null) {
        // Authenticated: fetch by user_id
        rows = await DB.client
            .from('pantry_items')
            .select()
            .eq('user_id', authUser['id'])
            .eq('is_consumed', false)
            .order('expiry_date', ascending: true);
      } else {
        // Guest: fetch by device_id where user_id is null
        rows = await DB.client
            .from('pantry_items')
            .select()
            .eq('device_id', _deviceId!)
            .isFilter('user_id', null)
            .eq('is_consumed', false)
            .order('expiry_date', ascending: true);
      }

      final items = rows.map((r) => PantryItem.fromMap(r)).toList();
      setState(() {
        myPantry = items;
        _isLoading = false;
      });
      await PantryNotificationService.checkAndNotify(items);
      if (mounted) {
        final authUser = DB.getCurrentUser();
        if (authUser != null) {
          context.read<NotificationsProvider>().initialize(
            authUser['id'] as String,
          );
        } else {
          context.read<NotificationsProvider>().initializeGuest();
        }
      }
      if (!_notifPermissionRequested) {
        _notifPermissionRequested = true;
        await LocalNotificationService.requestPermission();
      }
      await LocalNotificationService.schedulePantryNotifications(items);
    } catch (e) {
      debugPrint('Load pantry error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveItem(PantryItem item, {required bool isEditing}) async {
    try {
      _deviceId ??= await DB.getDeviceId();
      final authUser = DB.getCurrentUser();
      final userId = authUser?['id'] as String?;

      final payload = item.toMap(userId: userId);

      if (isEditing) {
        await DB.client.from('pantry_items').update(payload).eq('id', item.id);
      } else {
        await DB.client.from('pantry_items').insert(payload);
      }
    } catch (e) {
      debugPrint('Save item error: $e');
      rethrow;
    }
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await DB.client.from('pantry_items').delete().eq('id', itemId);
    } catch (e) {
      debugPrint('Delete item error: $e');
      rethrow;
    }
  }

  Future<void> _deleteExpiredItems(List<PantryItem> expired) async {
    try {
      final ids = expired.map((i) => i.id).toList();
      await DB.client.from('pantry_items').delete().inFilter('id', ids);
    } catch (e) {
      debugPrint('Delete expired error: $e');
      rethrow;
    }
  }

  UrgencyLevel _calculateUrgency(DateTime expiry) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    final diff = expiryDay.difference(today).inDays;
    if (diff <= 1) return UrgencyLevel.critical;
    if (diff <= 3) return UrgencyLevel.soon;
    return UrgencyLevel.safe;
  }

  UrgencyLevel _calculateUrgencyFromRelative(int relativeDays) {
    if (relativeDays <= 1) return UrgencyLevel.critical;
    if (relativeDays <= 3) return UrgencyLevel.soon;
    return UrgencyLevel.safe;
  }

  void _sortPantry() {
    myPantry.sort((a, b) {
      int dateCompare = a.computedExpiryDate.compareTo(b.computedExpiryDate);
      if (dateCompare != 0) return dateCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  String lookupScannedName(String scannedCode) {
    const demoDatabase = {
      '1200108000240': 'Cheetos Crunchy 250g',
      '1200108000523': "Lay's Cheddar & Sour Cream 170g",
    };
    return demoDatabase[scannedCode] ?? 'Scanned Item ($scannedCode)';
  }

  Future<DateTime?> _scanExpiryDateFromImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Scan with camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    debugPrint('[OCR] Image source selected: $source');
    if (source == null) return null;

    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return null;
      }
      if (!status.isGranted) return null;
    }

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    debugPrint('[OCR] Picked image path: ${picked?.path}');
    if (picked == null) return null;

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(picked.path);
      final recognized = await recognizer.processImage(inputImage);
      debugPrint('[OCR] Raw recognized text:\n${recognized.text}');
      final parsed = _extractExpiryDate(recognized.text);
      debugPrint('[OCR] Final parsed expiry date: $parsed');
      return parsed;
    } on MissingPluginException catch (e) {
      debugPrint('[OCR] MissingPluginException: $e');
      debugPrint(
        '[OCR] Plugin not registered. Do a full app restart (stop + flutter run), not hot reload.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'OCR plugin not initialized. Please fully restart the app.',
            ),
          ),
        );
      }
      return null;
    } on PlatformException catch (e) {
      debugPrint('[OCR] PlatformException: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[OCR] Unexpected OCR error: $e');
      return null;
    } finally {
      try {
        await recognizer.close();
      } on MissingPluginException catch (e) {
        debugPrint('[OCR] recognizer.close MissingPluginException: $e');
      } catch (e) {
        debugPrint('[OCR] recognizer.close error: $e');
      }
    }
  }

  // FIXED: Adjusted string cleaning logic to preserve spaces
  DateTime? _extractExpiryDate(String text) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Normalize separators so OCR strings like "12 FEB, 2027" are parsable.
    final normalized = text
        .toUpperCase()
        .replaceAll('\n', ' ')
        .replaceAll(',', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Instead of stripping everything, just normalize punctuation separators to help the regex.
    // This preserves the '19APR26' as a distinct block even if 'C3A' follows separated by space.
    final cleaned = normalized.replaceAll(RegExp(r'[.\-:]'), '');
    debugPrint('[OCR] Normalized text: $normalized');
    debugPrint('[OCR] Cleaned text: $cleaned');

    // Prioritize common stamped labels like "19APR26" or "EXP19APR26".
    for (final match in _compactMonthNamePattern.allMatches(cleaned)) {
      debugPrint('[OCR] Compact match: ${match.group(0)}');
      final day = int.tryParse(match.group(1)!);
      final month = _monthFromName(match.group(2)!);
      final rawYear = int.tryParse(match.group(3)!);
      final year = _normalizeYear(rawYear);
      final parsed = _safeDate(year, month, day);
      debugPrint('[OCR] Compact parsed candidate: $parsed');
      if (parsed != null && !parsed.isBefore(today)) return parsed;
    }

    // Explicitly support spaced month format like "12 FEB 2027".
    for (final match in _spacedMonthNamePattern.allMatches(normalized)) {
      debugPrint('[OCR] Spaced month-name match: ${match.group(0)}');
      final day = int.tryParse(match.group(1)!);
      final month = _monthFromName(match.group(2)!);
      final rawYear = int.tryParse(match.group(3)!);
      final year = _normalizeYear(rawYear);
      final parsed = _safeDate(year, month, day);
      debugPrint('[OCR] Spaced month-name parsed candidate: $parsed');
      if (parsed != null && !parsed.isBefore(today)) return parsed;
    }

    for (final match in _ymdPattern.allMatches(normalized)) {
      debugPrint('[OCR] YMD match: ${match.group(0)}');
      final year = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final day = int.tryParse(match.group(3)!);
      final parsed = _safeDate(year, month, day);
      debugPrint('[OCR] YMD parsed candidate: $parsed');
      if (parsed != null && !parsed.isBefore(today)) return parsed;
    }

    for (final match in _mdyOrDmyPattern.allMatches(normalized)) {
      debugPrint('[OCR] MDY/DMY match: ${match.group(0)}');
      final first = int.tryParse(match.group(1)!);
      final second = int.tryParse(match.group(2)!);
      final rawYear = int.tryParse(match.group(3)!);
      final year = _normalizeYear(rawYear);
      if (first == null || second == null || year == null) continue;

      DateTime? parsed;
      if (first > 12) {
        parsed = _safeDate(year, second, first);
      } else {
        parsed = _safeDate(year, first, second);
      }

      debugPrint('[OCR] MDY/DMY parsed candidate: $parsed');
      if (parsed != null && !parsed.isBefore(today)) return parsed;
    }

    for (final match in _monthNamePattern.allMatches(normalized)) {
      debugPrint('[OCR] Month-name match: ${match.group(0)}');
      final day = int.tryParse(match.group(1)!);
      final month = _monthFromName(match.group(2)!);
      final rawYear = int.tryParse(match.group(3)!);
      final year = _normalizeYear(rawYear);
      final parsed = _safeDate(year, month, day);
      debugPrint('[OCR] Month-name parsed candidate: $parsed');
      if (parsed != null && !parsed.isBefore(today)) return parsed;
    }

    for (final match in _monthYearPattern.allMatches(normalized)) {
      debugPrint('[OCR] Month-year match: ${match.group(0)}');
      final month = int.tryParse(match.group(1)!);
      final rawYear = int.tryParse(match.group(2)!);
      final year = _normalizeYear(rawYear);
      if (month == null || year == null) continue;
      final parsed = _safeDate(year, month, 1);
      debugPrint('[OCR] Month-year parsed candidate: $parsed');
      if (parsed != null && !parsed.isBefore(today)) return parsed;
    }

    debugPrint(
      '[OCR] No valid future expiry date detected from recognized text.',
    );
    return null;
  }

  int? _normalizeYear(int? rawYear) {
    if (rawYear == null) return null;
    if (rawYear >= 100) return rawYear;
    return 2000 + rawYear;
  }

  int? _monthFromName(String name) {
    final key = name.toLowerCase();
    const months = {
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'sept': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    };
    return months[key];
  }

  DateTime? _safeDate(int? year, int? month, int? day) {
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  void _showAddItemSheet({PantryItem? existingItem, int? index}) {
    final isEditing = existingItem != null;
    final nameController = TextEditingController(text: existingItem?.name);
    final costController = TextEditingController(
      text: existingItem?.cost?.toString(),
    );
    final relativeDaysController = TextEditingController(
      text:
          (existingItem != null &&
              existingItem.expiryType == ExpiryType.relative)
          ? existingItem.relativeDays.toString()
          : '7',
    );

    DateTime selectedDate =
        existingItem?.expiryDate ?? DateTime.now().add(const Duration(days: 7));
    String selectedCategory =
        (existingItem != null && _categories.contains(existingItem.category))
        ? existingItem.category
        : 'Other';
    ExpiryType selectedExpiryType = existingItem != null
        ? existingItem.expiryType
        : ExpiryType.absolute;
    int selectedRelativeDays = existingItem != null
        ? existingItem.relativeDays
        : 7;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Item' : 'Add to Pantry',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: FreshCycleTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // Item Name with Barcode Scanner
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    hintText: 'e.g. Fresh Milk',
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.barcode_reader,
                        color: FreshCycleTheme.primary,
                      ),
                      onPressed: () async {
                        final status = await Permission.camera.request();
                        if (status.isPermanentlyDenied) {
                          openAppSettings();
                          return;
                        }
                        if (!status.isGranted) return;
                        try {
                          var result = await BarcodeScanner.scan();
                          if (result.type == ResultType.Barcode) {
                            setSheetState(() {
                              nameController.text = lookupScannedName(
                                result.rawContent,
                              );
                            });
                          }
                        } catch (e) {
                          debugPrint('Scanner error: $e');
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories
                      .where((c) => c != 'All')
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheetState(() => selectedCategory = v);
                  },
                ),
                const SizedBox(height: 16),

                // Cost
                TextField(
                  controller: costController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cost',
                    prefixText: '₱ ',
                    hintText: '0.00',
                  ),
                ),
                const SizedBox(height: 16),

                // Expiry Type Toggle
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: FreshCycleTheme.borderColor,
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setSheetState(
                                  () =>
                                      selectedExpiryType = ExpiryType.absolute,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        selectedExpiryType ==
                                            ExpiryType.absolute
                                        ? FreshCycleTheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Specific Date',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            selectedExpiryType ==
                                                ExpiryType.absolute
                                            ? Colors.white
                                            : FreshCycleTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setSheetState(
                                  () =>
                                      selectedExpiryType = ExpiryType.relative,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        selectedExpiryType ==
                                            ExpiryType.relative
                                        ? FreshCycleTheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Expires In',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            selectedExpiryType ==
                                                ExpiryType.relative
                                            ? Colors.white
                                            : FreshCycleTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selectedExpiryType == ExpiryType.absolute)
                        ListTile(
                          title: const Text(
                            'Expiry Date',
                            style: TextStyle(
                              fontSize: 14,
                              color: FreshCycleTheme.textSecondary,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('yyyy-MM-dd').format(selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: FreshCycleTheme.textPrimary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Scan expiry date',
                                icon: const Icon(
                                  Icons.document_scanner_outlined,
                                  color: FreshCycleTheme.primary,
                                ),
                                onPressed: () async {
                                  final scannedDate =
                                      await _scanExpiryDateFromImage();
                                  if (!mounted) return;

                                  if (scannedDate == null) {
                                    debugPrint(
                                      '[OCR] Scan finished but no date selected in UI.',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No valid expiry date detected from image',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setSheetState(
                                    () => selectedDate = scannedDate,
                                  );
                                  debugPrint(
                                    '[OCR] UI selectedDate updated to: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Detected expiry date: ${DateFormat('yyyy-MM-dd').format(scannedDate)}',
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: FreshCycleTheme.primary,
                              ),
                            ],
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                              ),
                              firstDate: DateTime(
                                DateTime.now().year,
                                DateTime.now().month,
                                DateTime.now().day,
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 3650),
                              ),
                              builder: (context, child) => Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: FreshCycleTheme.primary,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              setSheetState(() => selectedDate = picked);
                            }
                          },
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: relativeDaysController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final days = int.tryParse(value);
                                    if (days != null && days > 0) {
                                      setSheetState(
                                        () => selectedRelativeDays = days,
                                      );
                                    } else if (days != null && days <= 0) {
                                      setSheetState(
                                        () => selectedRelativeDays = 1,
                                      );
                                      relativeDaysController.text = '1';
                                    }
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Days',
                                    hintText: 'e.g. 7',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Text(
                                    'day${selectedRelativeDays == 1 ? '' : 's'} from now',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: FreshCycleTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save / Update Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter an item name'),
                          ),
                        );
                        return;
                      }

                      final today = DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      );
                      if (selectedExpiryType == ExpiryType.absolute &&
                          DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                          ).isBefore(today)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Expiry date must be today or in the future',
                            ),
                          ),
                        );
                        return;
                      }
                      if (selectedExpiryType == ExpiryType.relative &&
                          selectedRelativeDays <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Days must be at least 1'),
                          ),
                        );
                        return;
                      }

                      final urgency = selectedExpiryType == ExpiryType.absolute
                          ? _calculateUrgency(selectedDate)
                          : _calculateUrgencyFromRelative(selectedRelativeDays);

                      final messenger = ScaffoldMessenger.of(context);
                      _deviceId ??= await DB.getDeviceId();

                      final newItem = PantryItem(
                        id: isEditing ? existingItem.id : uuid.v4(),
                        deviceId: _deviceId!,
                        name: nameController.text.trim(),
                        category: selectedCategory,
                        expiryDate: selectedDate,
                        relativeDays: selectedRelativeDays,
                        expiryType: selectedExpiryType,
                        cost: double.tryParse(costController.text),
                        urgency: urgency,
                      );

                      Navigator.pop(context);

                      try {
                        await _saveItem(newItem, isEditing: isEditing);
                        setState(() {
                          if (isEditing) {
                            myPantry[index!] = newItem;
                          } else {
                            myPantry.insert(0, newItem);
                          }
                          _sortPantry();
                        });
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Failed to save item: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: FreshCycleTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'Update Item' : 'Add to Pantry',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Convert to Listing ────────────────────────────────────────────────────────────

  Future<void> _convertToListing(PantryItem item) async {
    final auth = context.read<AuthProvider>();

    if (auth.user == null) {
      // Show login/register prompt
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Login required'),
          content: const Text(
            'You need an account to post listings. Would you like to login or register?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: FreshCycleTheme.primary,
              ),
              child: const Text('Login / Register'),
            ),
          ],
        ),
      );

      if (proceed != true || !context.mounted) return;

      // Navigate to profile screen for login/register
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ).then((_) {
        // After returning from profile, check if logged in and try again
        if (context.mounted) {
          final authAfter = context.read<AuthProvider>();
          if (authAfter.isLoggedIn) {
            _navigateToPostListing(item);
          }
        }
      });
      return;
    }

    // User is logged in, navigate to post listing screen with prefilled data
    _navigateToPostListing(item);
  }

  void _navigateToPostListing(PantryItem item) {
    final authUser = context.read<AuthProvider>().user;

    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to post listings')),
      );
      return;
    }

    // Create a minimal Listing object to prefetch form data
    // Use actual user ID to avoid UUID error when saving
    final prefilledListing = Listing(
      id: '', // Empty ID - will be generated on save
      sellerId: authUser.id,
      type: ListingType.selling,
      title: item.name,
      description: '',
      category: item.category,
      price: item.cost,
      originalPrice: item.cost,
      expiryDate: item.computedExpiryDate,
      postedAt: DateTime.now(),
      urgency: item.urgency,
      images: [],
      isFree: false,
      allowDelivery: false,
      dealLocation: '',
      seller: authUser.toSellerProfile(),
      tags: [],
      isSaved: false,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostListingScreen(existingListing: prefilledListing),
      ),
    );
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(PantryItem item, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.name}" from your pantry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _deleteItem(item.id);
        setState(() {
          myPantry.removeAt(index);
          _sortPantry();
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${item.name} deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ── Progress bar helpers ────────────────────────────────────────────────────

  Color _progressBarColor(PantryItem item) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final expiry = DateTime(
      item.computedExpiryDate.year,
      item.computedExpiryDate.month,
      item.computedExpiryDate.day,
    );
    final daysLeft = expiry.difference(today).inDays;
    if (daysLeft <= 1) return FreshCycleTheme.urgencyCritical;
    if (daysLeft <= 3) return FreshCycleTheme.urgencySoon;
    return FreshCycleTheme.urgencySafe;
  }

  double _progressValue(PantryItem item) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final expiry = DateTime(
      item.computedExpiryDate.year,
      item.computedExpiryDate.month,
      item.computedExpiryDate.day,
    );
    final daysLeft = expiry.difference(today).inDays.clamp(0, 9999);
    return (daysLeft / 7.0).clamp(0.0, 1.0);
  }

  Widget _buildCategoryIcon(
    dynamic icon, {
    required double size,
    required Color color,
  }) {
    if (icon is IconData) {
      return Icon(icon, size: size, color: color);
    }
    if (icon is List<List<dynamic>>) {
      return HugeIcon(icon: icon, size: size, color: color);
    }
    return Icon(Icons.inventory_2_outlined, size: size, color: color);
  }

  Widget _buildExpiringCard(PantryItem item) {
    final barColor = _progressBarColor(item);
    final progress = _progressValue(item);
    final index = myPantry.indexOf(item);
    final isHighlighted = _highlightedItemId == item.id;

    return AnimatedBuilder(
      animation: _highlightAnim,
      builder: (context, child) {
        final glow = isHighlighted ? _highlightAnim.value : 0.0;
        return GestureDetector(
          onLongPress: () =>
              _showAddItemSheet(existingItem: item, index: index),
          child: Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? Color.lerp(
                      Colors.white,
                      FreshCycleTheme.urgencySoonBg,
                      glow,
                    )!
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isHighlighted
                    ? FreshCycleTheme.urgencySoon.withValues(alpha: glow)
                    : FreshCycleTheme.borderColor,
                width: isHighlighted ? 2 : 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: urgencyBgColor(item.urgency),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.categoryIcon,
                        size: 18,
                        color: urgencyColor(item.urgency),
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: FreshCycleTheme.textSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showAddItemSheet(existingItem: item, index: index);
                        } else if (value == 'delete') {
                          _confirmDelete(item, index);
                        } else if (value == 'list') {
                          _convertToListing(item);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'list',
                          child: Row(
                            children: [
                              Icon(Icons.storefront_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Make into listing'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.red,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: FreshCycleTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  item.daysLeft,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: urgencyColor(item.urgency),
                  ),
                ),
                if (item.cost != null)
                  Text(
                    '₱${item.cost!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: FreshCycleTheme.textSecondary,
                    ),
                  ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: barColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpiredCard(PantryItem item) {
    final index = myPantry.indexOf(item);
    final isHighlighted = _highlightedItemId == item.id;

    return AnimatedBuilder(
      animation: _highlightAnim,
      builder: (context, child) {
        final glow = isHighlighted ? _highlightAnim.value : 0.0;
        return GestureDetector(
          onLongPress: () => _confirmDelete(item, index),
          child: Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? Color.lerp(
                      FreshCycleTheme.urgencyCriticalBg,
                      FreshCycleTheme.urgencyCritical.withValues(alpha: 0.15),
                      glow,
                    )!
                  : FreshCycleTheme.urgencyCriticalBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isHighlighted
                    ? FreshCycleTheme.urgencyCritical.withValues(
                        alpha: 0.3 + glow * 0.7,
                      )
                    : FreshCycleTheme.urgencyCritical.withValues(alpha: 0.3),
                width: isHighlighted ? 2 : 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: FreshCycleTheme.urgencyCritical.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.categoryIcon,
                        size: 18,
                        color: FreshCycleTheme.urgencyCritical,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: FreshCycleTheme.textSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showAddItemSheet(existingItem: item, index: index);
                        } else if (value == 'delete') {
                          _confirmDelete(item, index);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.red,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: FreshCycleTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                const Text(
                  'Expired',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: FreshCycleTheme.urgencyCritical,
                  ),
                ),
                if (item.cost != null)
                  Text(
                    '₱${item.cost!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: FreshCycleTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemCard(PantryItem item, int index) {
    final barColor = _progressBarColor(item);
    final progress = _progressValue(item);
    _itemKeys[item.id] ??= GlobalKey();

    return GestureDetector(
      key: _itemKeys[item.id],
      onLongPress: () => _showAddItemSheet(existingItem: item, index: index),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: FreshCycleTheme.borderColor,
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: urgencyBgColor(item.urgency),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.categoryIcon,
                  color: urgencyColor(item.urgency),
                ),
              ),
              title: Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      item.daysLeft,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: urgencyColor(item.urgency),
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      ' • ',
                      style: TextStyle(color: FreshCycleTheme.textHint),
                    ),
                    Text(
                      item.category,
                      style: const TextStyle(
                        color: FreshCycleTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (item.cost != null) ...[
                      const Text(
                        ' • ',
                        style: TextStyle(color: FreshCycleTheme.textHint),
                      ),
                      Text(
                        '₱${item.cost!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: FreshCycleTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: FreshCycleTheme.textSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showAddItemSheet(existingItem: item, index: index);
                  } else if (value == 'delete') {
                    _confirmDelete(item, index);
                  } else if (value == 'list') {
                    _convertToListing(item);
                  }
                },
                itemBuilder: (context) {
                  final today = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  );
                  final expiryDay = DateTime(
                    item.computedExpiryDate.year,
                    item.computedExpiryDate.month,
                    item.computedExpiryDate.day,
                  );
                  final isExpired = expiryDay.isBefore(today);
                  return [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    if (!isExpired)
                      const PopupMenuItem(
                        value: 'list',
                        child: Row(
                          children: [
                            Icon(Icons.storefront_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('Make into listing'),
                          ],
                        ),
                      ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: barColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPantryList() {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final expired = myPantry.where((i) {
      final expiry = DateTime(
        i.computedExpiryDate.year,
        i.computedExpiryDate.month,
        i.computedExpiryDate.day,
      );
      return expiry.isBefore(today);
    }).toList();
    final expiring = myPantry.where((i) {
      if (expired.contains(i)) return false;
      final expiry = DateTime(
        i.computedExpiryDate.year,
        i.computedExpiryDate.month,
        i.computedExpiryDate.day,
      );
      final daysLeft = expiry.difference(today).inDays;
      return daysLeft <= 3;
    }).toList();
    final allRest = myPantry.toList();
    final rest = _selectedCategory == 'All'
        ? allRest
        : allRest.where((i) => i.category == _selectedCategory).toList();

    return CustomScrollView(
      slivers: [
        if (expired.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.cancel_outlined,
                    size: 16,
                    color: FreshCycleTheme.urgencyCritical,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Expired',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: FreshCycleTheme.urgencyCritical,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear all expired?'),
                          content: const Text(
                            'This will remove all expired items from your pantry.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Clear all'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        try {
                          await _deleteExpiredItems(expired);
                          setState(() {
                            myPantry.removeWhere((i) {
                              final expiry = DateTime(
                                i.computedExpiryDate.year,
                                i.computedExpiryDate.month,
                                i.computedExpiryDate.day,
                              );
                              return expiry.isBefore(today);
                            });
                            _sortPantry();
                          });
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to clear: $e')),
                            );
                          }
                        }
                      }
                    },
                    child: const Text(
                      'Clear all',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: FreshCycleTheme.urgencyCritical,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: FreshCycleTheme.urgencyCriticalBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${expired.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: FreshCycleTheme.urgencyCritical,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: ListView.builder(
                controller: _expiredScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: expired.length,
                itemBuilder: (context, i) => _buildExpiredCard(expired[i]),
              ),
            ),
          ),
        ],
        if (expiring.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: FreshCycleTheme.urgencySoon,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Expiring Soon',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: FreshCycleTheme.urgencySoon,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: FreshCycleTheme.urgencySoonBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${expiring.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: FreshCycleTheme.urgencySoon,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: ListView.builder(
                controller: _expiringScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: expiring.length,
                itemBuilder: (context, i) => _buildExpiringCard(expiring[i]),
              ),
            ),
          ),
        ],
        if (allRest.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                expiring.isEmpty && expired.isEmpty ? 16 : 8,
                16,
                6,
              ),
              child: const Text(
                'All Items',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: FreshCycleTheme.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? FreshCycleTheme.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? FreshCycleTheme.primary
                                : FreshCycleTheme.borderColor,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : FreshCycleTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          if (rest.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) =>
                      _buildItemCard(rest[i], myPantry.indexOf(rest[i])),
                  childCount: rest.length,
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: Text(
                  'No items in "$_selectedCategory"',
                  style: const TextStyle(
                    color: FreshCycleTheme.textHint,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
        if (rest.isEmpty)
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FreshCycleTheme.surfaceGray,
      appBar: AppBar(
        title: const Text(
          'My Smart Pantry',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: FreshCycleTheme.textSecondary,
            ),
            onPressed: _loadPantry,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: FreshCycleTheme.primary),
            )
          : myPantry.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.kitchen_outlined,
                    size: 64,
                    color: FreshCycleTheme.textHint,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your pantry is empty.',
                    style: TextStyle(
                      fontSize: 16,
                      color: FreshCycleTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _showAddItemSheet(),
                    icon: const Icon(Icons.add, color: FreshCycleTheme.primary),
                    label: const Text(
                      'Add your first item',
                      style: TextStyle(color: FreshCycleTheme.primary),
                    ),
                  ),
                ],
              ),
            )
          : _buildPantryList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemSheet(),
        backgroundColor: FreshCycleTheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Stuff',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
