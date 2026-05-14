import 'package:flutter/material.dart';
import '../../widgets/app_widgets.dart';

class TourDetailScreen extends StatelessWidget {
  const TourDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Tour Details', style: TextStyle(color: AppColors.white)),
              background: Container(color: AppColors.light, child: const Icon(Icons.landscape, size: 80, color: AppColors.primary)),
            ),
            iconTheme: const IconThemeData(color: AppColors.white),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Adventure to Skardu', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 20),
                      const SizedBox(width: 5),
                      const Text('4.9 (120 reviews)', style: TextStyle(color: AppColors.textMuted)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Top Rated', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  const Text(
                    'Experience the breathtaking beauty of Skardu. This 5-day tour includes visits to Shangrila Resort, Upper Kachura Lake, and the Cold Desert. Professional guide and luxury transport included.',
                    style: TextStyle(color: AppColors.textMuted, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Text('Itinerary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  _buildItineraryStep('Day 1', 'Arrival in Skardu & Hotel Check-in'),
                  _buildItineraryStep('Day 2', 'Visit to Shangrila Resort & Lower Kachura'),
                  _buildItineraryStep('Day 3', 'Exploration of Upper Kachura Lake'),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Price', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                Text('Rs 45,000', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TealButton(
                label: 'Book Now',
                isLoading: false,
                onTap: () => Navigator.pushNamed(context, '/tour-booked'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItineraryStep(String day, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
            child: Text(day, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
