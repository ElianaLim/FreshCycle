import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import '../models/listing.dart';
import '../models/messages.dart';
import '../theme/app_theme.dart';
import '../widgets/selling_card.dart';
import '../widgets/location_settings_sheet.dart';
import '../widgets/request_card.dart';
import 'messages_screen.dart';
import 'post_listing_screen.dart';
import 'post_request_screen.dart';
import 'package:provider/provider.dart';
import '../providers/listing_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/messages_provider.dart';
import 'listing_detail_screen.dart';
import 'request_detail_screen.dart';
import 'saved_items_screen.dart';
import '../data/db.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  String _selectedRequestStatus = 'All';
  String _selectedRequestCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String _currentLocation = 'Select Location';
  double _proximityRadius = 5.0;
  LatLng? _currentLatLng;

  static const LatLng _defaultLocation = LatLng(14.6534, 121.0681);

  final List<double> _proximityOptions = [1.0, 2.0, 5.0, 10.0, 20.0, 50.0];

  List<String> get _sellingCategories => FreshCycleTheme.foodCategories;

  List<String> get _requestStatusFilters => const [
    'All',
    'Urgent',
    'Nearby',
    'No offers',
  ];

  List<String> get _requestCategories => FreshCycleTheme.foodCategories;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedCategory = 'All';
        _selectedRequestStatus = 'All';
        _selectedRequestCategory = 'All';
      });
    });
    // Load location settings from DB
    _loadLocationSettings();
  }

  Future<void> _loadLocationSettings() async {
    try {
      final deviceId = await DB.getDeviceId();
      final settings = await DB.getLocationSettings(deviceId);

      if (settings != null && mounted) {
        setState(() {
          _currentLocation = settings['location_name'] ?? 'Select Location';
          _proximityRadius = (settings['proximity_radius'] ?? 5.0).toDouble();
          _currentLatLng = LatLng(
            (settings['latitude'] ?? 14.6534).toDouble(),
            (settings['longitude'] ?? 121.0681).toDouble(),
          );
        });
      } else if (mounted) {
        setState(() {
          _currentLatLng = _defaultLocation;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentLatLng = _defaultLocation;
        });
      }
    }
  }

  Future<void> _saveLocationSettings(
    String location,
    LatLng latLng,
    double proximity,
  ) async {
    try {
      final deviceId = await DB.getDeviceId();
      await DB.saveLocationSettings(
        deviceId: deviceId,
        locationName: location,
        latitude: latLng.latitude,
        longitude: latLng.longitude,
        proximityRadius: proximity,
      );
    } catch (e) {
      print('Failed to save location settings: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Listing> _getFilteredListings(BuildContext context) {
    List<Listing> listings = context.watch<ListingProvider>().listings;

    if (_selectedCategory != 'All') {
      listings = listings
          .where(
            (l) => l.category.toLowerCase() == _selectedCategory.toLowerCase(),
          )
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      listings = listings
          .where(
            (l) =>
                l.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                l.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }
    return listings;
  }

  List<Listing> get _filteredRequests {
    List<Listing> requests = context.watch<ListingProvider>().requests;
    switch (_selectedRequestStatus) {
      case 'Urgent':
        requests = requests
            .where((r) => r.urgency == UrgencyLevel.critical)
            .toList();
        break;
      case 'Nearby':
        requests = requests.where((r) => r.distanceKm < 1.0).toList();
        break;
      case 'No offers':
        requests = requests.where((r) => (r.offerCount ?? 0) == 0).toList();
        break;
      case 'All':
        break;
    }

    if (_selectedRequestCategory != 'All') {
      requests = requests
          .where(
            (r) =>
                r.category.toLowerCase() ==
                _selectedRequestCategory.toLowerCase(),
          )
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      requests = requests
          .where(
            (r) => r.title.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    return requests;
  }

  Future<void> _openListingConversation(
    BuildContext context,
    Listing listing, {
    bool fromListingDetail = false,
  }) async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send messages.')),
      );
      return;
    }

    final messagesProvider = context.read<MessagesProvider>();
    messagesProvider.setCurrentUser(auth.user!.id);

    final conversation = await messagesProvider.startConversation(
      participantId: listing.seller.id,
      participantName: listing.seller.name,
      participantInitials: listing.seller.initials,
      participantIsVerified: listing.seller.isVerified,
      participantBarangay: listing.seller.barangay,
      context: ConversationContext.listing,
      relatedListingId: listing.id,
      relatedListingTitle: listing.title,
      initialMessage: null,
    );

    if (!context.mounted || conversation == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversation: conversation,
          currentUserId: auth.user!.id,
          showListingPreview: fromListingDetail,
          quickQuestions: fromListingDetail
              ? const [
                  'Is this still available?',
                  'Can I pick up today?',
                  'What time works for pickup?',
                ]
              : const [],
        ),
      ),
    );
  }

  Future<void> _openRequestConversation(
    BuildContext context,
    Listing request, {
    bool fromRequestDetail = false,
  }) async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send messages.')),
      );
      return;
    }

    final messagesProvider = context.read<MessagesProvider>();
    messagesProvider.setCurrentUser(auth.user!.id);

    final conversation = await messagesProvider.startConversation(
      participantId: request.seller.id,
      participantName: request.seller.name,
      participantInitials: request.seller.initials,
      participantIsVerified: request.seller.isVerified,
      participantBarangay: request.seller.barangay,
      context: ConversationContext.request,
      relatedListingId: request.id,
      relatedListingTitle: request.title,
      initialMessage: null,
    );

    if (!context.mounted || conversation == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversation: conversation,
          currentUserId: auth.user!.id,
          showListingPreview: fromRequestDetail,
          quickQuestions: fromRequestDetail
              ? const [
                  'Can you meet today?',
                  'What quantity do you need?',
                  'Where is the pickup point?',
                ]
              : const [],
        ),
      ),
    );
  }

  Future<void> _showOfferSheet(
    BuildContext context,
    Listing listing, {
    bool fromRequestDetail = false,
  }) async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send offers.')),
      );
      return;
    }

    final offerText = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _OfferSheet(listing: listing),
    );

    if (!context.mounted) return;
    if (offerText == null || offerText.trim().isEmpty) return;

    final messagesProvider = context.read<MessagesProvider>();
    messagesProvider.setCurrentUser(auth.user!.id);

    final conversation = await messagesProvider.startConversation(
      participantId: listing.seller.id,
      participantName: listing.seller.name,
      participantInitials: listing.seller.initials,
      participantIsVerified: listing.seller.isVerified,
      participantBarangay: listing.seller.barangay,
      context: ConversationContext.request,
      relatedListingId: listing.id,
      relatedListingTitle: listing.title,
      initialMessage: null,
    );

    if (!context.mounted || conversation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open chat right now.')),
      );
      return;
    }

    final sent = await messagesProvider.sendMessage(
      conversationId: conversation.id,
      text: '[OFFER] ${offerText.trim()}',
    );

    if (!context.mounted) return;
    if (!sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send offer. Please retry.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversation: conversation,
          currentUserId: auth.user!.id,
          showListingPreview: true,
          quickQuestions: fromRequestDetail
              ? const [
                  'Can you meet today?',
                  'What quantity do you need?',
                  'Where is the pickup point?',
                ]
              : const [],
        ),
      ),
    );
  }

  void _showBuyDialog(
    BuildContext context,
    Listing listing, {
    bool fromListingDetail = false,
  }) {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to buy items.')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm purchase'),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        content: Text(
          'Price: P${(listing.price ?? 0).toStringAsFixed(2)}\n'
          'Transaction fee (2%): P${((listing.price ?? 0) * 0.02).toStringAsFixed(2)}\n'
          'Total: P${((listing.price ?? 0) * 1.02).toStringAsFixed(2)}\n\n'
          'Proceed to buyer confirmation chat for "${listing.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);

              final messagesProvider = context.read<MessagesProvider>();
              messagesProvider.setCurrentUser(auth.user!.id);

              final conversation = await messagesProvider.startConversation(
                participantId: listing.seller.id,
                participantName: listing.seller.name,
                participantInitials: listing.seller.initials,
                participantIsVerified: listing.seller.isVerified,
                participantBarangay: listing.seller.barangay,
                context: ConversationContext.listing,
                relatedListingId: listing.id,
                relatedListingTitle: listing.title,
                initialMessage: null,
              );

              if (conversation != null) {
                final alreadyRequested = conversation.messages.any(
                  (m) => m.text.startsWith('[BUY_REQUEST]'),
                );
                if (!alreadyRequested) {
                  final priceLabel = (listing.price ?? 0).toStringAsFixed(0);
                  await messagesProvider.sendMessage(
                    conversationId: conversation.id,
                    text:
                        '[BUY_REQUEST] Hi! I would like to buy "${listing.title}" for ₱$priceLabel. Is this still available?',
                  );

                  await messagesProvider.loadConversations();
                }
              }

              if (!context.mounted) return;

              if (conversation == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Unable to open chat right now.'),
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    conversation: conversation,
                    currentUserId: auth.user!.id,
                    showListingPreview: fromListingDetail,
                    quickQuestions: fromListingDetail
                        ? const [
                            'Is this still available?',
                            'Can I pick up today?',
                            'What time works for pickup?',
                          ]
                        : const [],
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: FreshCycleTheme.primary,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showLocationSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => LocationSettingsSheet(
        currentLocation: _currentLocation,
        currentLatLng: _currentLatLng ?? _defaultLocation,
        proximityRadius: _proximityRadius,
        proximityOptions: _proximityOptions,
        onLocationChanged: (location, latLng) {
          setState(() {
            _currentLocation = location;
            _currentLatLng = latLng;
          });
          // Save to DB
          _saveLocationSettings(location, latLng, _proximityRadius);
        },
        onProximityChanged: (proximity) {
          setState(() => _proximityRadius = proximity);
          // Save to DB
          if (_currentLatLng != null) {
            _saveLocationSettings(_currentLocation, _currentLatLng!, proximity);
          }
        },
      ),
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
            floating: false,
            snap: false,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset('assets/logo.svg', width: 28, height: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'Marketplace',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: FreshCycleTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showLocationSettingsSheet(context),
                      child: const Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: FreshCycleTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: GestureDetector(
                        onTap: () => _showLocationSettingsSheet(context),
                        child: Text(
                          _currentLocation,
                          style: const TextStyle(
                            fontSize: 12,
                            color: FreshCycleTheme.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.bookmark_border_rounded,
                  color: FreshCycleTheme.textPrimary,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SavedItemsScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: FreshCycleTheme.textPrimary,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MessagesScreen()),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search listings and requests...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: FreshCycleTheme.textHint,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: FreshCycleTheme.borderColor,
                            width: 0.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: FreshCycleTheme.borderColor,
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: FreshCycleTheme.primary,
                            width: 1,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        hintStyle: const TextStyle(
                          color: FreshCycleTheme.textHint,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Listings'),
                      Tab(text: 'Requests'),
                    ],
                    labelColor: FreshCycleTheme.primary,
                    unselectedLabelColor: FreshCycleTheme.textSecondary,
                    indicatorColor: FreshCycleTheme.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
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
              onCategorySelected: (c) => setState(() => _selectedCategory = c),
              onBuy: (l) => _showBuyDialog(context, l),
              onMessage: (l) => _openListingConversation(context, l),
              onBuyFromDetail: (l) =>
                  _showBuyDialog(context, l, fromListingDetail: true),
              onMessageFromDetail: (l) =>
                  _openListingConversation(context, l, fromListingDetail: true),
            ),
            _RequestsTab(
              requests: _filteredRequests,
              categories: _requestCategories,
              statusFilters: _requestStatusFilters,
              selectedStatus: _selectedRequestStatus,
              selectedCategory: _selectedRequestCategory,
              onStatusSelected: (v) =>
                  setState(() => _selectedRequestStatus = v),
              onCategorySelected: (c) =>
                  setState(() => _selectedRequestCategory = c),
              onOffer: (l) => _showOfferSheet(context, l),
              onOfferFromDetail: (l) =>
                  _showOfferSheet(context, l, fromRequestDetail: true),
              onMessageFromDetail: (l) =>
                  _openRequestConversation(context, l, fromRequestDetail: true),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PostListingScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PostRequestScreen(),
              ),
            );
          }
        },
        backgroundColor: FreshCycleTheme.primary,
        foregroundColor: Colors.white,
        icon: Icon(
          _tabController.index == 0
              ? Icons.add_rounded
              : Icons.playlist_add_rounded,
        ),
        label: Text(
          _tabController.index == 0 ? 'Post listing' : 'Make request',
          style: const TextStyle(fontWeight: FontWeight.w600),
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
  final Color selectedColor;
  final Color selectedTextColor;
  final Color unselectedBackgroundColor;
  final Color unselectedTextColor;

  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.selectedColor = FreshCycleTheme.primary,
    this.selectedTextColor = Colors.white,
    this.unselectedBackgroundColor = Colors.white,
    this.unselectedTextColor = FreshCycleTheme.textSecondary,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : unselectedBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? selectedColor
                      : FreshCycleTheme.borderColor,
                  width: 0.5,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? selectedTextColor : unselectedTextColor,
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
  final void Function(Listing) onBuy;
  final void Function(Listing) onMessage;
  final void Function(Listing) onBuyFromDetail;
  final void Function(Listing) onMessageFromDetail;

  const _ListingsTab({
    required this.listings,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onBuy,
    required this.onMessage,
    required this.onBuyFromDetail,
    required this.onMessageFromDetail,
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 260,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => SellingCard(
                  listing: listings[i],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ListingDetailScreen(
                          listing: listings[i],
                          onBuy: () => onBuyFromDetail(listings[i]),
                          onMessage: () => onMessageFromDetail(listings[i]),
                        ),
                      ),
                    );
                  },
                  onBuy: () => onBuy(listings[i]),
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
  final List<String> statusFilters;
  final String selectedStatus;
  final String selectedCategory;
  final ValueChanged<String> onStatusSelected;
  final ValueChanged<String> onCategorySelected;
  final void Function(Listing) onOffer;
  final void Function(Listing) onOfferFromDetail;
  final void Function(Listing) onMessageFromDetail;

  const _RequestsTab({
    required this.requests,
    required this.categories,
    required this.statusFilters,
    required this.selectedStatus,
    required this.selectedCategory,
    required this.onStatusSelected,
    required this.onCategorySelected,
    required this.onOffer,
    required this.onOfferFromDetail,
    required this.onMessageFromDetail,
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
                categories: statusFilters,
                selected: selectedStatus,
                onSelected: onStatusSelected,
                selectedColor: FreshCycleTheme.requestColor,
                selectedTextColor: Colors.white,
                unselectedBackgroundColor: FreshCycleTheme.requestBg,
                unselectedTextColor: FreshCycleTheme.requestColor,
              ),
              const SizedBox(height: 8),
              _CategoryFilter(
                categories: categories,
                selected: selectedCategory,
                onSelected: onCategorySelected,
                selectedColor: FreshCycleTheme.primary,
                selectedTextColor: Colors.white,
                unselectedBackgroundColor: Colors.white,
                unselectedTextColor: FreshCycleTheme.textSecondary,
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RequestDetailScreen(
                            request: requests[i],
                            onOffer: () => onOfferFromDetail(requests[i]),
                            onMessage: () => onMessageFromDetail(requests[i]),
                          ),
                        ),
                      );
                    },
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

class _MessageSheet extends StatefulWidget {
  final Listing listing;

  const _MessageSheet({required this.listing});

  @override
  State<_MessageSheet> createState() => _MessageSheetState();
}

class _MessageSheetState extends State<_MessageSheet> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final messagesProvider = context.read<MessagesProvider>();

      if (authProvider.user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to send messages')),
          );
        }
        return;
      }

      final conversation = await messagesProvider.startConversation(
        participantId: widget.listing.seller.id,
        participantName: widget.listing.seller.name,
        participantInitials: widget.listing.seller.initials,
        participantIsVerified: widget.listing.seller.isVerified,
        context: ConversationContext.listing,
        relatedListingId: widget.listing.id,
        relatedListingTitle: widget.listing.title,
        initialMessage: text,
      );

      if (mounted) {
        Navigator.pop(context);

        if (conversation != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MessagesScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
            Text(
              'Message ${widget.listing.seller.name}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: FreshCycleTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Re: ${widget.listing.title}',
              style: const TextStyle(
                fontSize: 13,
                color: FreshCycleTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                        'Is this still available?',
                        'Can I pick up today?',
                        'What time works for pickup?',
                      ]
                      .map(
                        (msg) => GestureDetector(
                          onTap: () => _sendMessage(msg),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: FreshCycleTheme.primaryLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: FreshCycleTheme.primary,
                                width: 0.5,
                              ),
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
                    controller: _messageController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Write a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: FreshCycleTheme.borderColor,
                          width: 0.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: FreshCycleTheme.borderColor,
                          width: 0.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: FreshCycleTheme.primary,
                          width: 1,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _isSending
                      ? null
                      : () => _sendMessage(_messageController.text),
                  style: FilledButton.styleFrom(
                    backgroundColor: FreshCycleTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(14),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
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

class _OfferSheet extends StatefulWidget {
  final Listing listing;

  const _OfferSheet({required this.listing});

  @override
  State<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<_OfferSheet> {
  final TextEditingController _offerController = TextEditingController();

  @override
  void dispose() {
    _offerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
              'Responding to: ${widget.listing.title}',
              style: const TextStyle(
                fontSize: 13,
                color: FreshCycleTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _offerController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                final offerText = _offerController.text.trim();
                if (offerText.isNotEmpty) {
                  Navigator.pop(context, offerText);
                }
              },
              decoration: InputDecoration(
                hintText: 'Describe what you can offer...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: FreshCycleTheme.borderColor,
                    width: 0.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: FreshCycleTheme.borderColor,
                    width: 0.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: FreshCycleTheme.primary,
                    width: 1,
                  ),
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
                onPressed: () {
                  final offerText = _offerController.text.trim();
                  if (offerText.isEmpty) return;
                  Navigator.pop(context, offerText);
                },
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
