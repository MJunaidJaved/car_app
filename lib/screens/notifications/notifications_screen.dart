import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.get('/notifications');
      setState(() {
        _notifications = List<Map<String, dynamic>>.from(res['notifications'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.patch('/notifications/read-all', {});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 160,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.bark, AppColors.moss],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('Notifications', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      TextButton(
                        onPressed: _markAllRead,
                        child: Text('Mark all read', style: TextStyle(color: AppColors.white.withOpacity(0.8), fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _notifications.isEmpty
                          ? const Center(child: Text('No notifications yet.', style: TextStyle(color: AppColors.sage)))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: _notifications.length,
                              itemBuilder: (context, i) {
                                final n = _notifications[i];
                                final isNew = n['read'] != true;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _NotificationTile(
                                    title: n['title'] ?? 'Notification',
                                    sub: n['body'] ?? '',
                                    time: _formatTime(n['createdAt']),
                                    isNew: isNew,
                                    onTap: () {
                                      final type = n['type']?.toString() ?? '';
                                      final data = n['data'] as Map<String, dynamic>? ?? {};
                                      if (type == 'new_deal') {
                                        final rideId = data['rideId']?.toString();
                                        if (rideId != null && rideId.isNotEmpty) {
                                          Navigator.pushNamed(context, '/requests', arguments: rideId);
                                        }
                                      } else if (type == 'deal_confirmed' ||
                                          type == 'deal_cancelled' ||
                                          type == 'deal_counter' ||
                                          type == 'ride_started') {
                                        Navigator.pushNamed(context, '/my-bookings');
                                      } else if (type == 'ride_completed') {
                                        final dealId = data['dealId']?.toString();
                                        if (dealId != null) {
                                          Navigator.pushNamed(context, '/rate-review', arguments: dealId);
                                        }
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt.toString());
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String sub;
  final String time;
  final bool isNew;
  final VoidCallback? onTap;

  const _NotificationTile({
    required this.title,
    required this.sub,
    required this.time,
    this.isNew = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isNew ? AppColors.moss.withOpacity(0.3) : AppColors.light),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.moss.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_rounded, color: AppColors.moss, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.bark)),
                  const SizedBox(height: 4),
                  Text(sub, style: const TextStyle(color: AppColors.sage, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(time, style: const TextStyle(color: AppColors.sage, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
