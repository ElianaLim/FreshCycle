import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'dart:io';
import '../models/listing.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../providers/listing_provider.dart';
import '../providers/auth_provider.dart';
import 'post_listing_screen.dart';

class ListingDetailScreen extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onBuy;
  final VoidCallback? onMessage;

  const ListingDetailScreen({
    super.key,
    required this.listing,
    this.onBuy,
    this.onMessage,
  });

  Future<void> _confirmDeleteListing(
    BuildContext context,
    Listing currentListing,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete listing?'),
          content: Text(
            'This will permanently remove "${currentListing.title}" from your listings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      context.read<ListingProvider>().removeListing(currentListing.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingProvider = context.watch<ListingProvider>();
    final currentListing = listingProvider.findById(listing.id) ?? listing;
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final isOwnListing =
        currentUserId != null && currentListing.seller.id == currentUserId;
    final isRequest = currentListing.type == ListingType.requesting;

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
                      isOwnListing
                          ? Icons.edit_rounded
                          : currentListing.isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 20,
                    ),
                    color: isOwnListing
                        ? FreshCycleTheme.primary
                        : currentListing.isSaved
                        ? FreshCycleTheme.primary
                        : FreshCycleTheme.textPrimary,
                    onPressed: () {
                      if (isOwnListing) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PostListingScreen(existingListing: listing),
                          ),
                        );
                      } else {
                        context.read<ListingProvider>().toggleSave(listing.id);
                      }
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
                  if (isRequest) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Request Note',
                      style: TextStyle(
                        fontSize: 16,
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
                        (currentListing.note != null &&
                                currentListing.note!.trim().isNotEmpty)
                            ? currentListing.note!
                            : 'No note provided.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: FreshCycleTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Preferred Receiving Method',
                      style: TextStyle(
                        fontSize: 16,
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
                        currentListing.dealLocation?.isNotEmpty == true
                            ? currentListing.dealLocation!
                            : 'Not specified',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: FreshCycleTheme.primaryDark,
                        ),
                      ),
                    ),
                  ],                  

                  if (!isRequest) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Listing Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: FreshCycleTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: FreshCycleTheme.surfaceGray,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            currentListing.allowDelivery
                                ? 'Delivery available'
                                : 'Pickup only',
                            style: const TextStyle(
                              fontSize: 13,
                              color: FreshCycleTheme.textSecondary,
                            ),
                          ),
                        ),
                        if (currentListing.dealLocation != null &&
                            currentListing.dealLocation!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: FreshCycleTheme.surfaceGray,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Meetup: ${currentListing.dealLocation!}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: FreshCycleTheme.textSecondary,
                              ),
                            ),
                          ),
                        if (currentListing.expiryDate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: FreshCycleTheme.surfaceGray,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Expiry: ${currentListing.expiryDate!.toLocal().toString().split(' ').first}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: FreshCycleTheme.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  // User section below description
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

                  if (isOwnListing && !isRequest) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFD5D5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Delete Listing',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Remove this listing permanently from the marketplace.',
                            style: TextStyle(
                              fontSize: 13,
                              color: FreshCycleTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _confirmDeleteListing(context, currentListing),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Delete listing'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Bottom spacing so content doesn't get hidden behind the floating bottom bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Sticky Bottom Bar for actions
      bottomNavigationBar: !isOwnListing
          ? Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
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
                    child: FilledButton.icon(
                      onPressed: onBuy,
                      icon: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        isRequest ? 'Offer' : 'Buy',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onMessage,
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                      ),
                      label: Text(
                        isRequest ? 'Message requester' : 'Message',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FreshCycleTheme.primary,
                        side: const BorderSide(
                          color: FreshCycleTheme.primary,
                          width: 0.8,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildImage(Listing listing) {
    if (listing.images != null && listing.images!.isNotEmpty) {
      final imagePath = listing.images!.first;
      if (_isLocalImagePath(imagePath)) {
        return Image.file(
          File(imagePath),
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) =>
              _buildPlaceholder(listing.category),
        );
      }
      return Image.network(
        imagePath,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildPlaceholder(listing.category),
      );
    }
    return _buildPlaceholder(listing.category);
  }

  bool _isLocalImagePath(String path) {
    return path.startsWith('/') || path.startsWith('file://');
  }

  Widget _buildPlaceholder(String category) {
    dynamic icon;
    switch (category.toLowerCase()) {
      case 'produce':
        icon = Icons.eco_outlined;
        break;
      case 'dairy':
        icon = HugeIcons.strokeRoundedMilkBottle;
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
      child: Center(child: _buildCategoryIconWidget(icon)),
    );
  }

  Widget _buildCategoryIconWidget(dynamic icon) {
    if (icon is IconData) {
      return Icon(icon, size: 80, color: FreshCycleTheme.borderColor);
    }
    if (icon is List<List<dynamic>>) {
      return HugeIcon(icon: icon, size: 80, color: FreshCycleTheme.borderColor);
    }
    return const Icon(
      Icons.shopping_bag_outlined,
      size: 80,
      color: FreshCycleTheme.borderColor,
    );
  }
}
