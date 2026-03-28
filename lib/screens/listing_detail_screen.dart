import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/listing.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../providers/listing_provider.dart';

class ListingDetailScreen extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onMessage;

  const ListingDetailScreen({super.key, required this.listing, this.onMessage});

  @override
  Widget build(BuildContext context) {
    // Watch the provider to keep the saved icon updated
    final currentListing = context.watch<ListingProvider>().listings.firstWhere(
      (l) => l.id == listing.id,
      orElse: () => listing,
    );

    final discountPct = currentListing.discountPercent.round();

    return Scaffold(
      backgroundColor: FreshCycleTheme.surfaceGray,
      body: CustomScrollView(
        slivers: [
          // Collapsible Image Header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: FreshCycleTheme.textPrimary,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      currentListing.isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 20,
                    ),
                    color: currentListing.isSaved
                        ? FreshCycleTheme.primary
                        : FreshCycleTheme.textPrimary,
                    onPressed: () {
                      context.read<ListingProvider>().toggleSave(
                        currentListing.id,
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImage(currentListing),
            ),
          ),

          // Scrollable Content
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: FreshCycleTheme.surfaceGray,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          currentListing.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: FreshCycleTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      UrgencyBadge(
                        urgency: currentListing.urgency,
                        label: currentListing.urgencyLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title & Price
                  Text(
                    currentListing.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: FreshCycleTheme.textPrimary,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₱${currentListing.price?.toStringAsFixed(0) ?? 0}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: FreshCycleTheme.primary,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (currentListing.originalPrice != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '₱${currentListing.originalPrice!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: FreshCycleTheme.textHint,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      if (discountPct > 0) ...[
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: FreshCycleTheme.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '-$discountPct% OFF',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: FreshCycleTheme.primaryDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: FreshCycleTheme.borderColor),
                  const SizedBox(height: 24),

                  // Seller Info Profile Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: FreshCycleTheme.surfaceGray,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: FreshCycleTheme.borderColor,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        SellerAvatar(seller: currentListing.seller, size: 48),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentListing.seller.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: FreshCycleTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              StarRating(
                                rating: currentListing.seller.rating,
                                reviews: currentListing.seller.totalReviews,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            DistanceChip(distanceKm: currentListing.distanceKm),
                            const SizedBox(height: 4),
                            Text(
                              currentListing.timeAgo,
                              style: const TextStyle(
                                fontSize: 12,
                                color: FreshCycleTheme.textHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description Section
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: FreshCycleTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentListing.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: FreshCycleTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),

                  // Bottom spacing so content doesn't get hidden behind the floating bottom bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Sticky Bottom Bar for messaging
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: FreshCycleTheme.borderColor, width: 0.5),
          ),
        ),
        child: FilledButton.icon(
          onPressed: () {
            if (onMessage != null) {
              Navigator.pop(context); // Close details
              onMessage!(); // Open bottom sheet
            }
          },
          icon: const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 20,
            color: Colors.white,
          ),
          label: const Text(
            'Message Seller',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: FreshCycleTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Listing listing) {
    if (listing.images != null && listing.images!.isNotEmpty) {
      return Image.network(
        listing.images!.first,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildPlaceholder(listing.category),
      );
    }
    return _buildPlaceholder(listing.category);
  }

  Widget _buildPlaceholder(String category) {
    IconData icon;
    switch (category.toLowerCase()) {
      case 'produce':
        icon = Icons.eco_outlined;
        break;
      case 'dairy':
        icon = Icons.egg_outlined;
        break;
      case 'bakery':
        icon = Icons.bakery_dining_outlined;
        break;
      case 'meat & fish':
        icon = Icons.set_meal_outlined;
        break;
      default:
        icon = Icons.shopping_bag_outlined;
    }

    return Container(
      width: double.infinity,
      color: FreshCycleTheme.surfaceGray,
      child: Center(
        child: Icon(icon, size: 80, color: FreshCycleTheme.borderColor),
      ),
    );
  }
}
