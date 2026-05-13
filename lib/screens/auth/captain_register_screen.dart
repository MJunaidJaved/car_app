import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';

class CaptainRegisterScreen extends StatefulWidget {
  const CaptainRegisterScreen({super.key});

  @override
  State<CaptainRegisterScreen> createState() => _CaptainRegisterScreenState();
}

class _CaptainRegisterScreenState extends State<CaptainRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cnic = TextEditingController();
  final _vehicleName = TextEditingController();
  final _vehicleNumber = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _cnic.dispose();
    _vehicleName.dispose();
    _vehicleNumber.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await auth.completeCaptainRegistrationFromPhone(
        name: _name.text.trim(),
        cnic: _cnic.text.trim(),
        vehicleName: _vehicleName.text.trim(),
        vehicleNumber: _vehicleNumber.text.trim(),
      );

      final data = await auth.getUserData(auth.currentUser!.uid);
      if (data != null) {
        userProvider.setUser(data);
      }
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'Registration complete!');
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, '$e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Captain registration')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Naya captain account — details complete karein.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name zaroori hai' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cnic,
                  decoration: const InputDecoration(
                    labelText: 'CNIC',
                    prefixIcon: Icon(Icons.badge_outlined),
                    hintText: '12345-1234567-1',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'CNIC zaroori hai' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vehicleName,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle name',
                    prefixIcon: Icon(Icons.directions_car_outlined),
                    hintText: 'Toyota Corolla',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Vehicle name zaroori hai' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vehicleNumber,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle number',
                    prefixIcon: Icon(Icons.pin_outlined),
                    hintText: 'LEA-1234',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Number plate zaroori hai' : null,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Complete registration'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
