import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/listing.dart';
import '../providers/auth_provider.dart';
import '../providers/listing_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class RequestDetailScreen extends StatelessWidget {
  final Listing request;
  final VoidCallback? onOffer;
  final VoidCallback? onMessage;

  const RequestDetailScreen({
    super.key,
    required this.request,
    this.onOffer,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListingProvider>();
    final currentRequest = provider.findById(request.id) ?? request;
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final isOwnRequest =
        currentUserId != null && currentRequest.seller.id == currentUserId;

    return Scaffold(
      backgroundColor: FreshCycleTheme.surfaceGray,
      appBar: AppBar(
        title: const Text('Request Details'),
        actions: [
          if (!isOwnRequest)
            IconButton(
              onPressed: () {
                context.read<ListingProvider>().toggleSave(currentRequest.id);
              },
              icon: Icon(
                currentRequest.isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: currentRequest.isSaved
                    ? FreshCycleTheme.primary
                    : FreshCycleTheme.textPrimary,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FreshCycleTheme.borderColor, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: FreshCycleTheme.requestBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      currentRequest.category,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: FreshCycleTheme.requestColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  OfferCountBadge(count: currentRequest.offerCount ?? 0),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                currentRequest.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: FreshCycleTheme.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              if (currentRequest.price != null)
                Text(
                  'Budget: P${currentRequest.price!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: FreshCycleTheme.primary,
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: FreshCycleTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currentRequest.description,
                style: const TextStyle(
                  fontSize: 15,
                  color: FreshCycleTheme.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Note',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: FreshCycleTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FreshCycleTheme.surfaceGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  (currentRequest.note != null &&
                          currentRequest.note!.trim().isNotEmpty)
                      ? currentRequest.note!
                      : 'No note provided.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: FreshCycleTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Preferred Method of Receiving',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: FreshCycleTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: FreshCycleTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentRequest.dealLocation?.isNotEmpty == true
                      ? currentRequest.dealLocation!
                      : 'Not specified',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: FreshCycleTheme.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FreshCycleTheme.surfaceGray,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: FreshCycleTheme.borderColor,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    SellerAvatar(seller: currentRequest.seller, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentRequest.seller.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: FreshCycleTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          StarRating(
                            rating: currentRequest.seller.rating,
                            reviews: currentRequest.seller.totalReviews,
                            size: 13,
                          ),
                        ],
                      ),
                    ),
                    DistanceChip(distanceKm: currentRequest.distanceKm),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: !isOwnRequest
          ? Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: FreshCycleTheme.borderColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onOffer,
                      child: const Text('Offer'),
                      style: FilledButton.styleFrom(
                        backgroundColor: FreshCycleTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onMessage,
                      child: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FreshCycleTheme.primary,
                        side: const BorderSide(
                          color: FreshCycleTheme.primary,
                          width: 0.8,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
