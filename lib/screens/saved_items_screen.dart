import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/listing_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/selling_card.dart';

class SavedItemsScreen extends StatelessWidget {
  const SavedItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Filter listings to only show saved ones
    final savedListings = context
        .watch<ListingProvider>()
        .listings
        .where((l) => l.isSaved)
        .toList();

    return Scaffold(
      backgroundColor: FreshCycleTheme.surfaceGray,
      appBar: AppBar(title: const Text('Saved Items')),
      body: savedListings.isEmpty
          ? const Center(
              child: Text(
                'No saved items yet.',
                style: TextStyle(color: FreshCycleTheme.textSecondary),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 380,
              ),
              itemCount: savedListings.length,
              itemBuilder: (context, index) {
                return SellingCard(
                  listing: savedListings[index],
                  onTap: () {},
                  onMessage: () {}, // Optional: Add message logic here
                );
              },
            ),
    );
  }
}
