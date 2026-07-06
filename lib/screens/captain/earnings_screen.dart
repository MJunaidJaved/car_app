import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../utils/app_colors.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String _period = 'today';
  bool _loading = true;
  Map<String, dynamic> _today = {'ridesCompleted': 0, 'earningsRs': 0};
  Map<String, dynamic> _week = {'ridesCompleted': 0, 'earningsRs': 0};
  Map<String, dynamic> _month = {'ridesCompleted': 0, 'earningsRs': 0};
  Map<String, dynamic> _profile = {
    'averageRating': 0,
    'reviewCount': 0,
    'totalCompletedRides': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/captain/stats');
      if (!mounted) return;
      setState(() {
        _today = Map<String, dynamic>.from(res['today'] ?? _today);
        _week = Map<String, dynamic>.from(res['week'] ?? _week);
        _month = Map<String, dynamic>.from(res['month'] ?? _month);
        _profile = Map<String, dynamic>.from(res['profile'] ?? _profile);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> get _stats => switch (_period) {
        'week' => _week,
        'month' => _month,
        _ => _today,
      };

  String get _periodTitle => switch (_period) {
        'week' => 'Weekly',
        'month' => 'Monthly',
        _ => 'Today',
      };

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final rides = _int(_stats['ridesCompleted']);
    final earnings = _num(_stats['earningsRs']);
    final completed = _int(_profile['totalCompletedRides']);
    final rating = _num(_profile['averageRating']);
    final reviews = _int(_profile['reviewCount']);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.deepRoyalNavy, AppColors.veryLightBlue],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.42],
                ),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          color: AppColors.white,
                          style: IconButton.styleFrom(
                            backgroundColor:
                                AppColors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Performance',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 120,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _periodTitle,
                                  style: TextStyle(
                                    color: AppColors.white.withValues(alpha: 0.78),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Rs ${earnings.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _HeroMetric(
                                      icon: Icons.directions_car_rounded,
                                      label: 'Rides',
                                      value: '$rides',
                                    ),
                                    const SizedBox(width: 10),
                                    _HeroMetric(
                                      icon: Icons.star_rounded,
                                      label: 'Rating',
                                      value: rating.toStringAsFixed(1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: ['today', 'week', 'month'].map((period) {
                        final selected = _period == period;
                        final label = period == 'today'
                            ? 'Today'
                            : period == 'week'
                                ? 'Weekly'
                                : 'Monthly';
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: period == 'month' ? 0 : 8,
                            ),
                            child: GestureDetector(
                              onTap: () => setState(() => _period = period),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.white
                                      : AppColors.white.withValues(alpha: 0.68),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.line,
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.sage,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Completed',
                            value: '$completed',
                            icon: Icons.verified_rounded,
                            color: AppColors.emerald,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'Reviews',
                            value: '$reviews',
                            icon: Icons.rate_review_rounded,
                            color: AppColors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _StatCard(
                      label: 'Selected period earnings',
                      value: 'Rs ${earnings.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                      wide: true,
                    ),
                    const SizedBox(height: 28),
                    const Center(
                      child: Text(
                        'Powered by HiTECH TECHNOLOGIES',
                        style: TextStyle(
                          color: AppColors.sage,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.74),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool wide;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: wide ? 22 : 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.sage,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
