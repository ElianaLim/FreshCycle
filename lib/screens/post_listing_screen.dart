import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../providers/listing_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../models/listing.dart';
import '../data/db.dart';
import 'profile_screen.dart';

class PostListingScreen extends StatefulWidget {
  final Listing? existingListing;

  const PostListingScreen({super.key, this.existingListing});

  @override
  State<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends State<PostListingScreen> {
  final List<File> _images = [];
  bool _isFree = false;
  bool _allowDelivery = false;
  DateTime? _expiryDate;
  String? _selectedCategory;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _ogPriceController = TextEditingController();
  final _locationController = TextEditingController();

  List<String> get _categories =>
      FreshCycleTheme.foodCategories.where((c) => c != 'All').toList();

  @override
  void initState() {
    super.initState();
    if (widget.existingListing != null) {
      final l = widget.existingListing!;
      _titleController.text = l.title;
      _descController.text = l.description;
      _priceController.text = l.price?.toStringAsFixed(0) ?? '';
      _ogPriceController.text = l.originalPrice?.toStringAsFixed(0) ?? '';
      _locationController.text = l.dealLocation ?? '';
      _selectedCategory = l.category;
      _expiryDate = l.expiryDate;
      _isFree = l.isFree;
      _allowDelivery = l.allowDelivery;

      if (l.images != null) {
        _images.addAll(l.images!.map((path) => File(path)));
      }
    } else {
      _selectedCategory = _categories.first;
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) setState(() => _images.add(File(image.path)));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingListing != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Listing' : 'New Listing'),
        actions: [
          TextButton(
            onPressed: () async {
              final authUser = context.read<AuthProvider>().user;

              String sellerId;
              if (isEditing &&
                  widget.existingListing!.sellerId != null &&
                  widget.existingListing!.sellerId!.isNotEmpty) {
                sellerId = widget.existingListing!.sellerId!;
              } else if (isEditing &&
                  widget.existingListing!.seller.id.isNotEmpty) {
                sellerId = widget.existingListing!.seller.id;
              } else {
                sellerId = authUser?.id ?? '';
              }

              final uuidRegex = RegExp(
                r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
                caseSensitive: false,
              );
              if (sellerId.isEmpty || !uuidRegex.hasMatch(sellerId)) {
                // Redirect to profile screen for login
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                return;
              }

              // Save to database
              final dbListing = await DB.createListing(
                sellerId: sellerId,
                type: 'selling',
                title: _titleController.text,
                description: _descController.text.isNotEmpty
                    ? _descController.text
                    : null,
                category: _selectedCategory ?? 'Other',
                price: _isFree ? 0 : double.tryParse(_priceController.text),
                originalPrice: double.tryParse(_ogPriceController.text),
                expiryDate: _expiryDate,
                urgency: 'safe',
                note: _locationController.text.isNotEmpty
                    ? _locationController.text
                    : null,
                tags: [],
              );

              // Also add to local provider for immediate display
              final newListing = Listing(
                id: dbListing?['id'] ?? DateTime.now().toString(),
                sellerId: sellerId,
                type: ListingType.selling,
                title: _titleController.text,
                description: _descController.text,
                category: _selectedCategory ?? 'Other',
                price: _isFree ? 0 : double.tryParse(_priceController.text),
                originalPrice: double.tryParse(_ogPriceController.text),
                expiryDate: _expiryDate,
                postedAt: DateTime.now(),
                urgency: UrgencyLevel.safe,
                images: _images.map((f) => f.path).toList(),
                isFree: _isFree,
                allowDelivery: _allowDelivery,
                dealLocation: _locationController.text,
                seller: isEditing
                    ? widget.existingListing!.seller
                    : (authUser ?? User.sampleUser).toSellerProfile(),
                tags: [],
                isSaved: false,
              );

              if (isEditing) {
                context.read<ListingProvider>().updateListing(newListing);
              } else {
                context.read<ListingProvider>().addListing(newListing);
              }
              if (mounted) Navigator.pop(context);
            },
            child: Text(
              isEditing ? 'Save' : 'Post',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image Carousel (Carousell-inspired)
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      width: 90,
                      decoration: BoxDecoration(
                        border: Border.all(color: FreshCycleTheme.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            color: FreshCycleTheme.primary,
                          ),
                          Text('Take Photo', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  ..._images.map(
                    (file) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          file,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 6, color: FreshCycleTheme.surfaceGray),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Listing Title*',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category*'),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Expiry Date*"),
                    subtitle: Text(
                      _expiryDate == null
                          ? "Select date"
                          : "${_expiryDate!.toLocal()}".split(' ')[0],
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 1),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _expiryDate = date);
                    },
                  ),
                  TextField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 6, color: FreshCycleTheme.surfaceGray),
            // Price Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('List for FREE?'),
                      Switch(
                        value: _isFree,
                        onChanged: (v) => setState(() => _isFree = v),
                      ),
                    ],
                  ),
                  if (!_isFree) ...[
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: '₱',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ogPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Original Price (Optional)',
                        prefixText: '₱',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(thickness: 6, color: FreshCycleTheme.surfaceGray),
            // Deal Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Meetup Location',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Offer Delivery?'),
                    contentPadding: EdgeInsets.zero,
                    value: _allowDelivery,
                    onChanged: (v) => setState(() => _allowDelivery = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
