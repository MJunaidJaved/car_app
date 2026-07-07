import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/helpers.dart';

// ImgBB API Key
const String imgbbApiKey = 'f3e1d9b185dbeda5209741c804c2c705';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _loadedExternalProfile = false;
  UserModel? _externalUser;

  // Captain performance stats (sirf apni profile pe, Lifetime tab nahi)
  Map<String, dynamic> _todayStats = {'ridesCompleted': 0, 'earningsRs': 0};
  Map<String, dynamic> _weekStats = {'ridesCompleted': 0, 'earningsRs': 0};
  Map<String, dynamic> _monthStats = {'ridesCompleted': 0, 'earningsRs': 0};
  String _selectedStatsPeriod = 'today';

  // Helper method to get user ID from response
  String _getUserIdFromMap(Map<String, dynamic> userMap) {
    return userMap['id'] ?? userMap['uid'] ?? '';
  }

  /// Upload image to ImgBB and return URL
  Future<String?> _uploadImageToImgBB(File imageFile, String type) async {
    try {
      debugPrint('Uploading $type to ImgBB...');

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'),
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

  // Only upload car photo
  Future<void> _uploadCarPhoto() async {
    if (_isUploading) return;
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
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (file == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final imageFile = File(file.path);
      final imageUrl = await _uploadImageToImgBB(imageFile, 'vehicle');

      if (imageUrl == null) throw Exception('Upload failed');

      await ApiService.patch('/auth/profile', {
        'vehiclePhotoUrl': imageUrl,
      });

      final response = await ApiService.get('/auth/profile');
      final userMap = response['user'] as Map<String, dynamic>;
      final userId = _getUserIdFromMap(userMap);
      final updatedUser = UserModel.fromMap(userMap, userId);
      if (!mounted) return;
      Provider.of<UserProvider>(context, listen: false).setUser(updatedUser);

      AppHelpers.showSnackBar(context, 'Car photo updated!');
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'Upload failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _showEditProfile(BuildContext context, UserModel? user) async {
    if (user == null) return;
    await Navigator.pushNamed(context, '/edit-profile');
    if (!context.mounted) return;
    try {
      final response = await ApiService.get('/auth/profile');
      final userMap = response['user'] as Map<String, dynamic>;
      final userId = _getUserIdFromMap(userMap);
      final updatedUser = UserModel.fromMap(userMap, userId);
      if (!context.mounted) return;
      Provider.of<UserProvider>(context, listen: false).setUser(updatedUser);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedExternalProfile) return;
    _loadedExternalProfile = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is UserModel && args.role == 'captain') {
      _externalUser = args;
      _loadExternalCaptain(args.id);
    } else {
      // Apni profile — agar captain hai to performance stats + reviews load karo
      final ownUser = Provider.of<UserProvider>(context, listen: false).user;
      if (ownUser != null && ownUser.role == 'captain') {
        _loadCaptainStats();
        _loadOwnRecentReviews(ownUser.id);
      }
    }
  }

  Future<void> _loadExternalCaptain(String captainId) async {
    try {
      final data = await FirestoreService().getCaptainProfile(captainId);
      if (!mounted) return;
      setState(() {
        _externalUser =
            UserModel.fromMap(data, data['id']?.toString() ?? captainId);
      });
    } catch (_) {}
  }

  Future<void> _loadCaptainStats() async {
    try {
      final res = await ApiService.get('/captain/stats');
      if (!mounted) return;
      setState(() {
        _todayStats = res['today'] ?? _todayStats;
        _weekStats = res['week'] ?? _weekStats;
        _monthStats = res['month'] ?? _monthStats;
      });
    } catch (_) {}
  }

  // Yeh wahi backend endpoint use karta hai jo customer captain ki profile
  // dekhte waqt use hota hai — is se apni profile pe bhi rating/reviews
  // (jo customers ne diye) dikhne lagenge.
  Future<void> _loadOwnRecentReviews(String captainId) async {
    try {
      final data = await FirestoreService().getCaptainProfile(captainId);
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final current = userProvider.user;
      if (current == null) return;
      userProvider.setUser(current.copyWith(
        rating: (data['averageRating'] ?? data['rating']) != null
            ? (data['averageRating'] ?? data['rating']).toDouble()
            : null,
        reviewCount: data['reviewCount'] != null
            ? int.tryParse(data['reviewCount'].toString())
            : null,
        completedRides: data['completedRides'] != null
            ? int.tryParse(data['completedRides'].toString())
            : null,
        recentReviews: data['recentReviews'] is List
            ? List<Map<String, dynamic>>.from(data['recentReviews'])
            : null,
      ));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    final args = ModalRoute.of(context)?.settings.arguments;
    final isExternal = args is UserModel;
    final user = isExternal
        ? (_externalUser ?? args)
        : Provider.of<UserProvider>(context).user;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 260,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.bark, AppColors.moss],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -40,
                      right: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                  ],
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: AppColors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text('Profile',
                            style: TextStyle(
                                color: AppColors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        if (!isExternal)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.edit_outlined,
                                  color: AppColors.white, size: 18),
                              onPressed: () => _showEditProfile(context, user),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Avatar (No camera button)
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              AppColors.white.withValues(alpha: 0.2),
                          backgroundImage: (user?.photoUrl != null &&
                                  user!.photoUrl!.isNotEmpty)
                              ? CachedNetworkImageProvider(user.photoUrl!)
                              : null,
                          child: (user?.photoUrl == null ||
                                  user!.photoUrl!.isEmpty)
                              ? Text(
                                  AppHelpers.nameInitial(user?.name,
                                      fallback: 'U'),
                                  style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.w700),
                                )
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(user?.name ?? 'User',
                            style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        Text(user?.email ?? '',
                            style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.7),
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (user?.role == 'captain')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: (user?.captainVerificationStatus == 'verified'
                                  ? AppColors.success
                                  : AppColors.warning)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color:
                                  (user?.captainVerificationStatus == 'verified'
                                          ? AppColors.success
                                          : AppColors.warning)
                                      .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              user?.captainVerificationStatus == 'verified'
                                  ? Icons.verified_rounded
                                  : Icons.pending_actions_rounded,
                              color:
                                  user?.captainVerificationStatus == 'verified'
                                      ? AppColors.success
                                      : AppColors.warning,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.captainVerificationStatus ==
                                            'verified'
                                        ? 'Verified Captain'
                                        : 'Verification Pending',
                                    style: const TextStyle(
                                        color: AppColors.bark,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14),
                                  ),
                                  Text(
                                    user?.captainVerificationStatus ==
                                            'verified'
                                        ? 'You are a trusted driver'
                                        : 'We are reviewing your documents',
                                    style: TextStyle(
                                        color: AppColors.bark
                                            .withValues(alpha: 0.7),
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Your Performance card — sirf apni profile pe (Lifetime tab nahi)
                  if (user?.role == 'captain' && !isExternal)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: AppColors.sage.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Performance',
                              style: TextStyle(
                                color: AppColors.bark,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children:
                                    ['today', 'week', 'month'].map((period) {
                                  final isSelected =
                                      _selectedStatsPeriod == period;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => _selectedStatsPeriod = period),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.bg,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: isSelected
                                              ? null
                                              : Border.all(
                                                  color: AppColors.line),
                                        ),
                                        child: Text(
                                          period[0].toUpperCase() +
                                              period.substring(1),
                                          style: TextStyle(
                                            color: isSelected
                                                ? AppColors.white
                                                : AppColors.bark,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Builder(builder: (context) {
                              final stats = _selectedStatsPeriod == 'today'
                                  ? _todayStats
                                  : _selectedStatsPeriod == 'week'
                                      ? _weekStats
                                      : _monthStats;
                              final rides = stats['ridesCompleted'] ?? 0;
                              final earnings = stats['earningsRs'] ?? 0;
                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Rides Completed',
                                            style: TextStyle(
                                                color: AppColors.sage,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 6),
                                        Text('$rides',
                                            style: const TextStyle(
                                                color: AppColors.bark,
                                                fontSize: 24,
                                                fontWeight: FontWeight.w900)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                      width: 1,
                                      height: 50,
                                      color: AppColors.line),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Earnings',
                                              style: TextStyle(
                                                  color: AppColors.sage,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 6),
                                          Text(
                                              'Rs ${(earnings as num).toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                  color: AppColors.moss,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w900)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                  if (user?.role == 'captain')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: AppColors.sage.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.directions_car_rounded,
                                    color: AppColors.moss, size: 20),
                                const SizedBox(width: 10),
                                const Text('Vehicle Details',
                                    style: TextStyle(
                                        color: AppColors.bark,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800)),
                                const Spacer(),
                                if (!isExternal)
                                  GestureDetector(
                                    onTap: () =>
                                        _showEditProfile(context, user),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.moss
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.edit,
                                              size: 14, color: AppColors.moss),
                                          SizedBox(width: 4),
                                          Text('Edit',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.moss)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _VehicleDetailRow(
                                label: 'Car Name/Model',
                                value: (user?.vehicleModel ?? '').trim().isEmpty
                                    ? 'Not set'
                                    : user!.vehicleModel!),
                            const SizedBox(height: 8),
                            _VehicleDetailRow(
                                label: 'Registration',
                                value: user?.vehicleRegistration ?? 'Not set'),
                            const SizedBox(height: 8),
                            _VehicleDetailRow(
                                label: 'Seats',
                                value: (user?.vehicleSeats ?? 0) > 0
                                    ? '${user!.vehicleSeats} seats'
                                    : 'Not set'),
                          ],
                        ),
                      ),
                    ),

                  // Car Photo Upload Section
                  if (user?.role == 'captain')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: AppColors.sage.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.photo_library,
                                    color: AppColors.moss, size: 20),
                                SizedBox(width: 10),
                                Text('Car Photo',
                                    style: TextStyle(
                                        color: AppColors.bark,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: isExternal ? null : _uploadCarPhoto,
                              child: Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: AppColors.sage
                                          .withValues(alpha: 0.3)),
                                  image: (user?.vehiclePhotoUrl != null &&
                                          user!.vehiclePhotoUrl!.isNotEmpty)
                                      ? DecorationImage(
                                          image: CachedNetworkImageProvider(
                                            user.vehiclePhotoUrl!,
                                          ),
                                          fit: BoxFit.cover)
                                      : null,
                                ),
                                child: (user?.vehiclePhotoUrl == null ||
                                        user!.vehiclePhotoUrl!.isEmpty)
                                    ? const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_photo_alternate,
                                              size: 40, color: AppColors.sage),
                                          SizedBox(height: 8),
                                          Text('Tap to upload car photo',
                                              style: TextStyle(
                                                  color: AppColors.sage)),
                                        ],
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: AppColors.sage.withValues(alpha: 0.3),
                            width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              child: _TrustStat(
                                  value: (user?.rating ?? 0).toStringAsFixed(1),
                                  label: 'Rating',
                                  icon: Icons.verified_rounded)),
                          Container(
                              width: 1,
                              height: 40,
                              color: AppColors.sage.withValues(alpha: 0.2)),
                          Expanded(
                              child: _TrustStat(
                                  value:
                                      '${user?.completedRides ?? user?.totalRides ?? 0}',
                                  label: 'Completed',
                                  icon: Icons.directions_car_filled_rounded)),
                          Container(
                              width: 1,
                              height: 40,
                              color: AppColors.sage.withValues(alpha: 0.2)),
                          Expanded(
                              child: _TrustStat(
                                  value: '${user?.reviewCount ?? 0}',
                                  label: 'Reviews',
                                  icon: Icons.rate_review_outlined)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if ((user?.recentReviews ?? const []).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppColors.sage.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recent Feedback',
                              style: TextStyle(
                                color: AppColors.bark,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...user!.recentReviews.take(3).map((review) {
                              final text = (review['review'] ?? '').toString();
                              final rating = (review['rating'] ?? 0).toString();
                              final customer =
                                  (review['customerName'] ?? 'Customer')
                                      .toString();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded,
                                            color: AppColors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          rating,
                                          style: const TextStyle(
                                            color: AppColors.bark,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            customer,
                                            style: const TextStyle(
                                              color: AppColors.sage,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (text.trim().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        text,
                                        style: const TextStyle(
                                          color: AppColors.bark,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  if (!isExternal) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: AppColors.sage.withValues(alpha: 0.3),
                              width: 1),
                        ),
                        child: Column(
                          children: [
                            _ProfileMenuItem(
                                icon: Icons.notifications_outlined,
                                label: 'Notifications',
                                accentColor: AppColors.amber,
                                onTap: () => Navigator.pushNamed(
                                    context, '/notifications')),
                            _ProfileMenuItem(
                                icon: Icons.help_outline_rounded,
                                label: 'Help & Support',
                                accentColor: AppColors.cyan,
                                onTap: () => _showHelpSheet(context)),
                            _ProfileMenuItem(
                              icon: user?.role == 'captain'
                                  ? Icons.person_outline_rounded
                                  : Icons.directions_car_rounded,
                              label: user?.role == 'captain'
                                  ? 'Switch to Passenger'
                                  : 'Switch to Captain',
                              accentColor: AppColors.vehicleTruck,
                              onTap: () async {
                                final userProvider = Provider.of<UserProvider>(
                                    context,
                                    listen: false);
                                final newRole = user?.role == 'captain'
                                    ? 'passenger'
                                    : 'captain';
                                try {
                                  await ApiService.patch(
                                      '/auth/profile', {'role': newRole});
                                  final response =
                                      await ApiService.get('/auth/profile');
                                  final userMap =
                                      response['user'] as Map<String, dynamic>;
                                  final userId =
                                      userMap['id'] ?? userMap['uid'] ?? '';
                                  final updatedUser =
                                      UserModel.fromMap(userMap, userId);
                                  userProvider.setUser(updatedUser);
                                  if (context.mounted) {
                                    Navigator.pushNamedAndRemoveUntil(
                                        context, '/home', (_) => false);
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  AppHelpers.showSnackBar(
                                      context, 'Failed to switch role: $e',
                                      isError: true);
                                }
                              },
                            ),
                            _ProfileMenuItem(
                              icon: Icons.logout_rounded,
                              label: 'Sign Out',
                              isDestructive: true,
                              showDivider: false,
                              onTap: () async {
                                final authService = Provider.of<AuthService>(
                                    context,
                                    listen: false);
                                final userProvider = Provider.of<UserProvider>(
                                    context,
                                    listen: false);
                                await authService.signOut();
                                userProvider.clear();
                                if (context.mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, '/', (_) => false);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          // Footer Powered text only on Profile
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Center(
              child: Text(
                'Powered by HiTECH TECHNOLOGIES',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.95),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Help & Support',
                style: TextStyle(
                    color: AppColors.bark,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            const Text('Need assistance? Contact our support team.',
                style: TextStyle(color: AppColors.bark, fontSize: 14)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.sage.withValues(alpha: 0.3))),
              child: const Row(children: [
                Icon(Icons.email_outlined, color: AppColors.primary),
                SizedBox(width: 12),
                Text('hitechnologies2014@gmail.com',
                    style: TextStyle(
                        color: AppColors.bark, fontWeight: FontWeight.w700))
              ]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.cream,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              child: const Text('Close',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _TrustStat(
      {required this.value, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.white, size: 18),
      ),
      const SizedBox(height: 8),
      Text(value,
          style: const TextStyle(
              color: AppColors.bark,
              fontSize: 18,
              fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: AppColors.sage, fontSize: 11)),
    ]);
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showDivider;
  final Color? accentColor;
  const _ProfileMenuItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.isDestructive = false,
      this.showDivider = true,
      this.accentColor});
  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? AppColors.error : (accentColor ?? AppColors.primary);
    return Column(children: [
      ListTile(
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label,
            style: TextStyle(
                color: isDestructive ? AppColors.error : AppColors.bark,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        trailing: isDestructive
            ? null
            : Icon(Icons.chevron_right_rounded,
                color: AppColors.sage.withValues(alpha: 0.6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      ),
      if (showDivider)
        Divider(
            color: AppColors.sage.withValues(alpha: 0.15),
            height: 1,
            indent: 66),
    ]);
  }
}

class _VehicleDetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _VehicleDetailRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: const TextStyle(
              color: AppColors.sage,
              fontSize: 13,
              fontWeight: FontWeight.w600)),
      Text(value,
          style: const TextStyle(
              color: AppColors.bark,
              fontSize: 13,
              fontWeight: FontWeight.w700)),
    ]);
  }
}
