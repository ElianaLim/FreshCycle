import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../models/listing.dart';
import '../models/pantry_item.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  List<PantryItem> myPantry = [];
  String _selectedCategory = 'All';

  static List<String> get _categories => FreshCycleTheme.foodCategories;

  // Logic to determine urgency based on date
  UrgencyLevel _calculateUrgency(DateTime expiry) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
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

  // Quick demo lookup for the scanner
  String lookupScannedName(String scannedCode) {
    Map<String, String> demoDatabase = {
      "1200108000240": "Cheetos Crunchy 250g",
    };
    return demoDatabase[scannedCode] ?? "Scanned Item ($scannedCode)";
  }

  void _sortPantry() {
    myPantry.sort((a, b) {
      // 1. Sort by Expiry Date (Earliest first)
      int dateCompare = a.computedExpiryDate.compareTo(b.computedExpiryDate);
      if (dateCompare != 0) return dateCompare;

      // 2. Final tie-breaker: Alphabetical by Name
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }
  // 3. The Interactive Bottom Sheet for Adding & Editing
  void _showAddItemSheet({PantryItem? existingItem, int? index}) {
    final isEditing = existingItem != null;
    final nameController = TextEditingController(text: existingItem?.name);
    final costController = TextEditingController(text: existingItem?.cost?.toString());
    final relativeDaysController = TextEditingController(
      text: (existingItem != null && existingItem.expiryType == ExpiryType.relative) 
        ? existingItem.relativeDays.toString() 
        : '7',
    );
    
    // Default to 7 days from now if not editing
    DateTime selectedDate = existingItem?.expiryDate ?? DateTime.now().add(const Duration(days: 7));
    String selectedCategory = (existingItem != null && _categories.contains(existingItem.category))
        ? existingItem.category
        : 'Other';
    ExpiryType selectedExpiryType = existingItem != null ? existingItem.expiryType : ExpiryType.absolute;
    int selectedRelativeDays = existingItem != null ? existingItem.relativeDays : 7;

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
                
                // Item Name with Embedded Barcode Scanner
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    hintText: 'e.g. Fresh Milk',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.barcode_reader, color: FreshCycleTheme.primary),
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
                              nameController.text = lookupScannedName(result.rawContent);
                            });
                          }
                        } catch (e) {
                          debugPrint("Scanner error: $e");
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Cost',
                    prefixText: '₱ ',
                    hintText: '0.00',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Expiry Type Toggle (Absolute Date vs Relative Days)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: FreshCycleTheme.borderColor, width: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      // Toggle Row
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setSheetState(() => selectedExpiryType = ExpiryType.absolute),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selectedExpiryType == ExpiryType.absolute 
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
                                        color: selectedExpiryType == ExpiryType.absolute 
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
                                onTap: () => setSheetState(() => selectedExpiryType = ExpiryType.relative),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selectedExpiryType == ExpiryType.relative 
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
                                        color: selectedExpiryType == ExpiryType.relative 
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
                      // Content based on selected type
                      if (selectedExpiryType == ExpiryType.absolute)
                        ListTile(
                          title: const Text("Expiry Date", style: TextStyle(fontSize: 14, color: FreshCycleTheme.textSecondary)),
                          subtitle: Text(
                            "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: FreshCycleTheme.textPrimary),
                          ),
                          trailing: const Icon(Icons.calendar_today_rounded, color: FreshCycleTheme.primary),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
                              firstDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: FreshCycleTheme.primary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
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
                                      setSheetState(() => selectedRelativeDays = days);
                                    } else if (days != null && days <= 0) {
                                      setSheetState(() => selectedRelativeDays = 1);
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
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                
                // Save/Update Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter an item name')),
                        );
                        return;
                      }
                      
                      // Validate expiry date is in the future
                      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                      if (selectedExpiryType == ExpiryType.absolute && DateTime(selectedDate.year, selectedDate.month, selectedDate.day).isBefore(today)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Expiry date must be today or in the future')),
                        );
                        return;
                      }
                      if (selectedExpiryType == ExpiryType.relative && selectedRelativeDays <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Days must be at least 1')),
                        );
                        return;
                      }
                      
                      // Calculate urgency based on expiry type
                      final urgency = selectedExpiryType == ExpiryType.absolute
                          ? _calculateUrgency(selectedDate)
                          : _calculateUrgencyFromRelative(selectedRelativeDays);

                      final newItem = PantryItem(
                        id: isEditing ? existingItem.id : DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text.trim(),
                        category: selectedCategory,
                        expiryDate: selectedDate,
                        relativeDays: selectedRelativeDays,
                        expiryType: selectedExpiryType,
                        cost: double.tryParse(costController.text),
                        urgency: urgency,
                      );
                      
                      setState(() {
                        if (isEditing) {
                          myPantry[index!] = newItem;
                        } else {
                          myPantry.insert(0, newItem);
                        }
                        _sortPantry();
                      });
                      
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: FreshCycleTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isEditing ? 'Update Item' : 'Add to Pantry',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      setState(() {
        myPantry.removeAt(index);
        _sortPantry();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} deleted')),
        );
      }
    }
  }

  Color _progressBarColor(PantryItem item) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final expiry = DateTime(item.computedExpiryDate.year, item.computedExpiryDate.month, item.computedExpiryDate.day);
    final daysLeft = expiry.difference(today).inDays;
    if (daysLeft <= 1) return FreshCycleTheme.urgencyCritical;
    if (daysLeft <= 3) return FreshCycleTheme.urgencySoon;
    return FreshCycleTheme.urgencySafe;
  }

  double _progressValue(PantryItem item) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final expiry = DateTime(item.computedExpiryDate.year, item.computedExpiryDate.month, item.computedExpiryDate.day);
    final daysLeft = expiry.difference(today).inDays.clamp(0, 9999);
    return (daysLeft / 7.0).clamp(0.0, 1.0);
  }

  Widget _buildExpiringCard(PantryItem item) {
    final barColor = _progressBarColor(item);
    final progress = _progressValue(item);
    final index = myPantry.indexOf(item);

    return GestureDetector(
      onLongPress: () => _showAddItemSheet(existingItem: item, index: index),
      child: Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FreshCycleTheme.borderColor, width: 0.5),
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
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: FreshCycleTheme.textSecondary),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showAddItemSheet(existingItem: item, index: index);
                  } else if (value == 'delete') {
                    _confirmDelete(item, index);
                  } else if (value == 'list') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Moving to marketplace... (Original Cost: ₱${item.cost ?? 0})'),
                        backgroundColor: FreshCycleTheme.primary,
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 12), Text('Edit')]),
                  ),
                  const PopupMenuItem(
                    value: 'list',
                    child: Row(children: [Icon(Icons.storefront_outlined, size: 20), SizedBox(width: 12), Text('Make into listing')]),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [Icon(Icons.delete_outline, size: 20, color: Colors.red), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.red))]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FreshCycleTheme.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            item.daysLeft,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: urgencyColor(item.urgency)),
          ),
          if (item.cost != null)
            Text(
              '₱${item.cost!.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 11, color: FreshCycleTheme.textSecondary),
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
  }

  Widget _buildExpiredCard(PantryItem item) {
    final index = myPantry.indexOf(item);
    return GestureDetector(
      onLongPress: () => _confirmDelete(item, index),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        decoration: BoxDecoration(
          color: FreshCycleTheme.urgencyCriticalBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FreshCycleTheme.urgencyCritical.withValues(alpha: 0.3), width: 0.5),
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
                    color: FreshCycleTheme.urgencyCritical.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.categoryIcon, size: 18, color: FreshCycleTheme.urgencyCritical),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: FreshCycleTheme.textSecondary),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 12), Text('Edit')]),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [Icon(Icons.delete_outline, size: 20, color: Colors.red), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.red))]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FreshCycleTheme.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            const Text(
              'Expired',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: FreshCycleTheme.urgencyCritical),
            ),
            if (item.cost != null)
              Text(
                '₱${item.cost!.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 11, color: FreshCycleTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(PantryItem item, int index) {
    final barColor = _progressBarColor(item);
    final progress = _progressValue(item);

    return GestureDetector(
      onLongPress: () => _showAddItemSheet(existingItem: item, index: index),
      child: Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: FreshCycleTheme.borderColor, width: 0.5),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
                  const Text(" • ", style: TextStyle(color: FreshCycleTheme.textHint)),
                  Text(
                    item.category,
                    style: const TextStyle(color: FreshCycleTheme.textSecondary, fontSize: 12),
                  ),
                  if (item.cost != null) ...[
                    const Text(" • ", style: TextStyle(color: FreshCycleTheme.textHint)),
                    Text(
                      '₱${item.cost!.toStringAsFixed(2)}',
                      style: const TextStyle(color: FreshCycleTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: FreshCycleTheme.textSecondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'edit') {
                  _showAddItemSheet(existingItem: item, index: index);
                } else if (value == 'delete') {
                  _confirmDelete(item, index);
                } else if (value == 'list') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Moving to marketplace... (Original Cost: ₱${item.cost ?? 0})'),
                      backgroundColor: FreshCycleTheme.primary,
                    ),
                  );
                }
              },
              itemBuilder: (context) {
                final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                final expiryDay = DateTime(item.computedExpiryDate.year, item.computedExpiryDate.month, item.computedExpiryDate.day);
                final isExpired = expiryDay.isBefore(today);
                return [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 12), Text('Edit')]),
                  ),
                  if (!isExpired)
                    const PopupMenuItem(
                      value: 'list',
                      child: Row(children: [Icon(Icons.storefront_outlined, size: 20), SizedBox(width: 12), Text('Make into listing')]),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [Icon(Icons.delete_outline, size: 20, color: Colors.red), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.red))]),
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
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final expired = myPantry.where((i) {
      final expiry = DateTime(i.expiryDate.year, i.expiryDate.month, i.expiryDate.day);
      return expiry.isBefore(today);
    }).toList();
    final expiring = myPantry
        .where((i) => i.urgency == UrgencyLevel.critical || i.urgency == UrgencyLevel.soon)
        .where((i) => !expired.contains(i))
        .toList();
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
                  const Icon(Icons.cancel_outlined, size: 16, color: FreshCycleTheme.urgencyCritical),
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
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear all expired?'),
                          content: const Text('This will remove all expired items from your pantry.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Clear all'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        setState(() {
                          myPantry.removeWhere((i) {
                            final expiry = DateTime(i.expiryDate.year, i.expiryDate.month, i.expiryDate.day);
                            return expiry.isBefore(today);
                          });
                          _sortPantry();
                        });
                      }
                    },
                    child: const Text(
                      'Clear all',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FreshCycleTheme.urgencyCritical),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: FreshCycleTheme.urgencyCriticalBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${expired.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: FreshCycleTheme.urgencyCritical),
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
                  const Icon(Icons.warning_amber_rounded, size: 16, color: FreshCycleTheme.urgencySoon),
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
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: FreshCycleTheme.urgencySoonBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${expiring.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: FreshCycleTheme.urgencySoon),
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
              padding: EdgeInsets.fromLTRB(16, expiring.isEmpty && expired.isEmpty ? 16 : 8, 16, 6),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? FreshCycleTheme.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? FreshCycleTheme.primary : FreshCycleTheme.borderColor,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : FreshCycleTheme.textSecondary,
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
                  (context, i) => _buildItemCard(rest[i], myPantry.indexOf(rest[i])),
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
                  style: const TextStyle(color: FreshCycleTheme.textHint, fontSize: 13),
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
      ),
      body: myPantry.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.kitchen_outlined, size: 64, color: FreshCycleTheme.textHint),
                  const SizedBox(height: 16),
                  const Text(
                    "Your pantry is empty.",
                    style: TextStyle(fontSize: 16, color: FreshCycleTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _showAddItemSheet(),
                    icon: const Icon(Icons.add, color: FreshCycleTheme.primary),
                    label: const Text("Add your first item", style: TextStyle(color: FreshCycleTheme.primary)),
                  )
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