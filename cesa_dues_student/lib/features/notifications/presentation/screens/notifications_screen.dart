import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../app/theme/app_colors.dart';
import '../controllers/notifications_controller.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(studentNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications'),
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final n = notifications[index];
              final isUnread = !n.isRead;
              
              IconData icon;
              Color iconColor;
              if (n.type == NotificationType.paymentConfirmation) {
                icon = Icons.check_circle;
                iconColor = AppColors.success;
              } else if (n.type == NotificationType.reminder) {
                icon = Icons.warning_amber_rounded;
                iconColor = AppColors.warning;
              } else {
                icon = Icons.campaign;
                iconColor = AppColors.primary;
              }

              return ListTile(
                onTap: () {
                  ref.read(notificationsControllerProvider.notifier).markAsRead(n);
                  // Optionally show a dialog with full message if it's long
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(icon, color: iconColor),
                          const SizedBox(width: 8),
                          Expanded(child: Text(n.title)),
                        ],
                      ),
                      content: Text(n.body),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.1),
                  child: Icon(icon, color: iconColor),
                ),
                title: Text(
                  n.title,
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isUnread ? AppColors.textPrimary.withOpacity(0.8) : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.createdAt != null ? DateFormat('MMM d, yyyy • h:mm a').format(n.createdAt!) : 'Just now',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                trailing: isUnread
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
