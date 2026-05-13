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

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({super.key});
  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  bool _showSosConfirm = false;

  void _triggerSOS() {
    setState(() => _showSosConfirm = true);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Map takes full screen
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE8F4F3),
              child: Center(
                child: Icon(
                  Icons.map_outlined,
                  color: _C.primary.withOpacity(0.2),
                  size:  120,
                ),
              ),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color:        _C.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:      _C.dark.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Ride in Progress',
                          style: TextStyle(
                            color:      _C.textDark,
                            fontSize:   12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // SOS Button — always visible
                  GestureDetector(
                    onTap: _triggerSOS,
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color:        Colors.red,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:      Colors.red.withOpacity(0.4),
                            blurRadius: 12,
                            offset:     const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'SOS',
                          style: TextStyle(
                            color:      _C.white,
                            fontSize:   13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom ride card
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius: const BorderRadius.only(
                  topLeft:  Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color:      _C.dark.withOpacity(0.12),
                    blurRadius: 24,
                    offset:     const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Captain info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: _C.light.withOpacity(0.5),
                        child: const Text(
                          'A',
                          style: TextStyle(
                            color:      _C.primary,
                            fontWeight: FontWeight.w700,
                            fontSize:   18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ali Hassan',
                              style: TextStyle(
                                color:      _C.textDark,
                                fontSize:   16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Color(0xFFFFC107), size: 14),
                                const SizedBox(width: 3),
                                const Text(
                                  '4.9  •  Toyota Corolla  •  ABC-123',
                                  style: TextStyle(
                                    color: _C.textMuted, fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Call button — masked number
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color:        _C.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.phone_outlined,
                          color: _C.primary, size: 20,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF0F0F0), height: 1),
                  const SizedBox(height: 16),

                  // Route progress
                  Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: _C.primary,
                            ),
                          ),
                          Container(
                              width: 2, height: 30, color: _C.light),
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _C.primary, width: 2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gulberg, Lahore',
                              style: TextStyle(
                                color: _C.textDark, fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 18),
                            Text(
                              'DHA Phase 5',
                              style: TextStyle(
                                color: _C.textDark, fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color:        _C.light.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '12 min away',
                              style: TextStyle(
                                color:      _C.primary,
                                fontSize:   12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Fare chip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _InfoChip(
                        icon:  Icons.payments_outlined,
                        label: 'Rs 120  •  Agreed fare',
                      ),
                      _InfoChip(
                        icon:  Icons.shield_outlined,
                        label: 'Masked number',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // SOS Confirmation overlay
          if (_showSosConfirm)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color:        _C.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color:        Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red, size: 36,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Send SOS Alert?',
                          style: TextStyle(
                            color:      _C.textDark,
                            fontSize:   20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This will alert emergency contacts\nand share your live location.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _C.textMuted, fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => _showSosConfirm = false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _C.textMuted,
                                  side: const BorderSide(color: _C.light),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // trigger SOS logic
                                  setState(() => _showSosConfirm = false);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: _C.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                                child: const Text(
                                  'Send SOS',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:        _C.light.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _C.primary, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _C.primary, fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}