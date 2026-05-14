import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/session_storage.dart';
import '../../providers/user_provider.dart';
import '../../utils/helpers.dart';

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

class CaptainRegisterScreen extends StatefulWidget {
  const CaptainRegisterScreen({super.key});
  @override
  State<CaptainRegisterScreen> createState() =>
      _CaptainRegisterScreenState();
}

class _CaptainRegisterScreenState extends State<CaptainRegisterScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _phoneCtrl   = TextEditingController();
  bool  _isLoading   = false;

  final ImagePicker _picker = ImagePicker();

  XFile? _cnicFront;
  XFile? _cnicBack;

  Future<void> _pickCnic({required bool front}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: _C.black),
                title: const Text('Choose from gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: _C.black),
                title: const Text('Take a photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    final x = await _picker.pickImage(
      source: source,
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (!mounted) return;
    if (x != null) {
      setState(() {
        if (front) {
          _cnicFront = x;
        } else {
          _cnicBack = x;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cnicFront == null || _cnicBack == null) {
      AppHelpers.showSnackBar(
          context, 'Please upload both CNIC sides', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userProvider =
          Provider.of<UserProvider>(context, listen: false);
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      await SessionStorage.setPhone(_phoneCtrl.text.trim());
      await SessionStorage.setCaptainDocsPending(true);
      final u = await SessionStorage.loadUserModel();
      if (!mounted) return;
      if (u != null) userProvider.setUser(u);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/account-created');
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
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final userProvider = Provider.of<UserProvider>(context);
    final user         = userProvider.user;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Gradient header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.dark, Color(0xFF414833)],
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight,
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
                              color:        _C.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: _C.white, size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Complete your profile',
                                style: TextStyle(
                                  color:      _C.white,
                                  fontSize:   20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Step 3 of 3  •  Captain Verification',
                                style: TextStyle(
                                  color:    _C.white.withOpacity(0.75),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: List.generate(3, (i) {
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                                right: i < 2 ? 8 : 0),
                            height: 6,
                            decoration: BoxDecoration(
                              color:        i <= 2
                                  ? _C.white
                                  : _C.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Profile card
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color:        _C.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color:      Colors.black.withOpacity(0.02),
                                  blurRadius: 20,
                                  offset:     const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor:
                                          _C.primary.withOpacity(0.1),
                                      child: Text(
                                        ((user?.name ?? 'U')[0]).toUpperCase(),
                                        style: const TextStyle(
                                          color:      _C.primary,
                                          fontSize:   24,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0, right: 0,
                                      child: Container(
                                        width: 24, height: 24,
                                        decoration: BoxDecoration(
                                          color:  _C.primary,
                                          shape:  BoxShape.circle,
                                          border: Border.all(
                                              color: _C.white, width: 2.5),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: _C.white, size: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.name ?? 'Your Name',
                                        style: const TextStyle(
                                          color:      _C.textDark,
                                          fontSize:   18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        user?.email ?? '',
                                        style: const TextStyle(
                                          color:    _C.textMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:        _C.primary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'Captain Profile',
                                          style: TextStyle(
                                            color:      _C.primary,
                                            fontSize:   11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Phone card
                          _SectionCard(
                            title: 'Phone Number',
                            child: TextFormField(
                              controller:   _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(
                                color:      _C.textDark,
                                fontSize:   15,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText:  '03XX XXXXXXX',
                                hintStyle: const TextStyle(
                                    color: _C.textMuted, fontWeight: FontWeight.w500),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '🇵🇰',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        width: 1.5, height: 20,
                                        color: const Color(0xFFCCBFA3),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                  ),
                                ),
                                filled:     true,
                                fillColor:  _C.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide:   const BorderSide(color: Color(0xFFCCBFA3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide:   const BorderSide(color: Color(0xFFCCBFA3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                      color: _C.primary, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Enter your phone number';
                                if (v.length < 11)
                                  return 'Enter a valid Pakistan number';
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // CNIC Card
                          _SectionCard(
                            title:    'CNIC & Documents',
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color:        _C.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Captain only',
                                style: TextStyle(
                                  color:      _C.primary,
                                  fontSize:   11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                _UploadTile(
                                  label:    'CNIC Front Side',
                                  image:    _cnicFront,
                                  onTap:    () => _pickCnic(front: true),
                                ),
                                const SizedBox(height: 12),
                                _UploadTile(
                                  label: 'CNIC Back Side',
                                  image: _cnicBack,
                                  onTap: () => _pickCnic(front: false),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:        const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFFD54F), width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        color: Color(0xFFFF9800),
                                        size:  18,
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          'Admin verifies docs within 24 hrs for Captain access.',
                                          style: TextStyle(
                                            color:    _C.textDark,
                                            fontSize: 11,
                                            height:   1.4,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Submit button
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:         _C.primary,
                                foregroundColor:         _C.white,
                                disabledBackgroundColor: const Color(0xFFCCBFA3),
                                elevation:   0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24, height: 24,
                                      child: CircularProgressIndicator(
                                        color:       _C.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text(
                                      'Submit for Review',
                                      style: TextStyle(
                                        fontSize:   16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 40),
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
  final String  title;
  final Widget  child;
  final Widget? trailing;
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color:        _C.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset:     const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color:      _C.textDark,
                  fontSize:   16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final String  label;
  final XFile?  image;
  final VoidCallback onTap;
  const _UploadTile({
    required this.label,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = image != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding:  const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        isDone
              ? _C.primary.withOpacity(0.05)
              : _C.bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDone ? _C.primary : const Color(0xFFCCBFA3),
            width: isDone ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width:  52,
                height: 52,
                child: image != null
                    ? Image.file(
                        File(image!.path),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color:        _C.primary.withOpacity(0.1),
                        child: const Icon(
                          Icons.add_photo_alternate_rounded,
                          color: _C.primary,
                          size:  24,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color:      _C.textDark,
                      fontSize:   14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    isDone ? (image!.name) : 'Tap to upload side',
                    style: TextStyle(
                      color:    isDone ? _C.primary : _C.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: isDone ? const Color(0xFF4A7C59) : const Color(0xFFCCBFA3),
              size:  22,
            ),
          ],
        ),
      ),
    );
  }
}


