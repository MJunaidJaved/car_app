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

class TourBookedScreen extends StatelessWidget {
  const TourBookedScreen({super.key});

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
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.dark, Color(0xFF414833)],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                
                // Success content
                Container(
                  width: 100, height: 100,
                  decoration: const BoxDecoration(color: _C.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: _C.white, size: 60),
                ),
                const SizedBox(height: 32),
                const Text('Tour Booked!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _C.textDark)),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Your adventure is confirmed. Check your notifications for the itinerary and next steps.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _C.textMuted, fontSize: 16, height: 1.6, fontWeight: FontWeight.w500),
                  ),
                ),
                
                const Spacer(),
                
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        foregroundColor: _C.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Go to Home', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



