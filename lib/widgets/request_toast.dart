import 'dart:async';

import 'package:flutter/material.dart';

import '../navigation/app_navigator.dart';
import '../utils/app_colors.dart';

class RequestToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show({
    required String passengerName,
    required String route,
    required String fareLabel,
    required VoidCallback onView,
    String actionLabel = 'View Request',
    String? subtitle,
  }) {
    dismiss();
    final overlay = appNavigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (context) => _RequestToastWidget(
        passengerName: passengerName,
        route: route,
        fareLabel: fareLabel,
        actionLabel: actionLabel,
        subtitle: subtitle,
        onView: () {
          dismiss();
          onView();
        },
        onClose: dismiss,
        onTap: () {
          dismiss();
          onView();
        },
      ),
    );
    overlay.insert(_entry!);
    _timer = Timer(const Duration(seconds: 4), dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _RequestToastWidget extends StatefulWidget {
  final String passengerName;
  final String route;
  final String fareLabel;
  final String actionLabel;
  final String? subtitle;
  final VoidCallback onView;
  final VoidCallback onClose;
  final VoidCallback onTap;

  const _RequestToastWidget({
    required this.passengerName,
    required this.route,
    required this.fareLabel,
    required this.actionLabel,
    this.subtitle,
    required this.onView,
    required this.onClose,
    required this.onTap,
  });

  @override
  State<_RequestToastWidget> createState() => _RequestToastWidgetState();
}

class _RequestToastWidgetState extends State<_RequestToastWidget>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 8;
    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                color: AppColors.deepNavy.withValues(alpha:0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepNavy.withValues(alpha:0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.passengerName,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.route,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha:0.9),
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                            if (widget.subtitle != null &&
                                widget.subtitle!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle!,
                                style: TextStyle(
                                  color: AppColors.white.withValues(alpha:0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.fareLabel,
                                style: const TextStyle(
                                  color: AppColors.midnightBlue,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: widget.onView,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.white,
                                backgroundColor: AppColors.midnightBlue,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(widget.actionLabel),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close, color: AppColors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _progressCtrl,
                    builder: (_, __) => LinearProgressIndicator(
                      value: 1 - _progressCtrl.value,
                      backgroundColor: AppColors.white.withValues(alpha:0.2),
                      color: AppColors.ivory,
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

