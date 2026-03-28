import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';
import 'package:provider/provider.dart';
import '../providers/listing_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/post_listing_screen.dart';

class SellingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;
  final VoidCallback? onBuy;
  final VoidCallback? onMessage;

  const SellingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.onBuy,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final isOwnListing =
        currentUserId != null && listing.seller.id == currentUserId;
    final discountPct = listing.discountPercent.round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FreshCycleTheme.borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with urgency overlay
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: Stack(
                children: [
                  // Show actual image if available, else show category icon
                  if (listing.images != null && listing.images!.isNotEmpty)
                    Image.network(
                      listing.images!.first,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => _buildPlaceholder(),
                    )
                  else
                    _buildPlaceholder(),

                  // Urgency badge top-left
                  Positioned(
                    top: 10,
                    left: 10,
                    child: UrgencyBadge(
                      urgency: listing.urgency,
                      label: listing.urgencyLabel,
                    ),
                  ),
                  // Discount badge top-right
                  if (discountPct > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: FreshCycleTheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-$discountPct%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // Action button (Edit if it's yours, Save if it's not)
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        // Check if the current user is the seller
                        if (isOwnListing) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PostListingScreen(existingListing: listing),
                            ),
                          );
                        } else {
                          context.read<ListingProvider>().toggleSave(
                            listing.id,
                          );
                        }
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: FreshCycleTheme.borderColor,
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          isOwnListing
                              ? Icons
                                    .edit_rounded // Show edit if it's yours
                              : (listing.isSaved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded),
                          size: 16,
                          color: (listing.isSaved && !isOwnListing)
                              ? FreshCycleTheme.primary
                              : FreshCycleTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Urgency progress bar
            UrgencyBar(urgency: listing.urgency),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: FreshCycleTheme.surfaceGray,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        listing.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: FreshCycleTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FreshCycleTheme.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Removed the buggy 'Expanded' from here
                    Text(
                      listing.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: FreshCycleTheme.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      color: FreshCycleTheme.surfaceGray,
      child: Center(
        child: Icon(
          _categoryIcon(listing.category),
          size: 48,
          color: FreshCycleTheme.borderColor,
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'produce':
        return Icons.eco_outlined;
      case 'dairy':
        return Icons.egg_outlined;
      case 'bakery':
        return Icons.bakery_dining_outlined;
      case 'meat & fish':
        return Icons.set_meal_outlined;
      case 'meals & leftovers':
        return Icons.restaurant_menu_outlined;
      case 'snacks':
        return Icons.fastfood_outlined;
      case 'beverages':
        return Icons.local_cafe_outlined;
      case 'other':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.shopping_bag_outlined;
    }
  }
}
