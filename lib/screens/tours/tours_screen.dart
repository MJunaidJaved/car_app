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

class ToursScreen extends StatelessWidget {
  const ToursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Gradient Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.dark, Color(0xFF414833)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tours', style: TextStyle(color: _C.white, fontSize: 24, fontWeight: FontWeight.w900)),
                          Text('Replace your WhatsApp group trips', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text('Popular Routes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _C.white)),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 140,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            children: [
                              _PopularRouteCard(city: 'Murree', route: 'Lahore → Murree', captains: 8),
                              _PopularRouteCard(city: 'Lahore', route: 'ISB → Lahore', captains: 12),
                              _PopularRouteCard(city: 'Hyderabad', route: 'KHI → HYD', captains: 5),
                              _PopularRouteCard(city: 'Islamabad', route: 'Lahore → ISB', captains: 15),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text('Upcoming Tours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _C.textDark)),
                        ),
                        const SizedBox(height: 16),
                        
                        ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return const _UpcomingTourCard();
                          },
                        ),
                        const SizedBox(height: 32),
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

class _PopularRouteCard extends StatelessWidget {
  final String city;
  final String route;
  final int captains;
  const _PopularRouteCard({required this.city, required this.route, required this.captains});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_C.primary, Color(0xFF414833)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(city, style: const TextStyle(color: _C.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(route, style: TextStyle(color: _C.white.withOpacity(0.8), fontSize: 12)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _C.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Text('$captains captains', style: const TextStyle(color: _C.white, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _UpcomingTourCard extends StatelessWidget {
  const _UpcomingTourCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 160,
            decoration: const BoxDecoration(
              color: _C.primary,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 18, backgroundColor: _C.primary.withOpacity(0.1), child: const Text('AH', style: TextStyle(color: _C.primary, fontSize: 12, fontWeight: FontWeight.w800))),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Ahmed Hassan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _C.textDark))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF4A7C59).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, color: Color(0xFF4A7C59), size: 12),
                            SizedBox(width: 4),
                            Text('Verified', style: TextStyle(color: Color(0xFF4A7C59), fontSize: 10, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Column(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4A7C59), shape: BoxShape.circle)),
                          Container(width: 1, height: 20, color: const Color(0xFFCCBFA3)),
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: _C.primary, shape: BoxShape.circle)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lahore', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.textDark)),
                          SizedBox(height: 14),
                          Text('Naran Valley', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.textDark)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const _Chip(icon: Icons.calendar_today, label: 'Oct 24'),
                      const SizedBox(width: 8),
                      const _Chip(icon: Icons.access_time, label: '06:00 AM'),
                      const Spacer(),
                      const Text('Rs 4,500', style: TextStyle(color: _C.primary, fontWeight: FontWeight.w900, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/tour-detail'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        foregroundColor: _C.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Book Seat', style: TextStyle(fontWeight: FontWeight.w800)),
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
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFCCBFA3).withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _C.textMuted),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: _C.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}



