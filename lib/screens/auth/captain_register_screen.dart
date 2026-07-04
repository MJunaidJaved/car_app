import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
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
  final _cityCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController(text: '4');

  static const _cities = [
    'Abbottabad',
    'Bahawalpur',
    'Dera Ghazi Khan',
    'Lahore',
    'Karachi',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Gujranwala',
    'Gujrat',
    'Hyderabad',
    'Jhelum',
    'Kasur',
    'Larkana',
    'Multan',
    'Murree',
    'Okara',
    'Peshawar',
    'Quetta',
    'Rahim Yar Khan',
    'Sahiwal',
    'Sargodha',
    'Sialkot',
    'Sukkur',
    'Wah Cantt',
  ];

  final ImagePicker _picker = ImagePicker();
  String? _gender;
  String? _captainVehicleType;
  bool _isLoading = false;

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

    final city = _cityCtrl.text.trim();
    if (city.isEmpty) {
      debugPrint('DEBUG: Validation failed - City is null!');
      AppHelpers.showSnackBar(context, 'Enter your city', isError: true);
      return;
    }
    if (_gender == null) {
      AppHelpers.showSnackBar(context, 'Select your gender', isError: true);
      return;
    }
    if (_captainVehicleType == null) {
      AppHelpers.showSnackBar(context, 'Select your vehicle type',
          isError: true);
      return;
    }

    // Car Photo is REQUIRED
    if (_vehiclePhoto == null) {
      debugPrint('DEBUG: Validation failed - Car photo missing!');
      AppHelpers.showSnackBar(context, 'Please upload car photo',
          isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      debugPrint('DEBUG: Uploading images to ImgBB...');

      // Upload car photo (REQUIRED)
      final vehiclePhotoUrl =
          await _uploadImageToImgBB(_vehiclePhoto!, 'vehicle');

      // Send captain data to backend
      debugPrint('DEBUG: Sending data to backend...');
      final authService = Provider.of<AuthService>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = await authService.syncRole(
        role: 'captain',
        phone: _phoneCtrl.text.trim(),
        gender: _gender,
        captainVerificationStatus: 'pending_verification',
        vehiclePhotoUrl: vehiclePhotoUrl,
        city: city,
        vehicleMake: _captainVehicleType,
        vehicleModel: _modelCtrl.text.trim(),
        captainVehicleType: _captainVehicleType,
        vehicleRegistration: _regCtrl.text.trim(),
        vehicleSeats: int.parse(_seatsCtrl.text.trim()),
      );
      userProvider.setUser(user);

      debugPrint('DEBUG: Captain registration successful!');
      if (!mounted) return;
      AppHelpers.showSnackBar(
        context,
        'Documents submitted. Admin verification is required before access.',
      );
      Navigator.pushReplacementNamed(context, '/verification-pending');
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
    _cityCtrl.dispose();
    _modelCtrl.dispose();
    _regCtrl.dispose();
    _seatsCtrl.dispose();
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
              onTap: () => _pickImage(
                  onPicked: (f) => setState(() => _vehiclePhoto = f)),
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
            Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                final query = textEditingValue.text.trim().toLowerCase();
                if (query.isEmpty) return _cities;
                return _cities
                    .where((city) => city.toLowerCase().contains(query));
              },
              onSelected: (value) => _cityCtrl.text = value,
              fieldViewBuilder:
                  (context, textController, focusNode, onFieldSubmitted) {
                if (textController.text != _cityCtrl.text) {
                  textController.text = _cityCtrl.text;
                  textController.selection = TextSelection.collapsed(
                    offset: textController.text.length,
                  );
                }
                textController.addListener(() {
                  if (_cityCtrl.text != textController.text) {
                    _cityCtrl.text = textController.text;
                  }
                });
                return TextFormField(
                  controller: textController,
                  focusNode: focusNode,
                  decoration:
                      _inputDecoration('City (search or type manually)'),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter city' : null,
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(16),
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxHeight: 240, maxWidth: 360),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            dense: true,
                            title: Text(option),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: _inputDecoration('Gender'),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (v) => setState(() => _gender = v),
              validator: (v) => v == null ? 'Select gender' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _captainVehicleType,
              decoration: _inputDecoration('Captain Vehicle Type'),
              items: const [
                DropdownMenuItem(value: 'car', child: Text('Car')),
                DropdownMenuItem(value: 'bike', child: Text('Bike')),
                DropdownMenuItem(value: 'bus', child: Text('Bus')),
                DropdownMenuItem(value: 'truck', child: Text('Truck')),
                DropdownMenuItem(value: 'shazore', child: Text('Shazore')),
                DropdownMenuItem(value: 'tour', child: Text('Tour')),
              ],
              onChanged: (v) => setState(() => _captainVehicleType = v),
              validator: (v) => v == null ? 'Select vehicle type' : null,
            ),
            const SizedBox(height: 20),

            _sectionTitle('Vehicle Details'),
            TextFormField(
              controller: _modelCtrl,
              decoration: _inputDecoration('Vehicle name / model (e.g. Corolla, CD 70)'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _regCtrl,
              decoration: _inputDecoration('Registration (e.g. LHR-1234)'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _seatsCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Seats'),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1 || n > 60) return '1-60 seats';
                return null;
              },
            ),
            const SizedBox(height: 20),

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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: done ? AppColors.primary : AppColors.sage,
            width: done ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 48,
                height: 48,
                child: done
                    ? Image.file(File(image!.path), fit: BoxFit.cover)
                    : const Icon(Icons.add_a_photo_outlined,
                        color: AppColors.primary),
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
