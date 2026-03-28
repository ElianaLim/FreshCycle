import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; 
import 'dart:io';
import '../theme/app_theme.dart';
import '../providers/listing_provider.dart'; 
import '../models/user.dart';
import '../models/listing.dart';


class PostListingScreen extends StatefulWidget {
  const PostListingScreen({super.key});

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

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    // Use ImageSource.camera specifically to fulfill the "take pic from app" requirement
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) setState(() => _images.add(File(image.path)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('New Listing'),
        actions: [
          TextButton(
            onPressed: () {
              final newListing = Listing(
                id: DateTime.now().toString(),
                type: ListingType.selling,
                title: _titleController.text,
                description: _descController.text,
                category: _selectedCategory ?? 'General',
                price: _isFree ? 0 : double.tryParse(_priceController.text),
                originalPrice: double.tryParse(_ogPriceController.text),
                expiryDate: _expiryDate,
                postedAt: DateTime.now(),
                distanceKm: 0.1, // Demo default
                urgency: UrgencyLevel.safe, // Logic based on expiryDate
                images: _images
                    .map((f) => f.path)
                    .toList(), // local paths for demo
                isFree: _isFree,
                seller: User.sampleUser
                    .toSellerProfile(), // Helper to convert User to Seller
                tags: [],
              );

              context.read<ListingProvider>().addListing(newListing);
              Navigator.pop(context); // Go back to marketplace
            },
            child: const Text('Post'),
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
                    items: ['Produce', 'Dairy', 'Bakery', 'Meat & fish', 'Meals & leftovers', 'Snacks', 'Beverages', 'Other']
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
