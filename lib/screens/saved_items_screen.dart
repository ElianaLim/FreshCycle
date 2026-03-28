import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/listing_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/selling_card.dart';
import '../widgets/request_card.dart';
import 'listing_detail_screen.dart';
import 'request_detail_screen.dart';

class SavedItemsScreen extends StatelessWidget {
  const SavedItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListingProvider>();
    final savedListings = provider.savedListings;
    final savedRequests = provider.savedRequests;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: FreshCycleTheme.surfaceGray,
        appBar: AppBar(
          title: const Text('Saved Items'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Listings'),
              Tab(text: 'Requests'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            savedListings.isEmpty
                ? const Center(
                    child: Text(
                      'No saved listings yet.',
                      style: TextStyle(color: FreshCycleTheme.textSecondary),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 260,
                        ),
                    itemCount: savedListings.length,
                    itemBuilder: (context, index) {
                      return SellingCard(
                        listing: savedListings[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ListingDetailScreen(
                                listing: savedListings[index],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
            savedRequests.isEmpty
                ? const Center(
                    child: Text(
                      'No saved requests yet.',
                      style: TextStyle(color: FreshCycleTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: savedRequests.length,
                    itemBuilder: (context, index) {
                      final request = savedRequests[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: RequestCard(
                          listing: request,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RequestDetailScreen(request: request),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
