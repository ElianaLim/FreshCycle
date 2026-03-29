import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final points = context.watch<AuthProvider>().rewardPoints;

    return Scaffold(
      backgroundColor: FreshCycleTheme.surfaceGray,
      appBar: AppBar(
        backgroundColor: FreshCycleTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Your Sprouts',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showRewardsInfoDialog(context),
            tooltip: 'How to earn and use sprouts',
          ),
        ],
      ),
      body: Column(
        children: [
          // Points Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        FreshCycleTheme.primary,
                        FreshCycleTheme.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedPlant01,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Available Sprouts',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$points',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Transaction History Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: const Row(
              children: [
                Icon(
                  Icons.history,
                  size: 20,
                  color: FreshCycleTheme.textSecondary,
                ),
                SizedBox(width: 8),
                Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: FreshCycleTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Transaction List
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  _TransactionItem(
                    title: 'Listed Item Sold',
                    description: '5 kg of fresh vegetables',
                    points: 20,
                    date: 'Mar 28, 2026',
                    isPositive: true,
                  ),
                  _TransactionItem(
                    title: 'Posted Listing',
                    description: 'Creating a new listing',
                    points: 5,
                    date: 'Mar 25, 2026',
                    isPositive: true,
                  ),
                  _TransactionItem(
                    title: 'Completed Pickup',
                    description: 'Food saved from waste',
                    points: 10,
                    date: 'Mar 22, 2026',
                    isPositive: true,
                  ),
                  _TransactionItem(
                    title: 'First Listing Reward',
                    description: 'Welcome bonus',
                    points: 10,
                    date: 'Mar 20, 2026',
                    isPositive: true,
                  ),
                  _TransactionItem(
                    title: 'Sprouts Redeemed',
                    description: 'Discount on next purchase',
                    points: -15,
                    date: 'Mar 15, 2026',
                    isPositive: false,
                  ),
                  _TransactionItem(
                    title: 'Posted Listing',
                    description: 'Creating a new listing',
                    points: 5,
                    date: 'Mar 10, 2026',
                    isPositive: true,
                  ),
                  _TransactionItem(
                    title: 'Listing Bonus',
                    description: 'Listed 3 items this week',
                    points: 8,
                    date: 'Mar 5, 2026',
                    isPositive: true,
                  ),
                  _TransactionItem(
                    title: 'Verified Account',
                    description: 'Account verification bonus',
                    points: 20,
                    date: 'Feb 28, 2026',
                    isPositive: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRewardsInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedPlant01,
              color: FreshCycleTheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'How to Earn & Use Sprouts',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎁 How to Earn Sprouts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: FreshCycleTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _InfoItem(
                icon: Icons.percent,
                text: 'Earn 1.5% sprouts per transaction',
              ),
              const SizedBox(height: 20),
              const Text(
                '🏆 How to Use Sprouts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: FreshCycleTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _InfoItem(
                icon: Icons.discount_outlined,
                text: 'Get discounts on items',
              ),
              _InfoItem(
                icon: Icons.star_outline,
                text: 'Unlock premium features',
              ),
              _InfoItem(
                icon: Icons.local_shipping_outlined,
                text: 'Free delivery on purchases',
              ),
              _InfoItem(
                icon: Icons.card_giftcard_outlined,
                text: 'Redeem for exclusive items',
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FreshCycleTheme.primaryLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: FreshCycleTheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The more you contribute to reducing food waste, the more sprouts you earn!',
                        style: TextStyle(
                          fontSize: 13,
                          color: FreshCycleTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: FreshCycleTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: FreshCycleTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String title;
  final String description;
  final int points;
  final String date;
  final bool isPositive;

  const _TransactionItem({
    required this.title,
    required this.description,
    required this.points,
    required this.date,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: FreshCycleTheme.surfaceGray, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPositive
                  ? FreshCycleTheme.primaryLight.withValues(alpha: 0.3)
                  : FreshCycleTheme.urgencyCritical.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPositive ? Icons.add_circle : Icons.remove_circle,
              color: isPositive
                  ? FreshCycleTheme.primary
                  : FreshCycleTheme.urgencyCritical,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FreshCycleTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: FreshCycleTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: FreshCycleTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}$points sprouts',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isPositive
                  ? FreshCycleTheme.primary
                  : FreshCycleTheme.urgencyCritical,
            ),
          ),
        ],
      ),
    );
  }
}
