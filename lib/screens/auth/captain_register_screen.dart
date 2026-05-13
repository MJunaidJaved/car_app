import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/session_storage.dart';
import '../../providers/user_provider.dart';
import '../../utils/helpers.dart';

class _C {
  static const primary   = Color(0xFF39988E);
  static const dark      = Color(0xFF1F6059);
  static const light     = Color(0xFFB6D7D1);
  static const bg        = Color(0xFFF5F5F5);
  static const white     = Color(0xFFFFFFFF);
  static const textDark  = Color(0xFF0D1F1E);
  static const textMuted = Color(0xFF7A9E9B);
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
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
          // Teal header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.dark, _C.primary],
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

          // Decorative circle
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.white.withOpacity(0.05),
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
                                  fontSize:   18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Step 3 of 3  •  Captain Verification',
                                style: TextStyle(
                                  color:    _C.white.withOpacity(0.65),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: List.generate(3, (i) {
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                                right: i < 2 ? 6 : 0),
                            height: 4,
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

                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // Profile photo + name card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color:        _C.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color:      _C.dark.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset:     const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor:
                                          _C.light.withOpacity(0.5),
                                      child: Text(
                                        ((user?.name ?? 'U')[0]).toUpperCase(),
                                        style: const TextStyle(
                                          color:      _C.primary,
                                          fontSize:   24,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0, right: 0,
                                      child: Container(
                                        width: 22, height: 22,
                                        decoration: BoxDecoration(
                                          color:  _C.primary,
                                          shape:  BoxShape.circle,
                                          border: Border.all(
                                              color: _C.white, width: 2),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: _C.white, size: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.name ?? 'Your Name',
                                        style: const TextStyle(
                                          color:      _C.textDark,
                                          fontSize:   16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        user?.email ?? '',
                                        style: const TextStyle(
                                          color:    _C.textMuted,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color:        _C.primary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'Captain Account',
                                          style: TextStyle(
                                            color:      _C.primary,
                                            fontSize:   11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Phone number card
                          _SectionCard(
                            title: 'Phone Number',
                            child: TextFormField(
                              controller:   _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(
                                color:      _C.textDark,
                                fontSize:   15,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText:  '+92 3XX XXXXXXX',
                                hintStyle: const TextStyle(
                                    color: _C.textMuted),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '🇵🇰',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 1, height: 20,
                                        color: _C.light,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                  ),
                                ),
                                filled:     true,
                                fillColor:  const Color(0xFFF0F7F6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide:   BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide:   BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: _C.primary, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: Colors.redAccent, width: 1.5),
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

                          const SizedBox(height: 14),

                          // CNIC Upload Card
                          _SectionCard(
                            title:    'CNIC & Documents',
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:        _C.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Captain only',
                                style: TextStyle(
                                  color:      _C.primary,
                                  fontSize:   11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Upload area
                                GestureDetector(
                                  onTap: () => _pickCnic(front: true),
                                  child: _UploadTile(
                                    label:    'CNIC Front Side',
                                    image:    _cnicFront,
                                    onTap:    () => _pickCnic(front: true),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () => _pickCnic(front: false),
                                  child: _UploadTile(
                                    label: 'CNIC Back Side',
                                    image: _cnicBack,
                                    onTap: () => _pickCnic(front: false),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Note
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:        const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        color: Color(0xFFFF9800),
                                        size:  16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'JPG, PNG or PDF  •  Max 5MB each  •  Admin verifies within 24 hrs',
                                          style: TextStyle(
                                            color:    _C.textMuted,
                                            fontSize: 11,
                                            height:   1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Submit button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:         _C.primary,
                                foregroundColor:         _C.white,
                                disabledBackgroundColor: _C.light,
                                elevation:   0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                        color:       _C.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Submit for Review',
                                      style: TextStyle(
                                        fontSize:   16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Center(
                            child: Text(
                              'Admin verifies docs within 24 hours',
                              style: TextStyle(
                                color:    _C.textMuted,
                                fontSize: 12,
                              ),
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
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color:      _C.textDark,
                  fontSize:   15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 14),
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
        padding:  const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        isDone
              ? _C.primary.withOpacity(0.06)
              : const Color(0xFFF0F7F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone ? _C.primary : _C.light,
            width: isDone ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width:  48,
                height: 48,
                child: image != null
                    ? Image.file(
                        File(image!.path),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color:        _C.light.withOpacity(0.4),
                        child: Icon(
                          Icons.upload_rounded,
                          color: _C.textMuted,
                          size:  22,
                        ),
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
                    style: TextStyle(
                      color:      isDone ? _C.primary : _C.textDark,
                      fontSize:   13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isDone ? (image!.name) : 'Tap to upload',
                    style: TextStyle(
                      color:    isDone ? _C.primary : _C.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isDone
                  ? Icons.edit_outlined
                  : Icons.chevron_right_rounded,
              color: isDone ? _C.primary : _C.textMuted,
              size:  18,
            ),
          ],
        ),
      ),
    );
  }
}