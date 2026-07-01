import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
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
  final _cityCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  String? _captainVehicleType;
  bool _isLoading = false;

  XFile? _vehiclePhoto;

  Map<String, dynamic>? _userData;

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
      _cityCtrl.text = _userData?['city'] ?? '';
      _makeCtrl.text = _userData?['vehicleMake'] ?? '';
      _modelCtrl.text = _userData?['vehicleModel'] ?? '';
      _colorCtrl.text = _userData?['vehicleColor'] ?? '';
      _regCtrl.text = _userData?['vehicleRegistration'] ?? '';
      _yearCtrl.text = (_userData?['vehicleYear'] ?? '').toString();
      _seatsCtrl.text = (_userData?['vehicleSeats'] ?? '').toString();
      _captainVehicleType =
          (_userData?['captainVehicleType'] ?? '').toString().trim().isEmpty
              ? null
              : _userData?['captainVehicleType'].toString();

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
    if (_captainVehicleType == null) {
      AppHelpers.showSnackBar(context, 'Select vehicle type', isError: true);
      return;
    }
    if (_cityCtrl.text.trim().isEmpty) {
      AppHelpers.showSnackBar(context, 'Enter your city', isError: true);
      return;
    }
    if (!_hasExistingOrPicked('vehiclePhotoUrl', _vehiclePhoto)) {
      AppHelpers.showSnackBar(context, 'Upload car photo', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Upload car photo if changed
      String? vehiclePhotoUrl;
      if (_vehiclePhoto != null) {
        vehiclePhotoUrl = await _uploadImageToImgBB(_vehiclePhoto!, 'vehicle');
      }

      final updateData = {
        'phone': _phoneCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'vehicleMake': _makeCtrl.text.trim(),
        'vehicleModel': _modelCtrl.text.trim(),
        'vehicleColor': _colorCtrl.text.trim(),
        'vehicleRegistration': _regCtrl.text.trim(),
        'vehicleYear': int.tryParse(_yearCtrl.text.trim()),
        'vehicleSeats': int.tryParse(_seatsCtrl.text.trim()),
        'captainVehicleType': _captainVehicleType,
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

  bool _hasExistingOrPicked(String key, XFile? picked) {
    if (picked != null) return true;
    return (_userData?[key] ?? '').toString().trim().isNotEmpty;
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.deepNavy,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      );

  Widget _cityField() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _cityCtrl.text),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return _cities;
        return _cities.where((city) => city.toLowerCase().contains(query));
      },
      onSelected: (value) => _cityCtrl.text = value,
      fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
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
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('City (search or type manually)'),
          validator: _required,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
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
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    _regCtrl.dispose();
    _yearCtrl.dispose();
    _seatsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save',
                style: TextStyle(
                    color: AppColors.white, fontWeight: FontWeight.bold)),
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
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBlue,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.ivory),
                    ),
                    child: const Text(
                      'Keep all captain documents complete so your rides stay active and passengers can trust your profile.',
                      style: TextStyle(
                        color: AppColors.deepNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Car Photo (Required)'),
                  _UploadTile(
                    label: 'Car Photo',
                    image: _vehiclePhoto,
                    existingUrl: _userData?['vehiclePhotoUrl']?.toString(),
                    onTap: () => _pickImage(
                        onPicked: (f) => setState(() => _vehiclePhoto = f)),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Vehicle Details'),
                  DropdownButtonFormField<String>(
                    initialValue: _captainVehicleType,
                    decoration: _inputDecoration('Vehicle Type'),
                    items: const [
                      DropdownMenuItem(value: 'car', child: Text('Car')),
                      DropdownMenuItem(value: 'bike', child: Text('Bike')),
                      DropdownMenuItem(value: 'bus', child: Text('Bus')),
                      DropdownMenuItem(value: 'truck', child: Text('Truck')),
                      DropdownMenuItem(
                          value: 'shazore', child: Text('Shazore')),
                      DropdownMenuItem(value: 'tour', child: Text('Tour')),
                    ],
                    onChanged: (v) => setState(() => _captainVehicleType = v),
                    validator: (v) => v == null ? 'Select vehicle type' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _makeCtrl,
                    decoration: _inputDecoration('Make (e.g. Toyota)'),
                    validator: _required,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _modelCtrl,
                    decoration: _inputDecoration('Car Type (e.g. Corolla)'),
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
                    decoration: _inputDecoration('Registration Plate'),
                    validator: _required,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _yearCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('Model Year'),
                          validator: (v) {
                            final year = int.tryParse(v ?? '');
                            if (year == null ||
                                year < 1990 ||
                                year > DateTime.now().year + 1) {
                              return 'Invalid year';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _seatsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('Seats'),
                          validator: (v) {
                            final seats = int.tryParse(v ?? '');
                            if (seats == null || seats < 1 || seats > 60) {
                              return '1-60 seats';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Contact Information'),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('Phone Number'),
                    validator: (v) {
                      final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      if (digits.length != 11 || !digits.startsWith('03')) {
                        return 'Enter valid Pakistani mobile number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _cityField(),
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
  final String? existingUrl;
  final VoidCallback onTap;

  const _UploadTile({
    required this.label,
    required this.image,
    this.existingUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final existing = (existingUrl ?? '').trim();
    final done = image != null || existing.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
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
                width: 54,
                height: 54,
                child: image != null
                    ? Image.file(File(image!.path), fit: BoxFit.cover)
                    : existing.isNotEmpty
                        ? Image.network(
                            existing,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.error,
                            ),
                          )
                        : const Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.primary,
                          ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.deepNavy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    image != null
                        ? 'New image selected'
                        : existing.isNotEmpty
                            ? 'Uploaded'
                            : 'Required',
                    style: TextStyle(
                      color: done ? AppColors.success : AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
