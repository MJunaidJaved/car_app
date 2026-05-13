import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _C {
  static const primary   = Color(0xFF39988E);
  static const dark      = Color(0xFF1F6059);
  static const light     = Color(0xFFB6D7D1);
  static const bg        = Color(0xFFF5F5F5);
  static const white     = Color(0xFFFFFFFF);
  static const textDark  = Color(0xFF0D1F1E);
  static const textMuted = Color(0xFF7A9E9B);
}

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String _period = 'week';

  // Sample data — wire to real data
  final _weekData = [340.0, 520.0, 180.0, 620.0, 450.0, 730.0, 290.0];
  final _days     = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  double get _maxVal =>
      _weekData.reduce((a, b) => a > b ? a : b);
  double get _totalEarnings =>
      _weekData.reduce((a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.dark, _C.primary],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: _C.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: _C.white, size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Earnings',
                          style: TextStyle(
                            color: _C.white, fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Total earning card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:        _C.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _C.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'This Week',
                                  style: TextStyle(
                                    color:    _C.white.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rs ${_totalEarnings.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color:      _C.white,
                                    fontSize:   30,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color:        _C.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.trending_up_rounded,
                                    color: Color(0xFF4CAF50), size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '+12% vs last week',
                                  style: TextStyle(
                                    color:    _C.white.withOpacity(0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Chart card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:        _C.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color:      _C.dark.withOpacity(0.08),
                            blurRadius: 16,
                            offset:     const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Period selector
                          Row(
                            children: ['week', 'month'].map((p) {
                              final sel = _period == p;
                              return GestureDetector(
                                onTap: () => setState(() => _period = p),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color:        sel ? _C.primary : _C.bg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    p[0].toUpperCase() + p.substring(1),
                                    style: TextStyle(
                                      color:      sel ? _C.white : _C.textMuted,
                                      fontSize:   13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 20),

                          // Bar chart
                          SizedBox(
                            height: 140,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(
                                _weekData.length,
                                (i) {
                                  final ratio = _weekData[i] / _maxVal;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          // Value label
                                          Text(
                                            '${(_weekData[i] / 1000).toStringAsFixed(1)}k',
                                            style: const TextStyle(
                                              color:    _C.textMuted,
                                              fontSize: 9,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // Bar
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 600),
                                            curve: Curves.easeOutCubic,
                                            height: 100 * ratio,
                                            decoration: BoxDecoration(
                                              color:        i == 5
                                                  ? _C.primary
                                                  : _C.light.withOpacity(0.5),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _days[i],
                                            style: const TextStyle(
                                              color:    _C.textMuted,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _EarnStatCard(
                            label: 'Rides Done',
                            value: '18',
                            icon:  Icons.directions_car_filled_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EarnStatCard(
                            label: 'Commission',
                            value: 'Rs 313',
                            icon:  Icons.percent_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EarnStatCard(
                            label: 'Net Earned',
                            value: 'Rs 2,817',
                            icon:  Icons.account_balance_wallet_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarnStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _EarnStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        _C.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      _C.dark.withOpacity(0.07),
            blurRadius: 10,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _C.primary, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color:      _C.textDark,
              fontSize:   13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: _C.textMuted, fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}