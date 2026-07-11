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

class _NotificationBellState extends State<NotificationBell>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _unreadCount = 0;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -0.06), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -0.06, end: 0.06), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 0.06, end: -0.04), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -0.04, end: 0.04), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 0.04, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeCtrl,
      // ✅ Root cause of the crashes: Curves.elasticOut overshoots past
      // 1.0 (and can dip below 0.0) while it "springs" — that's what
      // gives elastic curves their bounce. TweenSequence.transform()
      // asserts its input t stays within [0.0, 1.0], so the moment this
      // animation played, it threw
      // "package:flutter/src/animation/tween_sequence.dart: Failed
      // assertion" — which is exactly the error now visible on screen.
      // The bell already gets its "shake" from the oscillating
      // begin/end values above, so it doesn't need an overshooting
      // curve on top. easeOutBack/bounceOut/elasticIn would all have
      // the same problem — any curve here must stay within [0, 1].
      curve: Curves.easeInOut,
    ));

    _loadUnreadCount();
    _timer = Timer.periodic(
      const Duration(seconds: 20),
          (_) => _loadUnreadCount(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount({bool silent = false}) async {
    try {
      final res = await ApiService.get('/notifications');
      final items = List<Map<String, dynamic>>.from(
        res['notifications'] ?? [],
      );
      final count = items.where((n) => n['read'] != true).length;
      if (mounted) {
        final oldCount = _unreadCount;
        setState(() => _unreadCount = count);
        if (count > oldCount && count > 0) {
          _shakeCtrl.forward(from: 0.0);
        }
      }
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
              borderRadius: BorderRadius.circular(12),
              border: widget.borderColor == null
                  ? null
                  : Border.all(color: widget.borderColor!),
            ),
            child: RotationTransition(
              turns: _shakeAnim,
              child: Icon(widget.icon, color: widget.iconColor, size: 22),
            ),
          ),
          Positioned(
            top: -5,
            right: -5,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: _unreadCount == 0
                  ? const SizedBox.shrink()
                  : Container(
                key: ValueKey<int>(_unreadCount),
                constraints:
                const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha:0.35),
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
          ),
        ],
      ),
    );
  }
}

