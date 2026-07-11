import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class _ShimmerBox extends StatefulWidget {
  final Widget child;

  const _ShimmerBox({required this.child});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

Widget _bone({double? width, double height = 14, double radius = 8}) {
  return _ShimmerBox(
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}

class RideCardSkeleton extends StatelessWidget {
  const RideCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ivory),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _bone(width: 44, height: 44, radius: 22),
              const SizedBox(width: 12),
              Expanded(child: _bone(height: 16)),
            ],
          ),
          const SizedBox(height: 14),
          _bone(height: 12),
          const SizedBox(height: 8),
          _bone(width: 180, height: 12),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _bone(height: 36, radius: 12)),
              const SizedBox(width: 10),
              _bone(width: 90, height: 36, radius: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class BookingCardSkeleton extends StatelessWidget {
  const BookingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const RideCardSkeleton();
  }
}

class RequestCardSkeleton extends StatelessWidget {
  const RequestCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ivory),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bone(width: 140, height: 16),
          const SizedBox(height: 10),
          _bone(height: 12),
          const SizedBox(height: 6),
          _bone(width: 200, height: 12),
          const SizedBox(height: 12),
          _bone(height: 32, radius: 12),
        ],
      ),
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _bone(width: 88, height: 88, radius: 44),
          const SizedBox(height: 16),
          _bone(width: 160, height: 18),
          const SizedBox(height: 8),
          _bone(width: 220, height: 14),
        ],
      ),
    );
  }
}

class WalletSkeleton extends StatelessWidget {
  const WalletSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bone(height: 100, radius: 16),
          const SizedBox(height: 20),
          _bone(height: 14),
          const SizedBox(height: 10),
          _bone(height: 14),
          const SizedBox(height: 10),
          _bone(height: 14),
        ],
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final Widget item;
  final int count;

  const SkeletonList({
    super.key,
    required this.item,
    this.count = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (_, __) => item,
    );
  }
}
