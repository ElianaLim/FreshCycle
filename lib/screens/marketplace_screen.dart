import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../data/sample_data.dart';
import '../theme/app_theme.dart';
import '../widgets/selling_card.dart';
import '../widgets/request_card.dart';
import 'messages_screen.dart';
import 'post_listing_screen.dart';
import 'package:provider/provider.dart';
import '../providers/listing_provider.dart';
import 'listing_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _sellingCategories = [
    'All',
    'Produce',
    'Dairy',
    'Bakery',
    'Meat & fish',
    'Meals & leftovers',
    'Snacks',
    'Beverages',
    'Other',
  ];

  final List<String> _requestCategories = [
    'All',
    'Urgent',
    'Nearby',
    'No offers',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedCategory = 'All';
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Listing> _getFilteredListings(BuildContext context) {
    // Read from the provider instead of sampleListings directly
    List<Listing> listings = context.watch<ListingProvider>().listings;
    
    if (_selectedCategory != 'All') {
      listings = listings
          .where((l) =>
              l.category.toLowerCase() ==
              _selectedCategory.toLowerCase())
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      listings = listings
          .where((l) =>
              l.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              l.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return listings;
  }

  List<Listing> get _filteredRequests {
    List<Listing> requests = sampleRequests;
    switch (_selectedCategory) {
      case 'Urgent':
        requests = requests
            .where((r) => r.urgency == UrgencyLevel.critical)
            .toList();
        break;
      case 'Nearby':
        requests = requests.where((r) => r.distanceKm < 1.0).toList();
        break;
      case 'No offers':
        requests =
            requests.where((r) => (r.offerCount ?? 0) == 0).toList();
        break;
    }
    if (_searchQuery.isNotEmpty) {
      requests = requests
          .where((r) =>
              r.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return requests;
  }

  void _showMessageSheet(BuildContext context, Listing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _MessageSheet(listing: listing),
    );
  }

  void _showOfferSheet(BuildContext context, Listing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _OfferSheet(listing: listing),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FreshCycleTheme.surfaceGray,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: Colors.white,
            floating: true,
            snap: true,
            pinned: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Marketplace',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: FreshCycleTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 12,
                      color: FreshCycleTheme.primary,
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      'Diliman, Quezon City',
                      style: TextStyle(
                        fontSize: 12,
                        color: FreshCycleTheme.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.tune_rounded,
                  color: FreshCycleTheme.textPrimary,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: FreshCycleTheme.textPrimary,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MessagesScreen(),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search near-expiry food...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: FreshCycleTheme.textHint,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: FreshCycleTheme.borderColor, width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: FreshCycleTheme.borderColor, width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: FreshCycleTheme.primary, width: 1),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        hintStyle: const TextStyle(
                            color: FreshCycleTheme.textHint, fontSize: 14),
                      ),
                    ),
                  ),
                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Near-expiry listings'),
                      Tab(text: 'Requests'),
                    ],
                    labelColor: FreshCycleTheme.primary,
                    unselectedLabelColor: FreshCycleTheme.textSecondary,
                    indicatorColor: FreshCycleTheme.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w400, fontSize: 13),
                    dividerColor: FreshCycleTheme.borderColor,
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _ListingsTab(
              listings: _getFilteredListings(context),
              categories: _sellingCategories,
              selectedCategory: _selectedCategory,
              onCategorySelected: (c) =>
                  setState(() => _selectedCategory = c),
              onMessage: (l) => _showMessageSheet(context, l),
            ),
            _RequestsTab(
              requests: _filteredRequests,
              categories: _requestCategories,
              selectedCategory: _selectedCategory,
              onCategorySelected: (c) =>
                  setState(() => _selectedCategory = c),
              onOffer: (l) => _showOfferSheet(context, l),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PostListingScreen(),
            ),
          );
        },
        backgroundColor: FreshCycleTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Post listing',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _StatItem(label: 'Listings nearby', value: '34'),
          _divider(),
          _StatItem(label: 'kg saved this week', value: '12.4'),
          _divider(),
          _StatItem(label: 'Requests open', value: '8'),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 0.5,
        height: 30,
        color: FreshCycleTheme.borderColor,
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: FreshCycleTheme.primary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: FreshCycleTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = cat == selected;
          return GestureDetector(
            onTap: () => onSelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? FreshCycleTheme.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? FreshCycleTheme.primary
                      : FreshCycleTheme.borderColor,
                  width: 0.5,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : FreshCycleTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ListingsTab extends StatelessWidget {
  final List<Listing> listings;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final void Function(Listing) onMessage;

  const _ListingsTab({
    required this.listings,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const _StatsBar(),
              const SizedBox(height: 12),
              _CategoryFilter(
                categories: categories,
                selected: selectedCategory,
                onSelected: onCategorySelected,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        if (listings.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text(
                'No listings found',
                style: TextStyle(color: FreshCycleTheme.textSecondary),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 380,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => SellingCard(
                  listing: listings[i],
                  // Connect the Tap here
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ListingDetailScreen(
                          listing: listings[i],
                          onMessage: () => onMessage(listings[i]), 
                        ),
                      ),
                    );
                  },
                  onMessage: () => onMessage(listings[i]),
                ),
                childCount: listings.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _RequestsTab extends StatelessWidget {
  final List<Listing> requests;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final void Function(Listing) onOffer;

  const _RequestsTab({
    required this.requests,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onOffer,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const _StatsBar(),
              const SizedBox(height: 12),
              _CategoryFilter(
                categories: categories,
                selected: selectedCategory,
                onSelected: onCategorySelected,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        if (requests.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text(
                'No requests found',
                style: TextStyle(color: FreshCycleTheme.textSecondary),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RequestCard(
                    listing: requests[i],
                    onTap: () {},
                    onOffer: () => onOffer(requests[i]),
                  ),
                ),
                childCount: requests.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _MessageSheet extends StatelessWidget {
  final Listing listing;

  const _MessageSheet({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: FreshCycleTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Message ${listing.seller.name}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: FreshCycleTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Re: ${listing.title}',
              style: const TextStyle(
                fontSize: 13,
                color: FreshCycleTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // Quick reply chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Is this still available?',
                'Can I pick up today?',
                'What time works for pickup?',
              ]
                  .map(
                    (msg) => GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: FreshCycleTheme.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: FreshCycleTheme.primary, width: 0.5),
                        ),
                        child: Text(
                          msg,
                          style: const TextStyle(
                            fontSize: 12,
                            color: FreshCycleTheme.primaryDark,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Write a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: FreshCycleTheme.borderColor, width: 0.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: FreshCycleTheme.borderColor, width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: FreshCycleTheme.primary, width: 1),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: FreshCycleTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(14),
                  ),
                  child: const Icon(Icons.send_rounded,
                      size: 18, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _OfferSheet extends StatelessWidget {
  final Listing listing;

  const _OfferSheet({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: FreshCycleTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Make an offer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: FreshCycleTheme.textPrimary,
              ),
            ),
            Text(
              'Responding to: ${listing.title}',
              style: const TextStyle(
                fontSize: 13,
                color: FreshCycleTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Describe what you can offer...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: FreshCycleTheme.borderColor, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: FreshCycleTheme.borderColor, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: FreshCycleTheme.primary, width: 1),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(14),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: FreshCycleTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Send offer',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
