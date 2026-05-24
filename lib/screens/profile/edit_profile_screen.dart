import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';

// ImgBB API Key
const String IMGBB_API_KEY = 'f3e1d9b185dbeda5209741c804c2c705';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  String? _city;
  bool _isLoading = false;

  XFile? _cnicFront;
  XFile? _cnicBack;
  XFile? _vehiclePhoto;

  Map<String, dynamic>? _userData;

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/auth/profile');
      _userData = response['user'];

      _phoneCtrl.text = _userData?['phone'] ?? '';
      _cnicCtrl.text = _userData?['cnic'] ?? '';
      _city = _userData?['city'];
      _makeCtrl.text = _userData?['vehicleMake'] ?? '';
      _modelCtrl.text = _userData?['vehicleModel'] ?? '';
      _colorCtrl.text = _userData?['vehicleColor'] ?? '';
      _regCtrl.text = _userData?['vehicleRegistration'] ?? '';
      _yearCtrl.text = (_userData?['vehicleYear'] ?? '').toString();
      _seatsCtrl.text = (_userData?['vehicleSeats'] ?? '').toString();
      _emergencyNameCtrl.text = _userData?['emergencyContactName'] ?? '';
      _emergencyPhoneCtrl.text = _userData?['emergencyContactPhone'] ?? '';

      setState(() {});
    } catch (e) {
      AppHelpers.showSnackBar(context, 'Error loading data: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage({required void Function(XFile) onPicked}) async {
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Upload CNIC front if changed
      String? cnicFrontUrl;
      if (_cnicFront != null) {
        cnicFrontUrl = await _uploadImageToImgBB(_cnicFront!, 'cnic_front');
      }

      // Upload CNIC back if changed
      String? cnicBackUrl;
      if (_cnicBack != null) {
        cnicBackUrl = await _uploadImageToImgBB(_cnicBack!, 'cnic_back');
      }

      // Upload car photo if changed
      String? vehiclePhotoUrl;
      if (_vehiclePhoto != null) {
        vehiclePhotoUrl = await _uploadImageToImgBB(_vehiclePhoto!, 'vehicle');
      }

      final updateData = {
        'phone': _phoneCtrl.text.trim(),
        'cnic': _cnicCtrl.text.trim(),
        'city': _city,
        'vehicleMake': _makeCtrl.text.trim(),
        'vehicleModel': _modelCtrl.text.trim(),
        'vehicleColor': _colorCtrl.text.trim(),
        'vehicleRegistration': _regCtrl.text.trim(),
        'vehicleYear': int.tryParse(_yearCtrl.text.trim()),
        'vehicleSeats': int.tryParse(_seatsCtrl.text.trim()),
        'emergencyContactName': _emergencyNameCtrl.text.trim(),
        'emergencyContactPhone': _emergencyPhoneCtrl.text.trim(),
        if (cnicFrontUrl != null) 'cnicFrontUrl': cnicFrontUrl,
        if (cnicBackUrl != null) 'cnicBackUrl': cnicBackUrl,
        if (vehiclePhotoUrl != null) 'vehiclePhotoUrl': vehiclePhotoUrl,
      };

      await ApiService.patch('/auth/profile/captain', updateData);

      AppHelpers.showSnackBar(context, 'Profile updated successfully!');
      Navigator.pop(context);
    } catch (e) {
      AppHelpers.showSnackBar(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Car Photo Section
            const Text('Car Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            _UploadTile(
              label: 'Car Photo',
              image: _vehiclePhoto,
              onTap: () => _pickImage(onPicked: (f) => setState(() => _vehiclePhoto = f)),
            ),
            const SizedBox(height: 20),

            // CNIC Section
            const Text('CNIC Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _cnicCtrl,
              keyboardType: TextInputType.number,
              maxLength: 13,
              decoration: const InputDecoration(labelText: 'CNIC Number (13 digits)'),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (digits.isNotEmpty && digits.length != 13) return 'Enter 13-digit CNIC';
                return null;
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _UploadTile(
                    label: 'CNIC Front',
                    image: _cnicFront,
                    onTap: () => _pickImage(onPicked: (f) => setState(() => _cnicFront = f)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _UploadTile(
                    label: 'CNIC Back',
                    image: _cnicBack,
                    onTap: () => _pickImage(onPicked: (f) => setState(() => _cnicBack = f)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Vehicle Details
            const Text('Vehicle Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _makeCtrl,
              decoration: const InputDecoration(labelText: 'Make (e.g. Toyota)'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _modelCtrl,
              decoration: const InputDecoration(labelText: 'Model (e.g. Corolla)'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _colorCtrl,
              decoration: const InputDecoration(labelText: 'Color'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _regCtrl,
              decoration: const InputDecoration(labelText: 'Registration Plate'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Year'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _seatsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Seats'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Phone & City
            const Text('Contact Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (digits.isNotEmpty && (digits.length != 11 || !digits.startsWith('03'))) {
                  return 'Enter valid Pakistani mobile number';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _city,
              decoration: const InputDecoration(labelText: 'City'),
              items: const [
                'Lahore', 'Karachi', 'Islamabad', 'Rawalpindi',
                'Faisalabad', 'Multan', 'Peshawar', 'Quetta'
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _city = v),
            ),
            const SizedBox(height: 20),

            // Emergency Contact
            const Text('Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emergencyNameCtrl,
              decoration: const InputDecoration(labelText: 'Contact Name'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emergencyPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Contact Phone'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
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
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: done ? AppColors.primary : AppColors.sage,
            width: done ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(image!.path), height: 50, width: 50, fit: BoxFit.cover),
              )
            else
              const Icon(Icons.add_a_photo, size: 30, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}