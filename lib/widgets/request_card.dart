import 'package:flutter/material.dart';
import '../models/listing.dart';
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: FreshCycleTheme.borderColor,
            width: 0.5,
          ),
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
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: FreshCycleTheme.requestBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'REQUEST · ${listing.category.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: FreshCycleTheme.requestColor,
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
                        ),
                        const SizedBox(height: 3),
                        Text(
                          listing.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: FreshCycleTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  OfferCountBadge(count: listing.offerCount ?? 0),
                ],
              ),

              // Personal note
              if (listing.note != null) ...[
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
                  // Offer button
                  FilledButton(
                    onPressed: onOffer,
                    style: FilledButton.styleFrom(
                      backgroundColor: FreshCycleTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Offer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
