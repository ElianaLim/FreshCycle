import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../theme/app_theme.dart';

class SellerAvatar extends StatelessWidget {
  final SellerProfile seller;
  final double size;

  const SellerAvatar({super.key, required this.seller, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final idx = seller.id.hashCode.abs() % FreshCycleTheme.avatarBgs.length;
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: FreshCycleTheme.avatarBgs[idx],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              seller.initials,
              style: TextStyle(
                fontSize: size * 0.33,
                fontWeight: FontWeight.w600,
                color: FreshCycleTheme.avatarFgs[idx],
              ),
            ),
          ),
        ),
        if (seller.isVerified)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.36,
              height: size * 0.36,
              decoration: const BoxDecoration(
                color: FreshCycleTheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: size * 0.22,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

class StarRating extends StatelessWidget {
  final double rating;
  final int reviews;
  final double size;

  const StarRating({
    super.key,
    required this.rating,
    required this.reviews,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.star_rounded, size: size + 2, color: const Color(0xFFBA7517)),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w600,
            color: FreshCycleTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '($reviews)',
          style: TextStyle(
            fontSize: size,
            color: FreshCycleTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class UrgencyBadge extends StatelessWidget {
  final UrgencyLevel urgency;
  final String label;

  const UrgencyBadge({super.key, required this.urgency, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: urgencyBgColor(urgency),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: urgencyColor(urgency),
        ),
      ),
    );
  }
}

class UrgencyBar extends StatelessWidget {
  final UrgencyLevel urgency;

  const UrgencyBar({super.key, required this.urgency});

  double get _fillFraction {
    switch (urgency) {
      case UrgencyLevel.critical:
        return 0.9;
      case UrgencyLevel.soon:
        return 0.6;
      case UrgencyLevel.safe:
        return 0.35;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        height: 3,
        width: double.infinity,
        decoration: BoxDecoration(
          color: urgencyBgColor(urgency),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            height: 3,
            width: constraints.maxWidth * _fillFraction,
            decoration: BoxDecoration(
              color: urgencyColor(urgency),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class OfferCountBadge extends StatelessWidget {
  final int count;

  const OfferCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1EFE8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'No offers yet',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5F5E5A),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: FreshCycleTheme.requestBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count ${count == 1 ? 'offer' : 'offers'}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: FreshCycleTheme.requestColor,
        ),
      ),
    );
  }
}

class DistanceChip extends StatelessWidget {
  final double distanceKm;

  const DistanceChip({super.key, required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 12,
          color: FreshCycleTheme.textSecondary,
        ),
        const SizedBox(width: 2),
        Text(
          '${distanceKm.toStringAsFixed(1)} km',
          style: const TextStyle(
            fontSize: 12,
            color: FreshCycleTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
