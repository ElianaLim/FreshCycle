import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/listing.dart';
import '../providers/auth_provider.dart';
import '../providers/listing_provider.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class RequestCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;
  final VoidCallback? onOffer;

  const RequestCard({
    super.key,
    required this.listing,
    this.onTap,
    this.onOffer,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final isOwnRequest =
        currentUserId != null && listing.seller.id == currentUserId;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FreshCycleTheme.borderColor, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: FreshCycleTheme.requestBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCategoryIcon(
                                _categoryIcon(listing.category),
                                size: 12,
                                color: FreshCycleTheme.requestColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                listing.category,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: FreshCycleTheme.requestColor,
                                ),
                              ),
                            ],
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
                        ),
                        const SizedBox(height: 3),
                        Text(
                          listing.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: FreshCycleTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (listing.price != null)
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
                                  'Budget: P${listing.price!.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: FreshCycleTheme.primaryDark,
                                  ),
                                ),
                              ),
                            if (listing.dealLocation != null &&
                                listing.dealLocation!.isNotEmpty)
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
                                  'Receive: ${listing.dealLocation!}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: FreshCycleTheme.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      OfferCountBadge(count: listing.offerCount ?? 0),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          context.read<ListingProvider>().toggleSave(
                            listing.id,
                          );
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
                            listing.isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 16,
                            color: listing.isSaved
                                ? FreshCycleTheme.primary
                                : FreshCycleTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Personal note
              if (listing.note != null && listing.note!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FreshCycleTheme.surfaceGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '"',
                        style: TextStyle(
                          fontSize: 20,
                          color: FreshCycleTheme.primary,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.note!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: FreshCycleTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1, color: FreshCycleTheme.borderColor),
              const SizedBox(height: 12),

              // Footer row
              Row(
                children: [
                  SellerAvatar(seller: listing.seller, size: 30),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.seller.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: FreshCycleTheme.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            DistanceChip(distanceKm: listing.distanceKm),
                            const SizedBox(width: 8),
                            Text(
                              listing.timeAgo,
                              style: const TextStyle(
                                fontSize: 11,
                                color: FreshCycleTheme.textHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isOwnRequest)
                    FilledButton(
                      onPressed: onOffer,
                      style: FilledButton.styleFrom(
                        backgroundColor: FreshCycleTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Offer'),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: FreshCycleTheme.surfaceGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Your request',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: FreshCycleTheme.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(
    dynamic icon, {
    required double size,
    required Color color,
  }) {
    if (icon is IconData) {
      return Icon(icon, size: size, color: color);
    }
    if (icon is List<List<dynamic>>) {
      return HugeIcon(icon: icon, size: size, color: color);
    }
    return Icon(Icons.category_outlined, size: size, color: color);
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
      default:
        return Icons.shopping_bag_outlined;
    }
  }
}
