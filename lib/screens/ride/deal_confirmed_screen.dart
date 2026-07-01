import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/deal_chat_panel.dart';

class DealConfirmedScreen extends StatefulWidget {
  const DealConfirmedScreen({super.key});

  @override
  State<DealConfirmedScreen> createState() => _DealConfirmedScreenState();
}

class _DealConfirmedScreenState extends State<DealConfirmedScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late Animation<double> _checkScale;
  late AnimationController _dotsCtrl;

  String? _dealId;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _dealSub;
  String _captainName = 'Captain';
  String _phoneDisplay = '*** **** ****';
  String _phoneRaw = '';
  double _fare = 0;
  String _rideId = '';
  String _status = 'pending';
  String _lastCounterBy = '';
  bool _isSendingCounter = false;
  final _counterCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _checkScale = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
    _checkCtrl.forward();
    _dotsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _dealId = args;
      } else if (args is Map) {
        _dealId = args['dealId']?.toString();
        _rideId = args['rideId']?.toString() ?? '';
      }
      await _loadDeal();
      _subscribeDealStream();
    });
  }

  void _subscribeDealStream() {
    if (_dealId == null) return;
    _dealSub?.cancel();
    _dealSub = FirebaseFirestore.instance
        .collection('deals')
        .doc(_dealId)
        .snapshots()
        .listen((_) => _loadDeal());
  }

  Future<void> _loadDeal() async {
    if (_dealId == null) return;
    try {
      final deal = await Provider.of<FirestoreService>(context, listen: false)
          .getDeal(_dealId!);
      if (!mounted) return;
      final phone = (deal['captain']?['phone'] ?? '').toString();
      final canRevealPhone = ['confirmed', 'started', 'completed'].contains(
            (deal['status'] ?? '').toString(),
          ) &&
          phone.trim().isNotEmpty &&
          !phone.contains('*');
      setState(() {
        _captainName = deal['captain']?['name'] ??
            deal['ride']?['captainName'] ??
            'Captain';
        _phoneRaw = canRevealPhone ? phone : '';
        _phoneDisplay = canRevealPhone ? _phoneDisplay : '03**-*****';
        _fare = (deal['agreedFare'] ?? 0).toDouble();
        _rideId =
            deal['rideId']?.toString() ?? deal['ride']?['id']?.toString() ?? '';
        _status = (deal['status'] ?? 'pending').toString();
        _lastCounterBy = (deal['lastCounterBy'] ?? '').toString();
      });
      if (canRevealPhone) _animatePhoneReveal(phone);
    } catch (_) {}
  }

  Future<void> _animatePhoneReveal(String phone) async {
    for (var i = 0; i <= phone.length; i++) {
      await Future.delayed(const Duration(milliseconds: 40));
      if (!mounted) return;
      setState(() {
        _phoneDisplay = phone.substring(0, i) + '*' * (phone.length - i);
      });
    }
    if (mounted) setState(() => _phoneDisplay = phone);
  }

  Future<void> _acceptCaptainCounter() async {
    if (_dealId == null || _isSendingCounter) return;
    setState(() => _isSendingCounter = true);
    try {
      await Provider.of<FirestoreService>(context, listen: false)
          .counterDeal(_dealId!, _fare, message: 'Passenger accepted the fare');
      await _loadDeal();
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Fare accepted. Waiting for captain confirmation.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Accept failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSendingCounter = false);
    }
  }

  Future<void> _sendCounterAgain() async {
    final amount = double.tryParse(_counterCtrl.text.trim()) ?? 0;
    if (_dealId == null || amount <= 0 || _isSendingCounter) {
      AppHelpers.showSnackBar(
        context,
        'Enter a valid counter fare',
        isError: true,
      );
      return;
    }
    setState(() => _isSendingCounter = true);
    try {
      await Provider.of<FirestoreService>(context, listen: false)
          .counterDeal(_dealId!, amount);
      _counterCtrl.clear();
      await _loadDeal();
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Adjusted fare sent');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Counter failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSendingCounter = false);
    }
  }

  Future<void> _cancelBooking() async {
    if (_dealId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text(
          'Are you sure you want to cancel? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await Provider.of<FirestoreService>(context, listen: false)
          .cancelDeal(_dealId!);
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Booking cancelled');
        Navigator.pushReplacementNamed(context, '/my-bookings');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Cancel failed: $e', isError: true);
      }
    }
  }

  Future<void> _callCaptain() async {
    if (_phoneRaw.isEmpty) {
      AppHelpers.showSnackBar(
        context,
        'Captain phone not available yet',
        isError: true,
      );
      return;
    }
    await dialPhone(context, _phoneRaw);
  }

  Future<void> _messageCaptain() async {
    if (_phoneRaw.isEmpty) {
      AppHelpers.showSnackBar(
        context,
        'Captain phone not available yet',
        isError: true,
      );
      return;
    }
    await openWhatsApp(context, _phoneRaw);
  }

  @override
  void dispose() {
    _dealSub?.cancel();
    _counterCtrl.dispose();
    _checkCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final initials =
        _captainName.isNotEmpty ? _captainName[0].toUpperCase() : 'C';

    return Scaffold(
      backgroundColor: AppColors.bark,
      body: Stack(
        children: [
          ...List.generate(
              6, (i) => _FloatingDot(controller: _dotsCtrl, index: i)),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                ScaleTransition(
                  scale: _checkScale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                        color: AppColors.moss, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.cream, size: 54),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Booking sent!',
                    style: TextStyle(
                        color: AppColors.cream,
                        fontSize: 32,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Requested fare',
                    style: TextStyle(
                        color: AppColors.cream.withValues(alpha:0.6), fontSize: 16)),
                const SizedBox(height: 12),
                Text('Rs ${_fare.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppColors.cream,
                        fontSize: 56,
                        fontWeight: FontWeight.w900)),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your Captain',
                          style: TextStyle(
                              color: AppColors.bark,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary.withValues(alpha:0.1),
                            child: Text(initials,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_captainName,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.bark)),
                          ),
                          IconButton(
                            onPressed: _phoneRaw.isEmpty ? null : _callCaptain,
                            icon: const Icon(Icons.phone,
                                color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: AppColors.sage.withValues(alpha:0.2)),
                      const SizedBox(height: 24),
                      const Text('Contact (after captain confirms)',
                          style: TextStyle(
                              color: AppColors.sage,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(_phoneDisplay,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.bark,
                              letterSpacing: 1.2)),
                      if (_status == 'pending' &&
                          _lastCounterBy == 'captain') ...[
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha:0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Captain countered Rs ${_fare.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppColors.bark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _counterCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Adjust fare again',
                                  prefixText: 'Rs ',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isSendingCounter
                                          ? null
                                          : _sendCounterAgain,
                                      child: const Text('Adjust Fare'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isSendingCounter
                                          ? null
                                          : _acceptCaptainCounter,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.moss,
                                        foregroundColor: AppColors.cream,
                                      ),
                                      child: const Text('Accept Fare'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _phoneRaw.isEmpty ? null : _callCaptain,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.moss,
                            foregroundColor: AppColors.cream,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('Call Captain',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _phoneRaw.isEmpty ? null : _messageCaptain,
                          icon: const Icon(Icons.chat_rounded),
                          label: const Text(
                            'WhatsApp Captain',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ),
                      ),
                      if (_dealId != null) ...[
                        const SizedBox(height: 16),
                        DealChatPanel(dealId: _dealId!, height: 140),
                      ],
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _cancelBooking,
                          child: const Text('Cancel booking',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _rideId.isEmpty
                              ? null
                              : () => Navigator.pushReplacementNamed(
                                    context,
                                    '/my-bookings',
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(alpha:0.1),
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('View My Bookings',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingDot extends StatelessWidget {
  final AnimationController controller;
  final int index;
  const _FloatingDot({required this.controller, required this.index});

  @override
  Widget build(BuildContext context) {
    final double left = (index + 1) * 60.0;
    final double startTop = 600.0 + (index * 40);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double progress = (controller.value + (index * 0.15)) % 1.0;
        return Positioned(
          left: left,
          top: startTop - (progress * 400),
          child: Opacity(
            opacity: (1.0 - progress) * 0.4,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
            ),
          ),
        );
      },
    );
  }
}

