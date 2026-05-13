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

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

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
              height: 260,
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
                  // Header
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
                          'Wallet',
                          style: TextStyle(
                            color: _C.white, fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Balance Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color:        _C.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _C.white.withOpacity(0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Balance',
                            style: TextStyle(
                              color:    _C.white.withOpacity(0.75),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Rs 1,240',
                            style: TextStyle(
                              color:      _C.white,
                              fontSize:   36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _WalletAction(
                                icon:  Icons.add_rounded,
                                label: 'Add Money',
                                onTap: () {},
                              ),
                              const SizedBox(width: 12),
                              _WalletAction(
                                icon:  Icons.send_rounded,
                                label: 'Transfer',
                                onTap: () {},
                              ),
                              const SizedBox(width: 12),
                              _WalletAction(
                                icon:  Icons.history_rounded,
                                label: 'History',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Easypaisa Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:        _C.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color:      _C.dark.withOpacity(0.07),
                            blurRadius: 12,
                            offset:     const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color:        _C.light.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: _C.primary, size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Easypaisa Connected',
                                  style: TextStyle(
                                    color:      _C.textDark,
                                    fontSize:   14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Tap to top up instantly',
                                  style: TextStyle(
                                    color: _C.textMuted, fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _C.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Referral Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _C.primary.withOpacity(0.9),
                            _C.dark,
                          ],
                          begin: Alignment.topLeft,
                          end:   Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Refer & Earn',
                                  style: TextStyle(
                                    color:      _C.white,
                                    fontSize:   16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Share code, get Rs 50 wallet credit',
                                  style: TextStyle(
                                    color:    _C.white.withOpacity(0.75),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color:        _C.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _C.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'POOL2024',
                                        style: TextStyle(
                                          color:      _C.white,
                                          fontSize:   15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(
                                        Icons.copy_rounded,
                                        color: _C.white.withOpacity(0.7),
                                        size:  16,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.card_giftcard_rounded,
                            color: _C.white, size: 48,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Transaction History
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        color:      _C.textDark,
                        fontSize:   17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _TransactionItem(
                    title:    'Ride — Gulberg to DHA',
                    date:     'Today, 8:30 AM',
                    amount:   '-Rs 120',
                    isDebit:  true,
                  ),
                  _TransactionItem(
                    title:    'Referral Bonus',
                    date:     'Yesterday',
                    amount:   '+Rs 50',
                    isDebit:  false,
                  ),
                  _TransactionItem(
                    title:    'Easypaisa Top-up',
                    date:     '11 May',
                    amount:   '+Rs 500',
                    isDebit:  false,
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

class _WalletAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _WalletAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color:        _C.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _C.white, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color:    _C.white.withOpacity(0.85),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String title;
  final String date;
  final String amount;
  final bool isDebit;

  const _TransactionItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.isDebit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        _C.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      _C.dark.withOpacity(0.06),
            blurRadius: 10,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isDebit
                  ? Colors.red.withOpacity(0.1)
                  : _C.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDebit
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: isDebit ? Colors.red : _C.primary,
              size:  20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color:      _C.textDark,
                    fontSize:   14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                      color: _C.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color:      isDebit ? Colors.red : _C.primary,
              fontSize:   15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}