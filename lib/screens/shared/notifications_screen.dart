import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../state/session_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_outline_rounded;
      case 'declined':
        return Icons.cancel_outlined;
      case 'rescheduled':
        return Icons.event_repeat_rounded;
      case 'urgent':
        return Icons.warning_amber_rounded;
      case 'reminder':
        return Icons.schedule_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type.toLowerCase()) {
      case 'approved':
        return AppColors.primary;
      case 'declined':
      case 'urgent':
        return AppColors.red;
      case 'rescheduled':
        return AppColors.amber;
      default:
        return AppColors.teal;
    }
  }

  Future<void> _showDetailModal(
    BuildContext context,
    Map<String, dynamic> notif,
    String role,
    Future<void> Function() reload,
  ) async {
    final id = toInt(notif['id']);
    final isRead = toInt(notif['is_read']) == 1 || notif['is_read'] == true;
    if (!isRead && id > 0) {
      try {
        await ApiClient.instance.post('notifications.php', query: {'action': 'mark_read'}, body: {'id': id});
        reload();
      } catch (_) {}
    }
    if (!context.mounted) return;
    final type = str(notif['type'], 'info');
    final studentName = str(notif['student_name']);
    final title = role == 'student'
        ? '${titleCase(type)} Session Update'
        : '${titleCase(type)}${studentName.isNotEmpty ? " — $studentName" : ""}';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _colorForType(type).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconForType(type), color: _colorForType(type)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(fmtDateTime(notif['created_at']), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.tint,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(str(notif['message']), style: const TextStyle(fontSize: 14, height: 1.45)),
              ),
              if (notif['appointment_id'] != null) ...[
                const SizedBox(height: 16),
                const Text('Appointment Details', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                const SizedBox(height: 8),
                InfoRow('Reference', '#APT-${notif['appointment_id']}', bold: true),
                if (str(notif['appointment_status']).isNotEmpty)
                  InfoRow('Status', titleCase(str(notif['appointment_status']))),
                if (str(notif['appointment_date']).isNotEmpty)
                  InfoRow('Date', fmtDate(notif['appointment_date'])),
                if (str(notif['start_time']).isNotEmpty)
                  InfoRow('Time', fmtTimeRange(notif['start_time'], notif['end_time'])),
                if (role == 'student' && str(notif['counselor_name']).isNotEmpty)
                  InfoRow('Counselor', str(notif['counselor_name'])),
                if (role != 'student' && studentName.isNotEmpty) ...[
                  InfoRow('Student', studentName),
                  if (str(notif['student_number']).isNotEmpty)
                    InfoRow('Student No.', str(notif['student_number'])),
                  if (str(notif['student_course']).isNotEmpty)
                    InfoRow('Section / Track', str(notif['student_course'])),
                ],
                if (str(notif['concern']).isNotEmpty)
                  InfoRow('Concern', str(notif['concern'])),
                if (str(notif['counselor_notes']).isNotEmpty)
                  InfoRow('Counselor Notes', str(notif['counselor_notes'])),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionState>().role;
    return AsyncView<Map<String, dynamic>>(
      scrollable: true,
      load: () async {
        final r = await ApiClient.instance.get('notifications.php', query: {'action': 'list'});
        return r.map;
      },
      builder: (context, data, reload) {
        final items = (data['notifications'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        final unreadCount = toInt(data['unread_count']);

        return PageList(
          children: [
            HeroCard(
              title: 'Notifications',
              subtitle: role == 'student'
                  ? 'Updates about your guidance appointments'
                  : 'Booking activity and guidance system alerts',
              trailing: unreadCount > 0
                  ? FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                      ),
                      onPressed: () async {
                        final ok = await runAction(
                          context,
                          () => ApiClient.instance.post('notifications.php', query: {'action': 'mark_all_read'}),
                          successMessage: 'All notifications marked as read.',
                        );
                        if (ok) reload();
                      },
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: Text('Mark all ($unreadCount)'),
                    )
                  : null,
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              const EmptyState(
                icon: Icons.notifications_none_rounded,
                message: 'No notifications yet.',
              )
            else
              for (final n in items) ...[
                _buildTile(context, n, role, reload),
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }

  Widget _buildTile(
    BuildContext context,
    Map<String, dynamic> n,
    String role,
    Future<void> Function() reload,
  ) {
    final isRead = toInt(n['is_read']) == 1 || n['is_read'] == true;
    final type = str(n['type'], 'info');
    final color = _colorForType(type);
    final studentName = str(n['student_name']);
    final title = role == 'student'
        ? '${titleCase(type)} Session Update'
        : '${titleCase(type)}${studentName.isNotEmpty ? " — $studentName" : ""}';

    return GsCard(
      color: isRead ? Colors.white : AppColors.primaryLight.withValues(alpha: 0.45),
      onTap: () => _showDetailModal(context, n, role, reload),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconForType(type), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.w700 : FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      fmtDate(n['created_at'], pattern: 'MMM d'),
                      style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  str(n['message']),
                  style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.35),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap to view full details ➜',
                  style: TextStyle(fontSize: 11.5, color: AppColors.primaryMid, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
