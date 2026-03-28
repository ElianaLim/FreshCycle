import 'package:flutter/material.dart';
import '../models/messages.dart';
import '../data/sample_data.dart';
import '../theme/app_theme.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Conversation> _filtered(ConversationContext ctx) {
    final all = sampleConversations.where((c) => c.context == ctx).toList();
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
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 20, color: FreshCycleTheme.textHint),
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
                    fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w400, fontSize: 13),
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
            builder: (_) => _ChatScreen(conversation: conversations[i]),
          ),
        ),
      ),
    );
  }
}

// ── Conversation tile ─────────────────────────────────────────────────────────

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
    final avatarIndex = c.participantId.hashCode.abs() %
        FreshCycleTheme.avatarBgs.length;

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
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Icon(Icons.check,
                                size: 8, color: Colors.white),
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
                                  fontWeight: c.hasUnread
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
                                color: c.hasUnread
                                    ? FreshCycleTheme.primary
                                    : FreshCycleTheme.textHint,
                                fontWeight: c.hasUnread
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
                                  color: c.hasUnread
                                      ? FreshCycleTheme.textPrimary
                                      : FreshCycleTheme.textSecondary,
                                  fontWeight: c.hasUnread
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (c.unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: FreshCycleTheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${c.unreadCount}',
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
          FreshCycleTheme.primaryLight
        ),
      ConversationContext.request => (
          FreshCycleTheme.requestColor,
          FreshCycleTheme.requestBg
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

// ── Chat detail screen ────────────────────────────────────────────────────────

class _ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const _ChatScreen({required this.conversation});

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.conversation.messages);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showSellerInfo(BuildContext context, Conversation c) {
    final avatarIndex =
        c.participantId.hashCode.abs() % FreshCycleTheme.avatarBgs.length;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: FreshCycleTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Avatar
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: FreshCycleTheme.avatarBgs[avatarIndex],
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    c.participantInitials,
                    style: TextStyle(
                      fontSize: 22,
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
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: FreshCycleTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.check,
                          size: 11, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Name + verified label
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  c.participantName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: FreshCycleTheme.textPrimary,
                  ),
                ),
                if (c.participantIsVerified) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: FreshCycleTheme.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Verified',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: FreshCycleTheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            const Divider(
                height: 0.5,
                thickness: 0.5,
                color: FreshCycleTheme.borderColor),
            const SizedBox(height: 16),
            // Contact rows
            if (c.participantPhone != null)
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: c.participantPhone!,
              ),
            if (c.participantBarangay != null) ...[
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: c.participantBarangay!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        id: 'new_${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'user_001',
        text: text,
        sentAt: DateTime.now(),
        status: MessageStatus.sent,
      ));
      _inputController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conversation;

    return Scaffold(
      backgroundColor: FreshCycleTheme.surfaceGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 4),
            _MiniAvatar(
              initials: c.participantInitials,
              participantId: c.participantId,
              isVerified: c.participantIsVerified,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.participantName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: FreshCycleTheme.textPrimary,
                    ),
                  ),
                  if (c.relatedListingTitle != null)
                    Text(
                      c.relatedListingTitle!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: FreshCycleTheme.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded,
                color: FreshCycleTheme.textPrimary),
            onPressed: () => _showSellerInfo(context, c),
          ),
        ],
      ),
      body: Column(
        children: [
          // Context banner
          if (c.relatedListingTitle != null)
            _ContextBanner(conversation: c),
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                final isMe = msg.senderId == 'user_001';
                final showDateSeparator = i == 0 ||
                    !_sameDay(_messages[i - 1].sentAt, msg.sentAt);
                return Column(
                  children: [
                    if (showDateSeparator) _DateSeparator(date: msg.sentAt),
                    _MessageBubble(message: msg, isMe: isMe),
                  ],
                );
              },
            ),
          ),
          // Input bar
          _InputBar(
            controller: _inputController,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MiniAvatar extends StatelessWidget {
  final String initials;
  final String participantId;
  final bool isVerified;

  const _MiniAvatar({
    required this.initials,
    required this.participantId,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    final idx =
        participantId.hashCode.abs() % FreshCycleTheme.avatarBgs.length;
    return Stack(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: FreshCycleTheme.avatarBgs[idx],
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: FreshCycleTheme.avatarFgs[idx],
            ),
          ),
        ),
        if (isVerified)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: FreshCycleTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.check, size: 7, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

class _ContextBanner extends StatelessWidget {
  final Conversation conversation;

  const _ContextBanner({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final (icon, color, bg, prefix) = switch (c.context) {
      ConversationContext.listing => (
          Icons.storefront_rounded,
          FreshCycleTheme.primary,
          FreshCycleTheme.primaryLight,
          'Listing',
        ),
      ConversationContext.request => (
          Icons.volunteer_activism_rounded,
          FreshCycleTheme.requestColor,
          FreshCycleTheme.requestBg,
          'Request',
        ),
    };

    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            '$prefix · ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Expanded(
            child: Text(
              c.relatedListingTitle!,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  String get _label {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(
              child: Divider(color: FreshCycleTheme.borderColor, thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              _label,
              style: const TextStyle(
                fontSize: 11,
                color: FreshCycleTheme.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(
              child: Divider(color: FreshCycleTheme.borderColor, thickness: 0.5)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final pushIndent = MediaQuery.of(context).size.width * 0.20;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 6,
        left: isMe ? pushIndent : 0,
        right: isMe ? 0 : pushIndent,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: isMe ? FreshCycleTheme.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border: isMe
                  ? null
                  : Border.all(
                      color: FreshCycleTheme.borderColor, width: 0.5),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                color:
                    isMe ? Colors.white : FreshCycleTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.timeLabel,
                style: const TextStyle(
                  fontSize: 10,
                  color: FreshCycleTheme.textHint,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                _StatusIcon(status: message.status),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final MessageStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      MessageStatus.sent => const Icon(Icons.check_rounded,
          size: 12, color: FreshCycleTheme.textHint),
      MessageStatus.delivered => const Icon(Icons.done_all_rounded,
          size: 12, color: FreshCycleTheme.textHint),
      MessageStatus.read => const Icon(Icons.done_all_rounded,
          size: 12, color: FreshCycleTheme.primary),
    };
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: FreshCycleTheme.textSecondary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: FreshCycleTheme.textHint,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: FreshCycleTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Write a message...',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onSend,
            style: FilledButton.styleFrom(
              backgroundColor: FreshCycleTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(14),
              minimumSize: Size.zero,
            ),
            child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
