import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../models/listing.dart';

enum FoodType { perishable, nonPerishable }

// 1. Updated Data Model
class PantryItem {
  final String id;
  String name;
  String category;
  DateTime expiryDate;
  FoodType foodType;
  double? cost;
  UrgencyLevel urgency;

  PantryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.expiryDate,
    required this.foodType,
    this.cost,
    required this.urgency,
  });

  String get daysLeft {
    final diff = expiryDate.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Expired';
    if (diff == 0) return 'Expires today';
    if (diff == 1) return 'Expires tomorrow';
    return '$diff days left';
  }
}

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  // 2. Empty initial pantry
  List<PantryItem> myPantry = [];

  // Logic to determine urgency based on date
  UrgencyLevel _calculateUrgency(DateTime expiry) {
    final diff = expiry.difference(DateTime.now()).inDays;
    if (diff <= 1) return UrgencyLevel.critical;
    if (diff <= 3) return UrgencyLevel.soon;
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
      int dateCompare = a.expiryDate.compareTo(b.expiryDate);
      if (dateCompare != 0) return dateCompare;

      // 2. Break ties with Food Type (Perishable first)
      // Since FoodType.perishable is index 0 and nonPerishable is index 1, 
      // comparing indices puts perishable first.
      int typeCompare = a.foodType.index.compareTo(b.foodType.index);
      if (typeCompare != 0) return typeCompare;

      // 3. Final tie-breaker: Alphabetical by Name
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }
  // 3. The Interactive Bottom Sheet for Adding & Editing
  void _showAddItemSheet({PantryItem? existingItem, int? index}) {
    final isEditing = existingItem != null;
    final nameController = TextEditingController(text: existingItem?.name);
    final costController = TextEditingController(text: existingItem?.cost?.toString());
    
    // Default to 7 days from now if not editing
    DateTime selectedDate = existingItem?.expiryDate ?? DateTime.now().add(const Duration(days: 7));
    FoodType selectedType = existingItem?.foodType ?? FoodType.perishable;

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
                
                // Type & Cost Row
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<FoodType>(
                        value: selectedType,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem(value: FoodType.perishable, child: Text('Perishable')),
                          DropdownMenuItem(value: FoodType.nonPerishable, child: Text('Non-perishable')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setSheetState(() => selectedType = v);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: costController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Cost',
                          prefixText: '₱ ',
                          hintText: '0.00',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Expiry Date Picker
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: FreshCycleTheme.borderColor, width: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: const Text("Expiry Date", style: TextStyle(fontSize: 14, color: FreshCycleTheme.textSecondary)),
                    subtitle: Text(
                      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: FreshCycleTheme.textPrimary),
                    ),
                    trailing: const Icon(Icons.calendar_today_rounded, color: FreshCycleTheme.primary),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

                      final newItem = PantryItem(
                        id: isEditing ? existingItem.id : DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text.trim(),
                        category: selectedType == FoodType.perishable ? "Perishable" : "Non-perishable",
                        expiryDate: selectedDate,
                        foodType: selectedType,
                        cost: double.tryParse(costController.text),
                        urgency: _calculateUrgency(selectedDate),
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myPantry.length,
              itemBuilder: (context, index) {
                final item = myPantry[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: FreshCycleTheme.borderColor, width: 0.5),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: urgencyBgColor(item.urgency),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.foodType == FoodType.perishable ? Icons.eco_outlined : Icons.inventory_2_outlined,
                        color: urgencyColor(item.urgency),
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
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
                            item.foodType == FoodType.perishable ? 'Perishable' : 'Non-perishable',
                            style: const TextStyle(color: FreshCycleTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    
                    // 4. Three-Dots Menu
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: FreshCycleTheme.textSecondary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showAddItemSheet(existingItem: item, index: index);
                        } else if (value == 'delete') {
                          setState(() {
                            myPantry.removeAt(index);
                            _sortPantry();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${item.name} deleted')),
                          );
                        } else if (value == 'list') {
                          // TODO: Implement actual navigation to listing creation
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
                              Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
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