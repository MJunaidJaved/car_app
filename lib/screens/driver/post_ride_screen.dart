import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_widgets.dart';

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

class PostRideScreen extends StatefulWidget {
  const PostRideScreen({super.key});
  @override
  State<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends State<PostRideScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _fromCtrl     = TextEditingController();
  final _toCtrl       = TextEditingController();
  final _fareCtrl     = TextEditingController();
  final _seatsCtrl    = TextEditingController(text: '1');
  String _rideType    = 'office';
  bool   _isLoading   = false;
  bool   _isRecurring = false;
  TimeOfDay _time     = const TimeOfDay(hour: 8, minute: 0);

  final _types = ['office', 'random', 'delivery', 'tour'];

  String get _aiSuggestedFare => 'Rs 120';

  Future<void> _post() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Ride posted (demo)');
        Navigator.pushReplacementNamed(context, '/my-rides');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _fareCtrl.dispose();
    _seatsCtrl.dispose();
    super.dispose();
  }

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
              height: 200,
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
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Post a Ride',
                              style: TextStyle(
                                color: _C.white, fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Fill your empty seats',
                              style: TextStyle(
                                color: Color(0xAAFFFFFF), fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Route Card
                          _SectionCard(
                            title: 'Route',
                            child: Column(
                              children: [
                                AppField(
                                  controller: _fromCtrl,
                                  label:      'From',
                                  icon:       Icons.my_location_rounded,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Enter pickup' : null,
                                ),
                                const SizedBox(height: 12),
                                AppField(
                                  controller: _toCtrl,
                                  label:      'To',
                                  icon:       Icons.location_on_outlined,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Enter destination' : null,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Ride Type Card
                          _SectionCard(
                            title: 'Ride Type',
                            child: Wrap(
                              spacing: 10, runSpacing: 10,
                              children: _types.map((t) {
                                final selected = _rideType == t;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _rideType = t),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color:        selected
                                          ? _C.primary : _C.white,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      border: Border.all(
                                        color: selected
                                            ? _C.primary : const Color(0xFFCCBFA3),
                                      ),
                                    ),
                                    child: Text(
                                      t[0].toUpperCase() + t.substring(1),
                                      style: TextStyle(
                                        color: selected
                                            ? _C.white : _C.textMuted,
                                        fontWeight: FontWeight.w700,
                                        fontSize:   13,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Fare & Seats Card
                          _SectionCard(
                            title: 'Fare & Seats',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // AI fare suggestion
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    color: _C.accent.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome_rounded,
                                        color: _C.black, size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'AI suggests: $_aiSuggestedFare based on distance',
                                          style: const TextStyle(
                                            color:    _C.black,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _fareCtrl.text = '120',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: _C.primary,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Use',
                                            style: TextStyle(
                                              color:    _C.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppField(
                                  controller: _fareCtrl,
                                  label:      'Your fare (Rs)',
                                  icon:       Icons.payments_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Enter fare';
                                    if (double.tryParse(v) == null)
                                      return 'Enter valid amount';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                AppField(
                                  controller: _seatsCtrl,
                                  label:      'Available seats',
                                  icon:       Icons.event_seat_rounded,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Enter seats';
                                    final n = int.tryParse(v);
                                    if (n == null || n < 1 || n > 6)
                                      return '1 to 6 seats';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Departure Time + Recurring Card
                          _SectionCard(
                            title: 'Schedule',
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: _time,
                                      builder: (context, child) =>
                                          Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme:
                                              const ColorScheme.light(
                                            primary: _C.primary,
                                            onPrimary: _C.white,
                                          ),
                                        ),
                                        child: child!,
                                      ),
                                    );
                                    if (picked != null)
                                      setState(() => _time = picked);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: _C.bg,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time_rounded,
                                          color: _C.primary, size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _time.format(context),
                                          style: const TextStyle(
                                            color:      _C.textDark,
                                            fontSize:   15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: _C.textMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Recurring toggle
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _isRecurring
                                        ? _C.primary.withOpacity(0.08)
                                        : _C.bg,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _isRecurring
                                          ? _C.primary : const Color(0xFFCCBFA3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.repeat_rounded,
                                        color: _isRecurring
                                            ? _C.primary : _C.textMuted,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Recurring Ride',
                                              style: TextStyle(
                                                color:      _C.textDark,
                                                fontSize:   14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              'Auto-post daily for commute',
                                              style: TextStyle(
                                                color:    _C.textMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value:          _isRecurring,
                                        onChanged: (v) =>
                                            setState(() => _isRecurring = v),
                                        activeColor: _C.primary,
                                        activeTrackColor: _C.primary.withOpacity(0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _post,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _C.primary,
                                foregroundColor: _C.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: _C.white)
                                  : const Text('Post Ride', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        _C.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset:     const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color:      _C.black,
              fontSize:   16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}


