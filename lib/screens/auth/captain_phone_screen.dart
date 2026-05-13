import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../services/app_mode_service.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import 'role_select_screen.dart';

class CaptainPhoneScreen extends StatefulWidget {
  const CaptainPhoneScreen({super.key});

  @override
  State<CaptainPhoneScreen> createState() => _CaptainPhoneScreenState();
}

class _CaptainPhoneScreenState extends State<CaptainPhoneScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String? _verificationId;
  bool _busy = false;
  bool _otpStep = false;
  String? _status;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _afterPhoneSignedIn() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final exists = await auth.captainProfileExists();
    if (!mounted) return;

    if (exists) {
      final data = await auth.getUserData(auth.currentUser!.uid);
      if (data != null) {
        userProvider.setUser(data);
      }
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } else {
      Navigator.pushReplacementNamed(context, '/captain-register');
    }
  }

  void _sendCode() {
    if (!AppHelpers.isValidPhone(_phoneController.text.trim())) {
      AppHelpers.showSnackBar(
        context,
        'Valid Pakistani mobile enter karein (e.g. 03001234567)',
        isError: true,
      );
      return;
    }

    setState(() {
      _busy = true;
      _status = 'SMS bhej rahe hain…';
    });

    final e164 = AppHelpers.phoneToE164Pk(_phoneController.text.trim());
    final auth = Provider.of<AuthService>(context, listen: false);

    auth.startCaptainPhoneVerification(
      e164Phone: e164,
      onCodeSent: (id) {
        if (!mounted) return;
        setState(() {
          _verificationId = id;
          _otpStep = true;
          _busy = false;
          _status = 'OTP apke number par aaye ga.';
        });
        AppHelpers.showSnackBar(context, 'OTP bhej diya gaya.');
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _status = null;
        });
        AppHelpers.showSnackBar(context, '$e', isError: true);
      },
      onAutoVerified: (cred) async {
        final auth = Provider.of<AuthService>(context, listen: false);
        await auth.signInWithPhoneCredential(cred);
        if (!mounted) return;
        setState(() => _busy = false);
        await _afterPhoneSignedIn();
      },
    );
  }

  Future<void> _verifyOtp() async {
    final id = _verificationId;
    if (id == null) return;

    setState(() {
      _busy = true;
      _status = 'Verify ho raha hai…';
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      await auth.signInCaptainWithSms(verificationId: id, smsCode: _otpController.text);
      if (!mounted) return;
      await _afterPhoneSignedIn();
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, '$e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Captain — Phone OTP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _busy
              ? null
              : () async {
                  await AppModeService.clearPersona();
                  await Provider.of<AuthService>(context, listen: false).signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const RoleSelectScreen()),
                    (_) => false,
                  );
                },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _otpStep
                    ? 'SMS ka 6-digit code enter karein.'
                    : 'Apna mobile number enter karein (Pakistan).',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              if (!_otpStep) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile',
                    hintText: '03001234567',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'OTP',
                    prefixIcon: Icon(Icons.sms_outlined),
                  ),
                ),
              ],
              if (_status != null) ...[
                const SizedBox(height: 12),
                Text(_status!, style: TextStyle(color: Colors.grey[700])),
              ],
              const Spacer(),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _busy
                      ? null
                      : () {
                          if (!_otpStep) {
                            _sendCode();
                          } else {
                            _verifyOtp();
                          }
                        },
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_otpStep ? 'Verify OTP' : 'Send OTP'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
