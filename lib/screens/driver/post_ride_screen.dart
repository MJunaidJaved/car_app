import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_widgets.dart';

class _C {
  static const primary   = Color(0xFF39988E);
  static const dark      = Color(0xFF1F6059);
  static const light     = Color(0xFFB6D7D1);
  static const bg        = Color(0xFFF5F5F5);
  static const white     = Color(0xFFFFFFFF);
  static const textDark  = Color(0xFF0D1F1E);
  static const textMuted = Color(0xFF7A9E9B);
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

  String get _aiSuggestedFare {
    // Wire to Grok AI service
    return 'Rs 120';
  }

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
                                TealField(
                                  controller: _fromCtrl,
                                  label:      'From',
                                  icon:       Icons.my_location_rounded,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Enter pickup' : null,
                                ),
                                const SizedBox(height: 12),
                                TealField(
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
                              spacing: 8, runSpacing: 8,
                              children: _types.map((t) {
                                final selected = _rideType == t;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _rideType = t),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color:        selected
                                          ? _C.primary : _C.bg,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                        color: selected
                                            ? _C.primary : _C.light,
                                      ),
                                    ),
                                    child: Text(
                                      t[0].toUpperCase() + t.substring(1),
                                      style: TextStyle(
                                        color: selected
                                            ? _C.white : _C.textMuted,
                                        fontWeight: FontWeight.w600,
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
                                    color: _C.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: _C.light, width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome_rounded,
                                        color: _C.primary, size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'AI suggests: $_aiSuggestedFare based on distance',
                                          style: const TextStyle(
                                            color:    _C.primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
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
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TealField(
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
                                TealField(
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
                                      color: const Color(0xFFF0F7F6),
                                      borderRadius:
                                          BorderRadius.circular(14),
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
                                            fontWeight: FontWeight.w600,
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
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isRecurring
                                        ? _C.primary.withOpacity(0.08)
                                        : const Color(0xFFF0F7F6),
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _isRecurring
                                          ? _C.primary : Colors.transparent,
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
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'Auto-post daily for office commute',
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
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          TealButton(
                            label:     'Post Ride',
                            isLoading: _isLoading,
                            onTap:     _post,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        _C.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:      _C.dark.withOpacity(0.07),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color:      _C.textDark,
              fontSize:   15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}