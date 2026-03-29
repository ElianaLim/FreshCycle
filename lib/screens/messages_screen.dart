import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/messages.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/listing_provider.dart';
import '../providers/messages_provider.dart';
import 'listing_detail_screen.dart';
import 'rewards_screen.dart';
import '../providers/notifications_provider.dart';

class MessagesScreen extends StatefulWidget {
  final String? initialConversationId;

  const MessagesScreen({super.key, this.initialConversationId});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _openedInitialConversation = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize messages provider with current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final messagesProvider = context.read<MessagesProvider>();
      if (authProvider.user != null) {
        messagesProvider.initialize(authProvider.user!.id).then((_) {
          _openInitialConversationIfNeeded();
        });
      }
    });
  }

  void _openInitialConversationIfNeeded() {
    if (_openedInitialConversation) return;
    final initialId = widget.initialConversationId;
    if (initialId == null || initialId.isEmpty) return;

    if (!mounted) return;

    final messagesProvider = Provider.of<MessagesProvider>(
      context,
      listen: false,
    );
    Conversation? conversation;
    try {
      conversation = messagesProvider.conversations.firstWhere(
        (c) => c.id == initialId,
      );
    } catch (_) {
      conversation = null;
    }

    if (conversation == null) return;
    _openedInitialConversation = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversation: conversation!,
            currentUserId: context.read<AuthProvider>().user?.id ?? '',
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Conversation> _filtered(ConversationContext ctx) {
    final messagesProvider = context.watch<MessagesProvider>();
    final all = messagesProvider.conversations
        .where((c) => c.context == ctx)
        .toList();
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all.where((c) {
      return c.participantName.toLowerCase().contains(q) ||
          (c.relatedListingTitle?.toLowerCase().contains(q) ?? false) ||
          (c.lastMessage?.text.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FreshCycleTheme.surfaceGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: FreshCycleTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search messages...',
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
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.storefront_rounded, size: 15),
                        SizedBox(width: 6),
                        Text('Listings'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volunteer_activism_rounded, size: 15),
                        SizedBox(width: 6),
                        Text('Requests'),
                      ],
                    ),
                  ),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _ConversationList(
            conversations: _filtered(ConversationContext.listing),
          ),
          _ConversationList(
            conversations: _filtered(ConversationContext.request),
          ),
        ],
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  final List<Conversation> conversations;

  const _ConversationList({required this.conversations});

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return const Center(
        child: Text(
          'No conversations found',
          style: TextStyle(color: FreshCycleTheme.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: conversations.length,
      itemBuilder: (context, i) => _ConversationTile(
        conversation: conversations[i],
        isLast: i == conversations.length - 1,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) {
              final authProvider = context.read<AuthProvider>();
              return ChatScreen(
                conversation: conversations[i],
                currentUserId: authProvider.user?.id ?? '',
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isLast;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final avatarIndex =
        c.participantId.hashCode.abs() % FreshCycleTheme.avatarBgs.length;

    final notificationsProvider = context.watch<NotificationsProvider>();
    final unreadCount = notificationsProvider
        .getUnreadMessageNotificationsCount(c.id);
    final hasUnread = unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: FreshCycleTheme.avatarBgs[avatarIndex],
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          c.participantInitials,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: FreshCycleTheme.avatarFgs[avatarIndex],
                          ),
                        ),
                      ),
                      if (c.participantIsVerified)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: FreshCycleTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.participantName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: hasUnread
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: FreshCycleTheme.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              c.lastActiveLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: hasUnread
                                    ? FreshCycleTheme.primary
                                    : FreshCycleTheme.textHint,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        if (c.relatedListingTitle != null) ...[
                          const SizedBox(height: 2),
                          _ContextChip(
                            label: c.relatedListingTitle!,
                            context: c.context,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.lastMessagePreview,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: hasUnread
                                      ? FreshCycleTheme.textPrimary
                                      : FreshCycleTheme.textSecondary,
                                  fontWeight: hasUnread
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: FreshCycleTheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              const Divider(
                height: 0.5,
                thickness: 0.5,
                indent: 74,
                color: FreshCycleTheme.borderColor,
              ),
          ],
        ),
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  final String label;
  final ConversationContext context;

  const _ContextChip({required this.label, required this.context});

  @override
  Widget build(BuildContext buildContext) {
    final (color, bg) = switch (context) {
      ConversationContext.listing => (
        FreshCycleTheme.primary,
        FreshCycleTheme.primaryLight,
      ),
      ConversationContext.request => (
        FreshCycleTheme.requestColor,
        FreshCycleTheme.requestBg,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final String currentUserId;
  final bool showListingPreview;
  final List<String> quickQuestions;

  const ChatScreen({
    super.key,
    required this.conversation,
    required this.currentUserId,
    this.showListingPreview = false,
    this.quickQuestions = const [],
  });

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<ChatMessage> _messages;
  Timer? _refreshTimer;
  bool _isMarkingComplete = false;
  bool _isBuyerConfirming = false;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.conversation.messages);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messagesProvider = context.read<MessagesProvider>();
      messagesProvider.markAsRead(widget.conversation.id);
      messagesProvider.refreshConversation(widget.conversation.id);
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      context.read<MessagesProvider>().refreshConversation(
        widget.conversation.id,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
    });

    final listingId = widget.conversation.relatedListingId;
    if (listingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ListingProvider>().refreshTransactionState(listingId);
      });
    }
  }

  Future<void> _markAsRead() async {
    if (!widget.conversation.hasUnread) return;

    final messagesProvider = context.read<MessagesProvider>();
    final notificationsProvider = context.read<NotificationsProvider>();

    await messagesProvider.markAsReadWithNotifications(widget.conversation.id, (
      notificationId,
    ) {
      notificationsProvider.markAsRead(notificationId);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_inputController.text.trim().isEmpty) return;
    final text = _inputController.text.trim();
    _inputController.clear();

    final messagesProvider = context.read<MessagesProvider>();
    final success = await messagesProvider.sendMessage(
      conversationId: widget.conversation.id,
      text: text,
    );

    if (success && mounted) {
      final updated = messagesProvider.getConversation(widget.conversation.id);
      if (updated != null) {
        setState(() {
          _messages = List.from(updated.messages);
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _openRelatedListing() {
    final c = widget.conversation;
    final listingId = c.relatedListingId;
    if (listingId == null) return;

    final listingProvider = context.read<ListingProvider>();
    try {
      final listing = listingProvider.listings.firstWhere(
        (l) => l.id == listingId,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ListingDetailScreen(listing: listing),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Listing not available')));
    }
  }

  Future<void> _markTransactionComplete() async {
    final listingId = widget.conversation.relatedListingId;
    if (listingId == null || _isMarkingComplete) return;

    final listingProvider = context.read<ListingProvider>();
    final buyerId = widget.conversation.participantId;
    if (!listingProvider.isBuyerConfirmedForListing(
      listingId,
      buyerId: buyerId,
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Seller can complete only after buyer confirms purchase.',
            ),
          ),
        );
      }
      return;
    }

    double? soldPrice;
    try {
      soldPrice = listingProvider.listings
          .firstWhere((l) => l.id == listingId)
          .price;
    } catch (_) {
      soldPrice = null;
    }
    final rewardPoints = (soldPrice != null && soldPrice > 0)
        ? (soldPrice * 0.05).round()
        : 0;

    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark transaction complete?'),
        content: Text(
          rewardPoints > 0
              ? 'This will finish the transaction, remove the listing from marketplace, and grant +$rewardPoints reward points (5% of sale price).'
              : 'This will finish the transaction, remove the listing from marketplace, and grant reward points.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (shouldComplete != true || !mounted) return;

    setState(() => _isMarkingComplete = true);
    final didComplete = await listingProvider.completeListingTransaction(
      listingId,
      sellerId: widget.currentUserId,
    );

    if (didComplete) {
      if (rewardPoints > 0) {
        await context.read<AuthProvider>().addRewardPoints(rewardPoints);
      }
      if (!mounted) return;
      final shouldOpenRewards = await _showRewardCelebrationDialog(
        rewardPoints,
      );
      if (!mounted) return;
      if (shouldOpenRewards) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RewardsScreen()),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This transaction is already completed.')),
      );
    }

    if (mounted) {
      setState(() => _isMarkingComplete = false);
    }
  }

  Future<void> _confirmBuyerPurchase() async {
    final listingId = widget.conversation.relatedListingId;
    if (listingId == null || _isBuyerConfirming) return;

    final listingProvider = context.read<ListingProvider>();
    final listing = listingProvider.listings.where((l) => l.id == listingId);
    final resolved = listing.isNotEmpty ? listing.first : null;
    final basePrice = resolved?.price ?? 0;
    final fee = basePrice * 0.02;
    final total = basePrice + fee;

    final shouldConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm purchase'),
        content: Text(
          'Price: P${basePrice.toStringAsFixed(2)}\n'
          'Transaction fee (2%): P${fee.toStringAsFixed(2)}\n'
          'Total: P${total.toStringAsFixed(2)}\n\n'
          'By confirming, the seller will be allowed to finalize this transaction.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm Buy'),
          ),
        ],
      ),
    );

    if (shouldConfirm != true || !mounted) return;

    setState(() => _isBuyerConfirming = true);
    final confirmed = await listingProvider.confirmBuyerPurchaseIntent(
      listingId: listingId,
      buyerId: widget.currentUserId,
      sellerId: resolved?.seller.id ?? widget.conversation.participantId,
      agreedPrice: resolved?.price,
      feePercent: 0.02,
    );

    if (confirmed) {
      final messagesProvider = context.read<MessagesProvider>();
      await messagesProvider.sendMessage(
        conversationId: widget.conversation.id,
        text:
            '[BUYER_CONFIRMED] I confirm this purchase. I understand there is a 2% transaction fee.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Purchase confirmed. Waiting for seller to complete.',
            ),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to confirm purchase. Try again.')),
      );
    }

    if (mounted) {
      setState(() => _isBuyerConfirming = false);
    }
  }

  Future<bool> _showRewardCelebrationDialog(int points) async {
    final confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    confettiController.play();

    final shouldOpenRewards = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ConfettiWidget(
                  confettiController: confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  emissionFrequency: 0.04,
                  numberOfParticles: 16,
                  maxBlastForce: 22,
                  minBlastForce: 8,
                  gravity: 0.15,
                  colors: const [
                    FreshCycleTheme.primary,
                    FreshCycleTheme.requestColor,
                    Colors.amber,
                    Colors.teal,
                    Colors.orange,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 52,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Transaction completed!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You earned +$points reward points',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: FreshCycleTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('View rewards'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Awesome!'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    confettiController.dispose();
    return shouldOpenRewards ?? false;
  }

  Widget _buildListingPreviewTile() {
    final c = widget.conversation;
    // Show preview for any chat tied to a listing, including seller-side chats.
    final listingId = c.relatedListingId;
    if (c.relatedListingTitle == null || listingId == null) {
      return const SizedBox.shrink();
    }

    final listingProvider = context.watch<ListingProvider>();
    final listing = listingProvider.listings.where(
      (l) => l.id == c.relatedListingId,
    );
    final resolved = listing.isNotEmpty ? listing.first : null;
    final isCompleted = listingProvider.isListingCompleted(listingId);
    final isSeller = listingProvider.isSellerForListing(
      listingId,
      widget.currentUserId,
    );
    final txState = listingProvider.transactionStateForListing(listingId);
    final isBuyerConfirmedForThisChat =
        txState != null &&
        txState.buyerConfirmed &&
        txState.buyerId == c.participantId;
    final isBuyer = !isSeller;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: InkWell(
        onTap: isCompleted ? null : _openRelatedListing,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isCompleted ? FreshCycleTheme.surfaceGray : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FreshCycleTheme.borderColor, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: FreshCycleTheme.surfaceGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    (resolved?.images != null && resolved!.images!.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          resolved.images!.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.inventory_2_outlined,
                            color: FreshCycleTheme.textHint,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2_outlined,
                        color: FreshCycleTheme.textHint,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.relatedListingTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? FreshCycleTheme.textHint
                            : FreshCycleTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCompleted
                          ? 'Transaction completed'
                          : isSeller && !isBuyerConfirmedForThisChat
                          ? 'Waiting for buyer confirmation'
                          : isBuyer && txState?.buyerConfirmed == true
                          ? 'Purchase confirmed. Waiting for seller.'
                          : resolved?.price != null
                          ? '₱${resolved!.price!.toStringAsFixed(0)}'
                          : 'Tap to view details',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted
                            ? FreshCycleTheme.textHint
                            : FreshCycleTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (isBuyer && !isCompleted)
                FilledButton(
                  onPressed:
                      (txState?.buyerConfirmed == true || _isBuyerConfirming)
                      ? null
                      : _confirmBuyerPurchase,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  child: _isBuyerConfirming
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          txState?.buyerConfirmed == true
                              ? 'Confirmed'
                              : 'Confirm Buy',
                          style: const TextStyle(fontSize: 11),
                        ),
                )
              else if (isSeller)
                GestureDetector(
                  onTap:
                      isCompleted ||
                          _isMarkingComplete ||
                          !isBuyerConfirmedForThisChat
                      ? null
                      : _markTransactionComplete,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? FreshCycleTheme.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted
                            ? FreshCycleTheme.primary
                            : FreshCycleTheme.primary,
                      ),
                    ),
                    child: _isMarkingComplete
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: FreshCycleTheme.primary,
                            ),
                          )
                        : Icon(
                            Icons.check,
                            size: 16,
                            color: isCompleted
                                ? Colors.white
                                : FreshCycleTheme.primary,
                          ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: isCompleted
                      ? FreshCycleTheme.textHint
                      : FreshCycleTheme.textHint,
                ),
              if (isCompleted) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.lock_rounded,
                  size: 16,
                  color: FreshCycleTheme.textHint,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickQuestions() {
    if (widget.quickQuestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: widget.quickQuestions
              .map(
                (q) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(q, style: const TextStyle(fontSize: 12)),
                    backgroundColor: FreshCycleTheme.primaryLight,
                    side: const BorderSide(
                      color: FreshCycleTheme.primary,
                      width: 0.5,
                    ),
                    onPressed: () async {
                      _inputController.text = q;
                      await Future<void>.delayed(
                        const Duration(milliseconds: 1),
                      );
                      _sendMessage();
                    },
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conversation;
    final isListingChat = c.context == ConversationContext.listing;
    final messagesProvider = context.watch<MessagesProvider>();
    final updatedConv = messagesProvider.getConversation(c.id);

    final hasNewMessages =
        updatedConv != null && updatedConv.messages.length > _messages.length;
    final currentLastId = _messages.isNotEmpty ? _messages.last.id : null;
    final hasMessageChanges =
        updatedConv != null &&
        (updatedConv.messages.length != _messages.length ||
            (updatedConv.lastMessage?.id != currentLastId));

    if (hasMessageChanges) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _messages = List.from(updatedConv.messages);
          });
          if (hasNewMessages) {
            _scrollToBottom();
          }
        }
      });
    }

    final avatarIndex =
        c.participantId.hashCode.abs() % FreshCycleTheme.avatarBgs.length;

    return Scaffold(
      backgroundColor: FreshCycleTheme.surfaceGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: FreshCycleTheme.avatarBgs[avatarIndex],
              child: Text(
                c.participantInitials,
                style: TextStyle(
                  color: FreshCycleTheme.avatarFgs[avatarIndex],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isListingChat
                        ? (c.relatedListingTitle ?? 'Listing chat')
                        : c.participantName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (c.relatedListingTitle != null)
                    GestureDetector(
                      onTap: _openRelatedListing,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.open_in_new_rounded,
                            size: 12,
                            color: FreshCycleTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'View listing details',
                              style: const TextStyle(
                                fontSize: 12,
                                color: FreshCycleTheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isListingChat)
                    const Text(
                      'Listing chat',
                      style: TextStyle(
                        fontSize: 12,
                        color: FreshCycleTheme.textSecondary,
                      ),
                    ),
                  if (!isListingChat && c.relatedListingTitle != null)
                    Text(
                      'Re: ${c.relatedListingTitle}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: FreshCycleTheme.textSecondary,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildListingPreviewTile(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true, // Show newest at the bottom
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[_messages.length - 1 - index];
                final isMe = msg.senderId == widget.currentUserId;
                return _buildMessageBubble(msg, isMe);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? FreshCycleTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(20),
            bottomLeft: !isMe
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
          border: isMe ? null : Border.all(color: FreshCycleTheme.borderColor),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: isMe ? Colors.white : FreshCycleTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuickQuestions(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: FreshCycleTheme.surfaceGray,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: FreshCycleTheme.primary,
                child: IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
