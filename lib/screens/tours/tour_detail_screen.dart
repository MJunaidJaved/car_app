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

class TourDetailScreen extends StatelessWidget {
  const TourDetailScreen({super.key});

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
                      const Text('Tour Details', style: TextStyle(color: _C.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _C.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: const Center(child: Icon(Icons.landscape_rounded, size: 80, color: _C.primary)),
                        ),
                        const SizedBox(height: 24),
                        const Text('Adventure to Skardu', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _C.textDark)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: _C.primary, size: 22),
                            const SizedBox(width: 6),
                            const Text('4.9 (120 reviews)', style: TextStyle(color: _C.textMuted, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: _C.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                              child: const Text('Top Rated', style: TextStyle(color: _C.primary, fontWeight: FontWeight.w800, fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _C.textDark)),
                        const SizedBox(height: 12),
                        const Text(
                          'Experience the breathtaking beauty of Skardu. This 5-day tour includes visits to Shangrila Resort, Upper Kachura Lake, and the Cold Desert. Professional guide and luxury transport included.',
                          style: TextStyle(color: _C.textMuted, height: 1.6, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 32),
                        const Text('Itinerary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _C.textDark)),
                        const SizedBox(height: 16),
                        _buildItineraryStep('Day 1', 'Arrival in Skardu & Hotel Check-in'),
                        _buildItineraryStep('Day 2', 'Visit to Shangrila Resort & Lower Kachura'),
                        _buildItineraryStep('Day 3', 'Exploration of Upper Kachura Lake'),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
              decoration: BoxDecoration(
                color: _C.white,
                border: const Border(top: BorderSide(color: Color(0xFFCCBFA3), width: 1)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, -10))],
              ),
              child: Row(
                children: [
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Price', style: TextStyle(color: _C.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('Rs 45,000', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _C.primary)),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/tour-booked'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.primary,
                          foregroundColor: _C.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryStep(String day, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _C.primary, borderRadius: BorderRadius.circular(10)),
            child: Text(day, style: const TextStyle(color: _C.white, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(color: _C.textDark, fontWeight: FontWeight.w600, fontSize: 15))),
        ],
      ),
    );
  }
}



