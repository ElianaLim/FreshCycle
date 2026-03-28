import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/listing.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/listing_provider.dart';
import '../theme/app_theme.dart';
import '../data/db.dart';

class PostRequestScreen extends StatefulWidget {
  const PostRequestScreen({super.key});

  @override
  State<PostRequestScreen> createState() => _PostRequestScreenState();
}

class _PostRequestScreenState extends State<PostRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  final _budgetController = TextEditingController();

  String _selectedCategory = 'Produce';
  String _fulfillmentPreference = 'Pickup';

  List<String> get _categories =>
      FreshCycleTheme.foodCategories.where((c) => c != 'All').toList();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authUser = context.read<AuthProvider>().user;
    final budget = double.tryParse(_budgetController.text.trim());
    final sellerId = authUser?.id ?? 'demo-user';

    // Save to database
    final dbRequest = await DB.createListing(
      sellerId: sellerId,
      type: 'requesting',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      price: budget,
      urgency: 'safe',
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      tags: [_selectedCategory.toLowerCase(), 'request'],
    );

    // Also add to local provider for immediate display
    final newRequest = Listing(
      id: dbRequest?['id'] ?? 'r_${DateTime.now().millisecondsSinceEpoch}',
      sellerId: sellerId,
      type: ListingType.requesting,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      price: budget,
      postedAt: DateTime.now(),
      urgency: UrgencyLevel.safe,
      offerCount: 0,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      dealLocation: _fulfillmentPreference,
      seller: (authUser ?? User.sampleUser).toSellerProfile(),
      tags: [_selectedCategory.toLowerCase(), 'request'],
      allowDelivery:
          _fulfillmentPreference == 'Delivery' ||
          _fulfillmentPreference == 'Either',
    );

    if (mounted) {
      context.read<ListingProvider>().addRequest(newRequest);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FreshCycleTheme.surfaceGray,
      appBar: AppBar(
        title: const Text('Make Request'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text(
              'Post',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Request title*',
                  hintText: 'Example: Looking for ripe bananas',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please add a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category*'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedCategory = v);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budgetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Budget (PHP)*',
                  hintText: 'Example: 120',
                  prefixText: 'P ',
                ),
                validator: (v) {
                  final parsed = double.tryParse((v ?? '').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid budget amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description*',
                  hintText: 'What item do you need and how much?',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please add a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Any context or urgency you want sellers to know',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _fulfillmentPreference,
                decoration: const InputDecoration(
                  labelText: 'Preferred way to get item*',
                ),
                items: const [
                  DropdownMenuItem(value: 'Pickup', child: Text('Pickup')),
                  DropdownMenuItem(value: 'Delivery', child: Text('Delivery')),
                  DropdownMenuItem(value: 'Either', child: Text('Either')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _fulfillmentPreference = v);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
