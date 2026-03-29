import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'dart:io';
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: Stack(
                children: [
                  if (listing.images != null && listing.images!.isNotEmpty)
                    _buildCardImage(listing.images!.first)
                  else
                    _buildPlaceholder(),

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

                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Check if the current user is the seller
                            if (isOwnListing) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PostListingScreen(
                                    existingListing: listing,
                                  ),
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
                                        .edit_rounded // Show edit if owned
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
                      ],
                    ),
                  ),
                ],
              ),
            ),

            UrgencyBar(urgency: listing.urgency),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: FreshCycleTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: FreshCycleTheme.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            listing.isFree
                                ? 'FREE'
                                : '₱${(listing.price ?? 0).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: FreshCycleTheme.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),

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

                    Text(
                      listing.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: FreshCycleTheme.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: FreshCycleTheme.borderColor,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 13,
                                color: FreshCycleTheme.textSecondary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${listing.distanceKm.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: FreshCycleTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: FreshCycleTheme.surfaceGray,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person_pin_circle_rounded,
                                size: 13,
                                color: FreshCycleTheme.textSecondary,
                              ),
                              if (listing.allowDelivery) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.delivery_dining_rounded,
                                  size: 13,
                                  color: FreshCycleTheme.textSecondary,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildCardImage(String path) {
    if (_isLocalImagePath(path)) {
      return Image.file(
        File(path),
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildPlaceholder(),
      );
    }
    return Image.network(
      path,
      height: 120,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, stack) => _buildPlaceholder(),
    );
  }

  bool _isLocalImagePath(String path) {
    return path.startsWith('/') || path.startsWith('file://');
  }

  Widget _buildPlaceholder() {
    final categoryIcon = _categoryIcon(listing.category);
    return Container(
      height: 120,
      width: double.infinity,
      color: FreshCycleTheme.surfaceGray,
      child: Center(child: _buildCategoryIconWidget(categoryIcon)),
    );
  }

  Widget _buildCategoryIconWidget(dynamic icon) {
    if (icon is IconData) {
      return Icon(icon, size: 48, color: FreshCycleTheme.borderColor);
    }
    if (icon is List<List<dynamic>>) {
      return HugeIcon(icon: icon, size: 48, color: FreshCycleTheme.borderColor);
    }
    return const Icon(
      Icons.shopping_bag_outlined,
      size: 48,
      color: FreshCycleTheme.borderColor,
    );
  }

  dynamic _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'produce':
        return Icons.eco_outlined;
      case 'dairy':
        return HugeIcons.strokeRoundedMilkBottle;
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
