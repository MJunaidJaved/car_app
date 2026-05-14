import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String _period = 'week';

  // Sample data
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
                  colors: [_C.dark, Color(0xFF414833)],
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
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Total earning card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color:        _C.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
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
                                    color:    _C.white.withOpacity(0.75),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Rs ${_totalEarnings.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color:      _C.white,
                                    fontSize:   36,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color:        _C.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.trending_up_rounded,
                                    color: _C.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  '+12%',
                                  style: TextStyle(
                                    color:    _C.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Chart card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:        _C.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color:      Colors.black.withOpacity(0.02),
                            blurRadius: 20,
                            offset:     const Offset(0, 8),
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
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color:        sel ? _C.primary : _C.bg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: sel ? _C.primary : const Color(0xFFCCBFA3), width: 1),
                                  ),
                                  child: Text(
                                    p[0].toUpperCase() + p.substring(1),
                                    style: TextStyle(
                                      color:      sel ? _C.white : _C.textMuted,
                                      fontSize:   13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // Bar chart
                          SizedBox(
                            height: 160,
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
                                          Text(
                                            '${(_weekData[i] / 100).toStringAsFixed(0)}0',
                                            style: const TextStyle(
                                              color:    _C.textMuted,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Bar
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 800),
                                            curve: Curves.elasticOut,
                                            height: 110 * ratio,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: i == 5 
                                                  ? [_C.primary, Color(0xFF414833)]
                                                  : [const Color(0xFFCCBFA3), const Color(0xFFCCBFA3)],
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            _days[i],
                                            style: TextStyle(
                                              color:    i == 5 ? _C.primary : _C.textMuted,
                                              fontSize: 10,
                                              fontWeight: i == 5 ? FontWeight.w800 : FontWeight.w600,
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

                  const SizedBox(height: 24),

                  // Stats row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Expanded(
                          child: _EarnStatCard(
                            label: 'Rides Done',
                            value: '18',
                            icon:  Icons.directions_car_filled_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: _EarnStatCard(
                            label: 'Commission',
                            value: 'Rs 313',
                            icon:  Icons.percent_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        _C.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _C.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _C.primary, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color:      _C.textDark,
              fontSize:   13,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: _C.textMuted, fontSize: 10, fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


