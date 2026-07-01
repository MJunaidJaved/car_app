import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String _period = 'week';
  List<Map<String, dynamic>> _transactions = [];
  bool _loadingTx = true;
  List<double> _weekData = [0, 0, 0, 0, 0, 0, 0];
  final _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  double _totalEarnings = 0;
  int _ridesDone = 0;
  double _commission = 0;
  double _netEarned = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final summaryRes = await ApiService.get('/wallet/earnings-summary');
      final txRes = await ApiService.get('/wallet/transactions');
      final summary = summaryRes['summary'] as Map<String, dynamic>? ?? {};
      setState(() {
        _weekData =
            List<double>.from(summary['weekData'] ?? [0, 0, 0, 0, 0, 0, 0]);
        _totalEarnings = (summary['totalEarnings'] ?? 0).toDouble();
        _ridesDone = summary['ridesCompleted'] ?? 0;
        _commission = (summary['totalCommission'] ?? 0).toDouble();
        _netEarned = (summary['netEarned'] ?? 0).toDouble();
        _transactions =
            List<Map<String, dynamic>>.from(txRes['transactions'] ?? []);
        _loadingTx = false;
      });
    } catch (e) {
      setState(() => _loadingTx = false);
    }
  }

  double get _maxVal {
    if (_weekData.isEmpty) return 1;
    return _weekData.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.dark, AppColors.primary],
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha:0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Earnings',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
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
                        color: AppColors.white.withValues(alpha:0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha:0.2),
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
                                    color: AppColors.white.withValues(alpha:0.75),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Rs ${_totalEarnings.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 36,
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
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.trending_up_rounded,
                                    color: AppColors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  '+12%',
                                  style: TextStyle(
                                    color: AppColors.white,
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
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.light, width: 1),
                        boxShadow: AppColors.cardShadow,
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
                                    color:
                                        sel ? AppColors.primary : AppColors.bg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: sel
                                            ? AppColors.primary
                                            : AppColors.light,
                                        width: 1),
                                  ),
                                  child: Text(
                                    p[0].toUpperCase() + p.substring(1),
                                    style: TextStyle(
                                      color: sel
                                          ? AppColors.white
                                          : AppColors.textMuted,
                                      fontSize: 13,
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
                                              color: AppColors.textMuted,
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
                                                    ? [
                                                        AppColors.primary,
                                                        AppColors.dark
                                                      ]
                                                    : [
                                                        AppColors.light,
                                                        AppColors.light
                                                            .withValues(alpha:0.5)
                                                      ],
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
                                              color: i == 5
                                                  ? AppColors.primary
                                                  : AppColors.textMuted,
                                              fontSize: 10,
                                              fontWeight: i == 5
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
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
                        Expanded(
                          child: _EarnStatCard(
                            label: 'Rides Done',
                            value: '$_ridesDone',
                            icon: Icons.directions_car_filled_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EarnStatCard(
                            label: 'Commission',
                            value: 'Rs ${_commission.toStringAsFixed(0)}',
                            icon: Icons.percent_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EarnStatCard(
                            label: 'Net Earned',
                            value: 'Rs ${_netEarned.toStringAsFixed(0)}',
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Recent Transactions
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Recent Transactions',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _loadingTx
                      ? const Center(child: CircularProgressIndicator())
                      : _transactions.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text('No transactions yet.',
                                  style: TextStyle(color: AppColors.textMuted)),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _transactions.length,
                              itemBuilder: (context, i) {
                                final tx = _transactions[i];
                                final amount = (tx['amount'] ?? 0).toDouble();
                                final isDebit =
                                    tx['type'] == 'commission_deduction';
                                final date = (tx['createdAt'] ?? '').toString();
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: AppColors.light, width: 0.5),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha:0.1),
                                            shape: BoxShape.circle),
                                        child: Icon(
                                            isDebit
                                                ? Icons.remove_circle_outline
                                                : Icons.add_circle_outline,
                                            color: AppColors.primary,
                                            size: 18),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                tx['description'] ??
                                                    tx['type'] ??
                                                    'Transaction',
                                                style: const TextStyle(
                                                    color: AppColors.textDark,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14)),
                                            Text(
                                                date.length > 10
                                                    ? date.substring(0, 10)
                                                    : date,
                                                style: const TextStyle(
                                                    color: AppColors.textMuted,
                                                    fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      Text(
                                          '${isDebit ? '-' : '+'}Rs ${amount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                              color: isDebit
                                                  ? AppColors.error
                                                  : AppColors.success,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14)),
                                    ],
                                  ),
                                );
                              },
                            ),

                  const SizedBox(height: 100),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line, width: 1),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

