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
          // Map placeholder
          Positioned.fill(
            child: Container(
              color: const Color(0xFFCCBFA3),
              child: Center(
                child: Icon(
                  Icons.map_outlined,
                  color: _C.accent.withOpacity(0.3),
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
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color:        _C.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color:      Colors.black.withOpacity(0.02),
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
                            color: Color(0xFF4A7C59),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Ride in Progress',
                          style: TextStyle(
                            color:      _C.textDark,
                            fontSize:   12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // SOS Button
                  GestureDetector(
                    onTap: _triggerSOS,
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color:        _C.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:      _C.primary.withOpacity(0.3),
                            blurRadius: 15,
                            offset:     const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'SOS',
                          style: TextStyle(
                            color:      _C.white,
                            fontSize:   14,
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius: const BorderRadius.only(
                  topLeft:  Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                border: const Border(top: BorderSide(color: Color(0xFFCCBFA3), width: 1)),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withOpacity(0.02),
                    blurRadius: 30,
                    offset:     const Offset(0, -10),
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
                        radius: 26,
                        backgroundColor: _C.primary.withOpacity(0.1),
                        child: const Text(
                          'A',
                          style: TextStyle(
                            color:      _C.primary,
                            fontWeight: FontWeight.w800,
                            fontSize:   20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ali Hassan',
                              style: TextStyle(
                                color:      _C.textDark,
                                fontSize:   18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.star_rounded,
                                    color: _C.primary, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  '4.9  •  Toyota Corolla  •  ABC-123',
                                  style: TextStyle(
                                    color: _C.textMuted, fontSize: 12, fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Call button
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color:        _C.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.phone_rounded,
                          color: _C.primary, size: 22,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 1, color: Color(0xFFCCBFA3)),
                  const SizedBox(height: 24),

                  // Route progress
                  Row(
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.circle, color: Color(0xFF4A7C59), size: 10),
                          Container(
                              width: 1.5, height: 36, color: const Color(0xFFCCBFA3)),
                          const Icon(Icons.circle, color: _C.primary, size: 10),
                        ],
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gulberg, Lahore',
                              style: TextStyle(
                                color: _C.textDark, fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'DHA Phase 5',
                              style: TextStyle(
                                color: _C.textDark, fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color:        _C.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '12 min away',
                          style: TextStyle(
                            color:      _C.primary,
                            fontSize:   12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Fare chip
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _InfoChip(
                        icon:  Icons.payments_rounded,
                        label: 'Rs 120  •  Agreed fare',
                      ),
                      _InfoChip(
                        icon:  Icons.shield_rounded,
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
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color:        _C.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color:        _C.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: _C.primary, size: 40,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Send SOS Alert?',
                          style: TextStyle(
                            color:      _C.textDark,
                            fontSize:   22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'This will alert emergency contacts\nand share your live location.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _C.textMuted, fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => _showSosConfirm = false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _C.textDark,
                                  side: const BorderSide(color: Color(0xFFCCBFA3)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                ),
                                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() => _showSosConfirm = false);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _C.primary,
                                  foregroundColor: _C.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                ),
                                child: const Text(
                                  'Send SOS',
                                  style: TextStyle(fontWeight: FontWeight.w900),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:        _C.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _C.primary, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: _C.primary, fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}


