import 'package:flutter/material.dart';
import '../../widgets/app_widgets.dart';

class _C {
  static const primary   = Color(0xFF414833); // Primary Action
  static const dark      = Color(0xFF414833); // Header/Black
  static const accent    = Color(0xFF737A5D); // Accent
  static const black     = Color(0xFF414833);
  static const white     = Color(0xFFF5E3D2);
  static const textDark  = Color(0xFF414833);
  static const textMuted = Color(0xFF737A5D);
  static const bg        = Color(0xFFF5E3D2);
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Gradient header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 160,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.dark, Color(0xFF414833)],
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
                // Header row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: _C.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('Notifications', style: TextStyle(color: _C.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: 8,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _NotificationTile(index: index);
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
}

class _NotificationTile extends StatelessWidget {
  final int index;
  const _NotificationTile({required this.index});

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    String title;
    String sub;
    IconData icon;

    if (index % 3 == 0) {
      dotColor = const Color(0xFF4A7C59);
      title = "Ride Confirmed";
      sub = "Your ride with M. Salman has been confirmed for 5:00 PM.";
      icon = Icons.check_circle_rounded;
    } else if (index % 3 == 1) {
      dotColor = _C.primary;
      title = "New Request";
      sub = "You have a new ride request from Sarah J. to Gulberg.";
      icon = Icons.hail_rounded;
    } else {
      dotColor = const Color(0xFF414833);
      title = "Ride Declined";
      sub = "Sorry, the captain has declined your request. Try another ride.";
      icon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _C.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: _C.primary, size: 22),
              ),
              Positioned(
                right: 0, top: 0,
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle, border: Border.all(color: _C.white, width: 2)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: _C.black, fontSize: 14)),
                    const Text('2m ago', style: TextStyle(fontSize: 11, color: _C.textMuted, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  sub,
                  style: const TextStyle(color: _C.textMuted, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



