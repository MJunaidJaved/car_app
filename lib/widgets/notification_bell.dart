import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';

class NotificationBell extends StatefulWidget {
  final Color iconColor;
  final Color backgroundColor;
  final Color? borderColor;
  final IconData icon;

  const NotificationBell({
    super.key,
    required this.iconColor,
    required this.backgroundColor,
    this.borderColor,
    this.icon = Icons.notifications_none_rounded,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  Timer? _timer;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _loadUnreadCount(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount({bool silent = false}) async {
    try {
      final res = await ApiService.get('/notifications');
      final items = List<Map<String, dynamic>>.from(
        res['notifications'] ?? [],
      );
      final count = items.where((n) => n['read'] != true).length;
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {
      if (!silent && mounted) setState(() => _unreadCount = 0);
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.pushNamed(context, '/notifications');
    if (mounted) await _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final label = _unreadCount > 9 ? '9+' : _unreadCount.toString();
    return GestureDetector(
      onTap: _openNotifications,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(13),
              border: widget.borderColor == null
                  ? null
                  : Border.all(color: widget.borderColor!),
            ),
            child: Icon(widget.icon, color: widget.iconColor, size: 22),
          ),
          if (_unreadCount > 0)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
