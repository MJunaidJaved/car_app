import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _C {
  static const primary   = Color(0xFF414833); // Primary Action
  static const dark      = Color(0xFF414833); // The "black"
  static const accent    = Color(0xFF737A5D); // Secondary Accent
  static const white     = Color(0xFFF5E3D2);
  static const textDark  = Color(0xFF414833);
  static const textMuted = Color(0xFF737A5D);
  static const bg        = Color(0xFFF5E3D2);
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
        duration: const Duration(milliseconds: 1500));
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
      body: Stack(
        children: [
          // Simple Confetti effect
          ...List.generate(25, (index) => _ConfettiPiece(index: index)),
          
          SafeArea(
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
                          width: 110, height: 110,
                          decoration: BoxDecoration(
                            color:        _C.primary.withOpacity(0.15),
                            shape:        BoxShape.circle,
                            border: Border.all(
                                color: _C.primary.withOpacity(0.3),
                                width: 3),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: _C.primary,
                            size:  58,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      "You're all set!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:        _C.textDark,
                        fontSize:     30,
                        fontWeight:   FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Welcome to CarPool. Your account is\nactive and ready to use.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:    _C.textMuted,
                        fontSize: 15,
                        height:   1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Status checklist card
                    Container(
                      padding:     const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color:        _C.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color:      Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset:     const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          _StatusItem(
                            icon:      Icons.link_rounded,
                            label:     'Google account linked securely',
                            isDone:    true,
                          ),
                          SizedBox(height: 18),
                          _StatusItem(
                            icon:      Icons.account_balance_wallet_outlined,
                            label:     'Wallet created · Ready to use',
                            isDone:    true,
                          ),
                          SizedBox(height: 18),
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
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.primary,
                          foregroundColor: _C.white,
                          elevation:   0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Go to Dashboard',
                          style: TextStyle(
                            fontSize:   16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Center(
                      child: Text(
                        "You'll be notified once your Captain account is approved",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:    _C.textMuted,
                          fontSize: 12,
                          height:   1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
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

class _ConfettiPiece extends StatefulWidget {
  final int index;
  const _ConfettiPiece({required this.index});

  @override
  State<_ConfettiPiece> createState() => _ConfettiPieceState();
}

class _ConfettiPieceState extends State<_ConfettiPiece> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late double _left;
  late double _top;
  late Color _color;
  late double _size;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _left = random.nextDouble() * 400;
    _top = -20.0;
    _size = random.nextDouble() * 10 + 5;
    // Using the earthy palette for confetti
    _color = [_C.primary, _C.dark, _C.accent, const Color(0xFFCCBFA3), const Color(0xFF414833)][random.nextInt(5)];
    
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: 2000 + random.nextInt(1000)));
    _ctrl.forward();
    _ctrl.addListener(() {
       if (mounted) setState(() {
         _top += 5;
       });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _left,
      top: _top,
      child: RotationTransition(
        turns: _ctrl,
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(color: _color, shape: widget.index % 2 == 0 ? BoxShape.circle : BoxShape.rectangle),
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
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: isPending
                ? _C.accent.withOpacity(0.12)
                : _C.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: isPending ? _C.accent : _C.primary,
            size:  22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color:      _C.textDark,
              fontSize:   14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Icon(
          isDone
              ? Icons.check_circle_rounded
              : Icons.access_time_rounded,
          color: isDone ? Colors.green : _C.accent,
          size:  22,
        ),
      ],
    );
  }
}


