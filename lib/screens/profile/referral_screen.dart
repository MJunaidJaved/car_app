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

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

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
                      const Text('Refer & Earn', style: TextStyle(color: _C.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // Hero Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: _C.dark,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _C.primary.withOpacity(0.2), width: 1),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(color: _C.primary.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.card_giftcard_rounded, size: 64, color: _C.primary),
                              ),
                              const SizedBox(height: 24),
                              const Text('Invite Your Friends!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _C.white)),
                              const SizedBox(height: 12),
                              Text(
                                'Share your referral code and get Rs 50 credit for every friend who joins!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _C.white.withOpacity(0.6), fontSize: 14, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Your Referral Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _C.textDark)),
                        ),
                        const SizedBox(height: 12),
                        
                        // Code Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          decoration: BoxDecoration(
                            color: _C.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('CARPOOL2024', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _C.primary, letterSpacing: 2)),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied to clipboard!')));
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: _C.primary, borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.copy_rounded, color: _C.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 60),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _C.primary,
                              foregroundColor: _C.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text('Share Referral Link', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
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



