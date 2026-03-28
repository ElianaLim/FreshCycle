import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/navigation_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeProvider();
  }
  
  void _initializeProvider() {
    final authProvider = context.read<AuthProvider>();
    final notificationsProvider = context.read<NotificationsProvider>();
    
    if (authProvider.user != null) {
      notificationsProvider.initialize(authProvider.user!.id);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final auth = context.read<AuthProvider>();
        final notif = context.read<NotificationsProvider>();
        if (auth.user != null) {
          notif.initialize(auth.user!.id);
        } else {
          notif.initializeGuest();
        }
      });
    }
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
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: FreshCycleTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Consumer<NotificationsProvider>(
            builder: (context, provider, _) {
              if (provider.notifications.isEmpty) {
                return const SizedBox.shrink();
              }
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: FreshCycleTheme.textPrimary, size: 22),
                onSelected: (value) async {
                  if (value == 'mark_all_read') {
                    await provider.markAllAsRead();
                  } else if (value == 'clear_all') {
                    _showClearConfirmation(context, provider);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.done_all_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Mark all as read'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 20,
                            color: FreshCycleTheme.urgencyCritical),
                        SizedBox(width: 12),
                        Text('Clear all',
                            style: TextStyle(
                                color: FreshCycleTheme.urgencyCritical)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: FreshCycleTheme.primary,
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: FreshCycleTheme.textHint.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: FreshCycleTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'You\'ll see updates about your listings, messages, and pantry expiry reminders here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: FreshCycleTheme.textHint,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 32),
            itemCount: provider.notifications.length,
            itemBuilder: (context, i) {
              final notification = provider.notifications[i];
              return _NotificationTile(
                notification: notification,
                isLast: i == provider.notifications.length - 1,
                onTap: () => _handleNotificationTap(context, notification),
                onDismiss: () => provider.deleteNotification(notification.id),
              );
            },
          );
        },
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, AppNotification notification) async {
    final provider = context.read<NotificationsProvider>();
    final nav = context.read<NavigationProvider>();

    if (!notification.isRead) {
      await provider.markAsRead(notification.id);
    }

    final isPantryNotif = notification.type == NotificationType.pantryExpired ||
        notification.type == NotificationType.pantryExpiresToday ||
        notification.type == NotificationType.pantryExpiresTomorrow ||
        notification.type == NotificationType.pantryExpiringSoon;

    if (isPantryNotif && notification.relatedId != null) {
      nav.navigateToPantryItem(notification.relatedId!);
    }
  }

  void _showClearConfirmation(BuildContext context, NotificationsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.clearAll();
            },
            style: TextButton.styleFrom(
              foregroundColor: FreshCycleTheme.urgencyCritical,
            ),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.isLast,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;
    
    // Get icon and color based on notification type
    final (icon, iconColor, bgColor) = _getIconForType(n.type);
    
    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: FreshCycleTheme.urgencyCritical,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: n.isRead ? Colors.white : FreshCycleTheme.primaryLight.withValues(alpha: 0.3),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon container
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, size: 20, color: iconColor),
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
                                  n.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: n.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    color: FreshCycleTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                n.timeLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: n.isRead
                                      ? FreshCycleTheme.textHint
                                      : FreshCycleTheme.primary,
                                  fontWeight: n.isRead
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            n.body,
                            style: TextStyle(
                              fontSize: 13,
                              color: n.isRead
                                  ? FreshCycleTheme.textSecondary
                                  : FreshCycleTheme.textPrimary,
                              fontWeight: n.isRead
                                  ? FontWeight.w400
                                  : FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Unread indicator
                    if (!n.isRead)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: FreshCycleTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: 68,
                  color: FreshCycleTheme.borderColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color, Color) _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.newMessage:
        return (Icons.chat_rounded, FreshCycleTheme.primary, FreshCycleTheme.primaryLight);
      case NotificationType.listingSaved:
        return (Icons.bookmark_rounded, FreshCycleTheme.accent, FreshCycleTheme.primaryLight);
      case NotificationType.listingExpired:
        return (Icons.schedule_rounded, FreshCycleTheme.urgencySoon, FreshCycleTheme.urgencySoonBg);
      case NotificationType.newListing:
        return (Icons.new_releases_rounded, FreshCycleTheme.urgencyCritical, FreshCycleTheme.urgencyCriticalBg);
      case NotificationType.offerReceived:
        return (Icons.local_offer_rounded, FreshCycleTheme.requestColor, FreshCycleTheme.requestBg);
      case NotificationType.offerAccepted:
        return (Icons.check_circle_rounded, FreshCycleTheme.urgencySafe, FreshCycleTheme.urgencySafeBg);
      case NotificationType.offerRejected:
        return (Icons.cancel_rounded, FreshCycleTheme.urgencyCritical, FreshCycleTheme.urgencyCriticalBg);
      case NotificationType.pantryExpiringSoon:
        return (Icons.warning_amber_rounded, FreshCycleTheme.urgencySoon, FreshCycleTheme.urgencySoonBg);
      case NotificationType.pantryExpiresTomorrow:
        return (Icons.warning_amber_rounded, FreshCycleTheme.urgencySoon, FreshCycleTheme.urgencySoonBg);
      case NotificationType.pantryExpiresToday:
        return (Icons.warning_rounded, FreshCycleTheme.urgencyCritical, FreshCycleTheme.urgencyCriticalBg);
      case NotificationType.pantryExpired:
        return (Icons.cancel_rounded, FreshCycleTheme.urgencyCritical, FreshCycleTheme.urgencyCriticalBg);
    }
  }
}