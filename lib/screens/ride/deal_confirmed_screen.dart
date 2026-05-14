import 'package:flutter/material.dart';
import 'dart:async';
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

class DealConfirmedScreen extends StatefulWidget {
  const DealConfirmedScreen({super.key});

  @override
  State<DealConfirmedScreen> createState() => _DealConfirmedScreenState();
}

class _DealConfirmedScreenState extends State<DealConfirmedScreen> with TickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late Animation<double> _checkScale;
  
  late AnimationController _revealCtrl;
  String _phone = "••• •••• ••••";
  final String _actualPhone = "+92 312 4567890";
  
  late AnimationController _dotsCtrl;

  @override
  void initState() {
    super.initState();
    
    // Checkmark animation
    _checkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _checkScale = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
    _checkCtrl.forward();
    
    // Reveal phone number after 1.5s delay
    _revealCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _revealPhone();
      }
    });

    // Floating dots
    _dotsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
  }

  void _revealPhone() async {
    for (int i = 0; i <= _actualPhone.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() {
        _phone = _actualPhone.substring(0, i) + "•" * (_actualPhone.length - i);
      });
    }
    setState(() {
      _phone = _actualPhone;
    });
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _revealCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.dark,
      body: Stack(
        children: [
          // Floating dots in background
          ...List.generate(6, (index) => _FloatingDot(controller: _dotsCtrl, index: index)),
          
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                
                // Center content
                ScaleTransition(
                  scale: _checkScale,
                  child: Container(
                    width: 100, height: 100,
                    decoration: const BoxDecoration(color: _C.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: _C.white, size: 54),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Deal Done!', style: TextStyle(color: _C.white, fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('You agreed on', style: TextStyle(color: _C.white.withOpacity(0.6), fontSize: 16)),
                const SizedBox(height: 12),
                const Text('Rs 130', style: TextStyle(color: _C.primary, fontSize: 56, fontWeight: FontWeight.w900)),
                
                const Spacer(),
                
                // White Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: const BoxDecoration(
                    color: _C.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your Captain', style: TextStyle(color: _C.textDark, fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          CircleAvatar(radius: 24, backgroundColor: _C.primary.withOpacity(0.1), child: const Text('MS', style: TextStyle(color: _C.primary, fontWeight: FontWeight.w800))),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('M. Salman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _C.textDark)),
                                Row(
                                  children: [
                                    Icon(Icons.star, color: _C.primary, size: 14),
                                    Icon(Icons.star, color: _C.primary, size: 14),
                                    Icon(Icons.star, color: _C.primary, size: 14),
                                    Icon(Icons.star, color: _C.primary, size: 14),
                                    Icon(Icons.star_half, color: _C.primary, size: 14),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: _C.primary.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.phone, color: _C.primary, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFCCBFA3)),
                      const SizedBox(height: 24),
                      const Text('Contact Revealed', style: TextStyle(color: _C.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(_phone, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _C.black, letterSpacing: 1.2)),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.primary,
                            foregroundColor: _C.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('Call Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pushReplacementNamed(context, '/active-ride'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _C.primary.withOpacity(0.1),
                                  foregroundColor: _C.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: const Text('Track Ride', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: _C.primary, width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('Share', style: TextStyle(color: _C.primary, fontWeight: FontWeight.w800)),
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
        ],
      ),
    );
  }
}

class _FloatingDot extends StatelessWidget {
  final AnimationController controller;
  final int index;
  const _FloatingDot({required this.controller, required this.index});

  @override
  Widget build(BuildContext context) {
    final double left = (index + 1) * 60.0;
    final double startTop = 600.0 + (index * 40);
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double progress = (controller.value + (index * 0.15)) % 1.0;
        return Positioned(
          left: left,
          top: startTop - (progress * 400),
          child: Opacity(
            opacity: (1.0 - progress) * 0.4,
            child: Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: _C.primary, shape: BoxShape.circle),
            ),
          ),
        );
      },
    );
  }
}



