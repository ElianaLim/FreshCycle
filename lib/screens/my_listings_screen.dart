import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/listing.dart';
import '../providers/auth_provider.dart';
import '../providers/listing_provider.dart';
import '../theme/app_theme.dart';
import 'post_listing_screen.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FreshCycleTheme.surfaceGray,
      appBar: AppBar(title: const Text('My Listings')),
      body: Consumer2<AuthProvider, ListingProvider>(
        builder: (context, auth, listingsProvider, _) {
          final user = auth.user;

          if (user == null) {
            return const _EmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in required',
              subtitle: 'Please sign in to view your listings.',
              showAction: false,
            );
          }

          final myListings =
              listingsProvider.listings
                  .where(
                    (listing) =>
                        listing.type == ListingType.selling &&
                        listing.seller.id == user.id,
                  )
                  .toList()
                ..sort((a, b) => b.postedAt.compareTo(a.postedAt));

          if (myListings.isEmpty) {
            return _EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No listings yet',
              subtitle: 'Items you post in Marketplace will show up here.',
              onAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PostListingScreen()),
                );
              },
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: myListings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final listing = myListings[index];
              return _MyListingCard(listing: listing);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostListingScreen()),
          );
        },
        backgroundColor: FreshCycleTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Listing',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _MyListingCard extends StatelessWidget {
  final Listing listing;

  const _MyListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    final imagePath = (listing.images != null && listing.images!.isNotEmpty)
        ? listing.images!.first
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FreshCycleTheme.borderColor, width: 0.5),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 10, 6, 4),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _ListingThumb(imagePath: imagePath),
            ),
            title: Text(
              listing.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: FreshCycleTheme.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Pill(
                    label: listing.category,
                    fg: FreshCycleTheme.textSecondary,
                    bg: FreshCycleTheme.surfaceGray,
                  ),
                  if (listing.expiryDate != null)
                    _Pill(
                      label: _formatDate(listing.expiryDate!),
                      fg: urgencyColor(listing.urgency),
                      bg: urgencyBgColor(listing.urgency),
                    ),
                ],
              ),
            ),
            trailing: PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PostListingScreen(existingListing: listing),
                    ),
                  );
                }
                if (value == 'delete') {
                  _confirmDelete(context, listing.id, listing.title);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                Text(
                  listing.timeAgo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: FreshCycleTheme.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  listing.isFree
                      ? 'FREE'
                      : '₱${(listing.price ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: FreshCycleTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return 'Exp. $y-$m-$d';
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String id,
    String title,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete listing?'),
          content: Text('Remove "$title" from your listings?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      context.read<ListingProvider>().removeListing(id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Listing deleted')));
    }
  }
}

class _ListingThumb extends StatelessWidget {
  final String? imagePath;

  const _ListingThumb({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return _fallback();
    }

    final uri = Uri.tryParse(imagePath!);
    final isNetwork =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    if (!isNetwork) {
      return _fallback();
    }

    return Image.network(
      imagePath!,
      width: 58,
      height: 58,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: 58,
      height: 58,
      color: FreshCycleTheme.surfaceGray,
      child: const Icon(
        Icons.image_outlined,
        color: FreshCycleTheme.textHint,
        size: 22,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;

  const _Pill({required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showAction;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showAction = true,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: FreshCycleTheme.textHint),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: FreshCycleTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: FreshCycleTheme.textSecondary,
              ),
            ),
            if (showAction) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Listing'),
                style: FilledButton.styleFrom(
                  backgroundColor: FreshCycleTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
