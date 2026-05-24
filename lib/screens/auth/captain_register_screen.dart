import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';

// ImgBB API Key
const String IMGBB_API_KEY = 'f3e1d9b185dbeda5209741c804c2c705';

class CaptainRegisterScreen extends StatefulWidget {
  const CaptainRegisterScreen({super.key});

  @override
  State<CaptainRegisterScreen> createState() => _CaptainRegisterScreenState();
}

class _CaptainRegisterScreenState extends State<CaptainRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController(text: '4');
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  static const _cities = [
    'Lahore', 'Karachi', 'Islamabad', 'Rawalpindi',
    'Faisalabad', 'Multan', 'Peshawar', 'Quetta',
  ];

  final ImagePicker _picker = ImagePicker();
  String? _city;
  bool _isLoading = false;

  XFile? _cnicFront;
  XFile? _cnicBack;
  XFile? _vehiclePhoto;

  /// Upload image to ImgBB and return URL
  Future<String?> _uploadImageToImgBB(XFile file, String type) async {
    try {
      debugPrint('Uploading $type to ImgBB...');

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$IMGBB_API_KEY'),
        body: {
          'image': base64Image,
          'name': 'carpool_${type}_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['data']['url'];
        debugPrint('✅ $type uploaded: $imageUrl');
        return imageUrl;
      } else {
        debugPrint('❌ $type upload failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error uploading $type: $e');
      return null;
    }
  }

  Future<void> _pickImage({
    required void Function(XFile) onPicked,
  }) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (file != null && mounted) onPicked(file);
  }

  Future<void> _submit() async {
    debugPrint('DEBUG: Submit button clicked!');

    if (!_formKey.currentState!.validate()) {
      debugPrint('DEBUG: Form validation failed!');
      return;
    }

    if (_city == null) {
      debugPrint('DEBUG: Validation failed - City is null!');
      AppHelpers.showSnackBar(context, 'Select your city', isError: true);
      return;
    }

    // CNIC Front is REQUIRED
    if (_cnicFront == null) {
      debugPrint('DEBUG: Validation failed - CNIC Front image missing!');
      AppHelpers.showSnackBar(context, 'Please upload CNIC Front', isError: true);
      return;
    }

    // CNIC Back is REQUIRED
    if (_cnicBack == null) {
      debugPrint('DEBUG: Validation failed - CNIC Back image missing!');
      AppHelpers.showSnackBar(context, 'Please upload CNIC Back', isError: true);
      return;
    }

    // Car Photo is REQUIRED
    if (_vehiclePhoto == null) {
      debugPrint('DEBUG: Validation failed - Car photo missing!');
      AppHelpers.showSnackBar(context, 'Please upload car photo', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      debugPrint('DEBUG: Uploading images to ImgBB...');

      // Upload CNIC front (REQUIRED)
      final cnicFrontUrl = await _uploadImageToImgBB(_cnicFront!, 'cnic_front');

      // Upload CNIC back (REQUIRED)
      final cnicBackUrl = await _uploadImageToImgBB(_cnicBack!, 'cnic_back');

      // Upload car photo (REQUIRED)
      final vehiclePhotoUrl = await _uploadImageToImgBB(_vehiclePhoto!, 'vehicle');

      // Send captain data to backend
      debugPrint('DEBUG: Sending data to backend...');
      await ApiService.patch('/auth/profile/captain', {
        'phone': _phoneCtrl.text.trim(),
        'captainVerificationStatus': 'pending_verification',
        'cnicFrontUrl': cnicFrontUrl,
        'cnicBackUrl': cnicBackUrl,
        'vehiclePhotoUrl': vehiclePhotoUrl,
        'cnic': _cnicCtrl.text.trim(),
        'city': _city,
        'vehicleMake': _makeCtrl.text.trim(),
        'vehicleModel': _modelCtrl.text.trim(),
        'vehicleColor': _colorCtrl.text.trim(),
        'vehicleRegistration': _regCtrl.text.trim(),
        'vehicleYear': int.parse(_yearCtrl.text.trim()),
        'vehicleSeats': int.parse(_seatsCtrl.text.trim()),
        'emergencyContactName': _emergencyNameCtrl.text.trim(),
        'emergencyContactPhone': _emergencyPhoneCtrl.text.trim(),
      });

      debugPrint('DEBUG: Captain registration successful!');
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'Registration submitted for review!');
      Navigator.pushReplacementNamed(context, '/account-created');
    } catch (e) {
      debugPrint('DEBUG: Exception caught during submission: $e');
      if (mounted) {
        AppHelpers.showSnackBar(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _cnicCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    _regCtrl.dispose();
    _yearCtrl.dispose();
    _seatsCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
        title: const Text('Captain Registration'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Hi ${user?.name ?? ''}, complete every field to submit for verification.',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Car Photo Section (Required)
            _sectionTitle('Car Photo (Required)'),
            const SizedBox(height: 8),
            _UploadTile(
              label: 'Upload Car Photo',
              image: _vehiclePhoto,
              onTap: () => _pickImage(onPicked: (f) => setState(() => _vehiclePhoto = f)),
            ),
            const SizedBox(height: 20),

            _sectionTitle('Contact'),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration('Phone (03XXXXXXXXX)'),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (digits.length != 11 || !digits.startsWith('03')) {
                  return 'Enter valid Pakistani mobile number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _city,
              decoration: _inputDecoration('City'),
              items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _city = v),
              validator: (v) => v == null ? 'Select city' : null,
            ),
            const SizedBox(height: 20),

            _sectionTitle('CNIC Information'),
            TextFormField(
              controller: _cnicCtrl,
              keyboardType: TextInputType.number,
              maxLength: 13,
              decoration: _inputDecoration('CNIC Number (13 digits)'),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (digits.length != 13) return 'Enter 13-digit CNIC';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _UploadTile(
              label: 'CNIC Front (Required)',
              image: _cnicFront,
              onTap: () => _pickImage(onPicked: (f) => setState(() => _cnicFront = f)),
            ),
            const SizedBox(height: 10),
            _UploadTile(
              label: 'CNIC Back (Required)',
              image: _cnicBack,
              onTap: () => _pickImage(onPicked: (f) => setState(() => _cnicBack = f)),
            ),
            const SizedBox(height: 20),

            _sectionTitle('Vehicle Details'),
            TextFormField(
              controller: _makeCtrl,
              decoration: _inputDecoration('Make (e.g. Toyota)'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _modelCtrl,
              decoration: _inputDecoration('Model (e.g. Corolla)'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _colorCtrl,
              decoration: _inputDecoration('Color'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _regCtrl,
              decoration: _inputDecoration('Registration (e.g. LHR-1234)'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Year'),
                    validator: (v) {
                      final y = int.tryParse(v ?? '');
                      if (y == null || y < 1990 || y > DateTime.now().year + 1) {
                        return 'Invalid year';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _seatsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Seats'),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1 || n > 8) return '1–8 seats';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _sectionTitle('Emergency Contact (not shown to passengers)'),
            TextFormField(
              controller: _emergencyNameCtrl,
              decoration: _inputDecoration('Contact name'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emergencyPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration('Contact phone'),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (digits.length < 10) return 'Enter valid phone';
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.cream,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: AppColors.white)
                    : const Text(
                  'Submit for Review',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.textDark,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );
}

class _UploadTile extends StatelessWidget {
  final String label;
  final XFile? image;
  final VoidCallback onTap;

  const _UploadTile({
    required this.label,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = image != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: done ? AppColors.primary : AppColors.sage,
            width: done ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 48,
                height: 48,
                child: done
                    ? Image.file(File(image!.path), fit: BoxFit.cover)
                    : const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Icon(
              done ? Icons.check_circle : Icons.chevron_right,
              color: done ? AppColors.success : AppColors.sage,
            ),
          ],
        ),
      ),
    );
  }
}