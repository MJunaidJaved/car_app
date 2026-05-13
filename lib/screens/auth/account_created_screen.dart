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

class AccountCreatedScreen extends StatefulWidget {
  const AccountCreatedScreen({super.key});
  @override
  State<AccountCreatedScreen> createState() => _AccountCreatedScreenState();
}

class _AccountCreatedScreenState extends State<AccountCreatedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double>   _scaleAnim;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800));
    _scaleAnim = CurvedAnimation(
        parent: _animCtrl, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // Animated check icon
                Center(
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color:        _C.primary.withOpacity(0.1),
                        shape:        BoxShape.circle,
                        border: Border.all(
                            color: _C.primary.withOpacity(0.2),
                            width: 2),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: _C.primary,
                        size:  54,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  "You're all set!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:        _C.textDark,
                    fontSize:     28,
                    fontWeight:   FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome to CarPool. Your account is\nactive and ready to use.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:    _C.textMuted,
                    fontSize: 15,
                    height:   1.5,
                  ),
                ),

                const SizedBox(height: 36),

                // Status checklist card
                Container(
                  padding:     const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color:        _C.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color:      _C.dark.withOpacity(0.08),
                        blurRadius: 16,
                        offset:     const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _StatusItem(
                        icon:      Icons.link_rounded,
                        label:     'Google account linked securely',
                        isDone:    true,
                      ),
                      const SizedBox(height: 14),
                      _StatusItem(
                        icon:      Icons.account_balance_wallet_outlined,
                        label:     'Wallet created · Top up to start',
                        isDone:    true,
                      ),
                      const SizedBox(height: 14),
                      _StatusItem(
                        icon:      Icons.description_outlined,
                        label:     'Docs under review (24 hrs)',
                        isDone:    false,
                        isPending: true,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // CTA
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary,
                      foregroundColor: _C.white,
                      elevation:   0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Go to Dashboard',
                      style: TextStyle(
                        fontSize:   16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: Text(
                    "You'll be notified once your Captain account is approved",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:    _C.textMuted,
                      fontSize: 12,
                      height:   1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     isDone;
  final bool     isPending;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.isDone,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: isPending
                ? const Color(0xFFFFF8E1)
                : _C.light.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isPending ? const Color(0xFFFF9800) : _C.primary,
            size:  20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color:      _C.textDark,
              fontSize:   14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Icon(
          isDone
              ? Icons.check_circle_rounded
              : Icons.access_time_rounded,
          color: isDone ? _C.primary : const Color(0xFFFF9800),
          size:  20,
        ),
      ],
    );
  }
}