import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/app_colors.dart';
import '../../widgets/co_riders_section.dart';

class FareNegotiateScreen extends StatefulWidget {
  final RideModel ride;
  final bool isCaptain; // ✅ ADDED: true if captain is negotiating

  const FareNegotiateScreen({
    super.key,
    required this.ride,
    this.isCaptain = false,
  });

  @override
  State<FareNegotiateScreen> createState() => _FareNegotiateScreenState();
}

class _FareNegotiateScreenState extends State<FareNegotiateScreen> {
  final _offerCtrl = TextEditingController();
  final _pickupCtrl = TextEditingController();
  final _dropCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isConfirmed = false;
  bool _isCreatingDeal = false;
  double _finalAgreedFare = 0.0;
  bool _showMap = false;
  String? _pickupError;
  double _pickupLat = 0;
  double _pickupLng = 0;
  double _dropLat = 0;
  double _dropLng = 0;
  bool _isFareDone = false; // ✅ NEW: Track if fare is finalized

  @override
  void initState() {
    super.initState();
    _finalAgreedFare = widget.ride.suggestedFare;
    _dropCtrl.text = widget.ride.endLocation;
    if (widget.ride.endLat != 0 && widget.ride.endLng != 0) {
      _dropLat = widget.ride.endLat;
      _dropLng = widget.ride.endLng;
    }
    if (widget.ride.startLat != 0 && widget.ride.startLng != 0) {
      _pickupLat = widget.ride.startLat;
      _pickupLng = widget.ride.startLng;
    }
    if (widget.ride.isFull) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppHelpers.showSnackBar(context, 'This ride is full', isError: true);
        Navigator.pop(context);
      });
    }
  }

  String _now() {
    final t = TimeOfDay.now();
    return '${t.hour}:${t.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildChatArea() {
    if (_messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.handshake_outlined,
                size: 48,
                color: AppColors.ivory,
              ),
              SizedBox(height: 12),
              Text(
                'Negotiate your fare or accept the captain\'s price',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.dustyBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, i) => _ChatBubble(message: _messages[i]),
    );
  }

  bool _validatePickup() {
    final empty = _pickupCtrl.text.trim().isEmpty;
    if (empty) {
      setState(() => _pickupError = 'Enter your exact pickup point');
      return false;
    }
    setState(() => _pickupError = null);
    return true;
  }

  // ✅ Captain sends fare to customer
  Future<void> _sendCaptainOffer() async {
    if (_offerCtrl.text.isEmpty || _isCreatingDeal) return;
    final offerDouble = double.tryParse(_offerCtrl.text.trim()) ?? 0.0;
    if (offerDouble <= 0) {
      AppHelpers.showSnackBar(context, 'Enter a valid fare amount',
          isError: true);
      return;
    }

    setState(() {
      _finalAgreedFare = offerDouble;
      _isFareDone = true; // ✅ Fare is done/countered
      _messages.add(_ChatMessage(
        text: 'Captain offered: Rs ${offerDouble.toStringAsFixed(0)}',
        isSystem: true,
        isAccepted: true,
        time: _now(),
      ));
      _offerCtrl.clear();
    });
    _scrollToEnd();

    // ✅ Show customer that fare is done, now they can enter pickup
    setState(() {
      _isConfirmed = true;
    });
  }

  // ✅ Customer sends offer to captain
  Future<void> _sendCustomerOffer() async {
    if (_offerCtrl.text.isEmpty || _isCreatingDeal) return;
    if (!_validatePickup()) return;
    final offerDouble = double.tryParse(_offerCtrl.text.trim()) ?? 0.0;
    if (offerDouble <= 0) {
      AppHelpers.showSnackBar(context, 'Enter a valid fare amount',
          isError: true);
      return;
    }

    setState(() {
      _finalAgreedFare = offerDouble;
      _isFareDone = true; // ✅ Fare is done/countered
      _messages.add(_ChatMessage(
        text: 'You offered: Rs ${offerDouble.toStringAsFixed(0)}',
        isSystem: true,
        isAccepted: true,
        time: _now(),
      ));
      _offerCtrl.clear();
    });
    _scrollToEnd();

    // ✅ Show that fare is done, now enter pickup
    setState(() {
      _isConfirmed = true;
    });
  }

  // ✅ Customer accepts captain's fare
  Future<void> _acceptCaptainFare() async {
    if (_isCreatingDeal) return;
    if (!_validatePickup()) return;
    setState(() {
      _finalAgreedFare = widget.ride.suggestedFare;
      _isFareDone = true;
      _messages.add(_ChatMessage(
        text:
            'You accepted: Rs ${widget.ride.suggestedFare.toStringAsFixed(0)}',
        isSystem: true,
        isAccepted: true,
        time: _now(),
      ));
    });
    _scrollToEnd();

    // ✅ Show fare done, enter pickup
    setState(() {
      _isConfirmed = true;
    });
  }

  // ✅ Captain accepts customer's offer (if customer sent first)
  Future<void> _acceptCustomerOffer() async {
    if (_isCreatingDeal) return;
    setState(() {
      _isFareDone = true;
      _messages.add(_ChatMessage(
        text:
            'Captain accepted your offer: Rs ${_finalAgreedFare.toStringAsFixed(0)}',
        isSystem: true,
        isAccepted: true,
        time: _now(),
      ));
    });
    _scrollToEnd();

    // ✅ Show fare done, enter pickup
    setState(() {
      _isConfirmed = true;
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ✅ FINAL CONFIRM - Both sides see each other's contact
  Future<void> _confirmAndBook() async {
    if (_pickupCtrl.text.trim().isEmpty) {
      setState(() => _pickupError = 'Enter your exact pickup point');
      return;
    }

    setState(() => _isCreatingDeal = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) throw Exception('User not logged in');

      final pickupLat = _pickupLat != 0 ? _pickupLat : widget.ride.startLat;
      final pickupLng = _pickupLng != 0 ? _pickupLng : widget.ride.startLng;
      final dropLat = _dropLat != 0 ? _dropLat : widget.ride.endLat;
      final dropLng = _dropLng != 0 ? _dropLng : widget.ride.endLng;

      await firestoreService.createDeal(
        rideId: widget.ride.id,
        agreedFare: _finalAgreedFare,
        customerMessage: _messageCtrl.text.trim().isEmpty
            ? 'Booking request'
            : _messageCtrl.text.trim(),
        passengerPickupLat: pickupLat,
        passengerPickupLng: pickupLng,
        passengerPickupAddress: _pickupCtrl.text.trim(),
        passengerDropLat: dropLat,
        passengerDropLng: dropLng,
        passengerDropAddress: _dropCtrl.text.trim().isNotEmpty
            ? _dropCtrl.text.trim()
            : widget.ride.endLocation,
      );

      if (mounted) {
        AppHelpers.showSnackBar(
            context, '✅ Booking confirmed! Contact shared!');

        // ✅ Show both contacts
        await _showContactConfirmation();

        Navigator.pushReplacementNamed(context, '/my-bookings');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Booking failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isCreatingDeal = false);
    }
  }

  // ✅ Show contact confirmation dialog
  Future<void> _showContactConfirmation() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('🎉 Booking Confirmed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fare finalized! You can now contact each other directly.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.moss.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📞 Captain Contact',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text('Name: ${widget.ride.captainName}'),
                  Text(
                      'Phone: ${widget.ride.captainPhone ?? 'Available in booking'}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '👤 Passenger Contact',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text('You can see each other\'s contact in booking details'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '💰 Final Fare: Rs ${_finalAgreedFare.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.moss,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _offerCtrl.dispose();
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Widget _buildRouteMap() {
    final hasCoords =
        widget.ride.startLat != 0.0 && widget.ride.startLng != 0.0;
    final startLatLng = LatLng(
      hasCoords ? widget.ride.startLat : 31.5204,
      hasCoords ? widget.ride.startLng : 74.3587,
    );
    final endLatLng = LatLng(
      widget.ride.endLat != 0.0 ? widget.ride.endLat : 31.5404,
      widget.ride.endLng != 0.0 ? widget.ride.endLng : 74.3787,
    );

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('start'),
        position: startLatLng,
        infoWindow:
            InfoWindow(title: 'Pickup', snippet: widget.ride.startLocation),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: endLatLng,
        infoWindow: InfoWindow(title: 'Drop', snippet: widget.ride.endLocation),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: startLatLng,
            zoom: 12,
          ),
          markers: markers,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    const Icon(Icons.circle, color: AppColors.moss, size: 10),
                    Container(
                        width: 1.5,
                        height: 20,
                        color: AppColors.sage.withValues(alpha: 0.3)),
                    const Icon(Icons.circle,
                        color: AppColors.primary, size: 10),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.ride.startLocation,
                          style: const TextStyle(
                              color: AppColors.bark,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Text(widget.ride.endLocation,
                          style: const TextStyle(
                              color: AppColors.bark,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Text(
                  'Rs ${widget.ride.suggestedFare.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppColors.moss,
                      fontSize: 16,
                      fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Gradient Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
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
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final dummyUserModel = UserModel(
                              id: widget.ride.captainId,
                              email: '',
                              name: widget.ride.captainName,
                              phone: widget.ride.captainPhone ?? '',
                              role: 'captain',
                              vehicleModel: widget.ride.vehicleInfo ?? '',
                              vehicleRegistration: '',
                              vehicleSeats: widget.ride.totalSeats,
                              vehiclePhotoUrl: widget.ride.vehiclePhotoUrl,
                              captainVehicleType: widget.ride.vehicleType,
                              rating: widget.ride.captainRating,
                              totalRides: 0,
                              createdAt: DateTime.now(),
                            );
                            Navigator.pushNamed(context, '/profile',
                                arguments: dummyUserModel);
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    AppColors.white.withValues(alpha: 0.2),
                                child: Text(
                                  AppHelpers.nameInitial(
                                      widget.ride.captainName,
                                      fallback: 'C'),
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.ride.captainName,
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${widget.ride.startLocation} → ${widget.ride.endLocation}',
                                      style: TextStyle(
                                        color: AppColors.white
                                            .withValues(alpha: 0.7),
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (widget.ride.displayVehicle.isNotEmpty)
                                      Text(
                                        widget.ride.displayVehicle,
                                        style: TextStyle(
                                          color: AppColors.white
                                              .withValues(alpha: 0.85),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Rs ${widget.ride.suggestedFare}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _showMap = !_showMap),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _showMap ? Icons.chat_rounded : Icons.map_rounded,
                            color: AppColors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CoRidersSection(rideId: widget.ride.id),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: _showMap ? _buildRouteMap() : _buildChatArea(),
                ),

                // ✅ Input area - Shows pickup after fare is done
                if (!_isConfirmed && !_isFareDone)
                  _buildFareInputArea()
                else if (_isFareDone && !_isCreatingDeal)
                  _buildConfirmationArea()
                else if (_isCreatingDeal)
                  _buildLoadingArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FARE INPUT AREA
  Widget _buildFareInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
            top: BorderSide(
                color: AppColors.sage.withValues(alpha: 0.2), width: 1)),
        boxShadow: [
          BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ Show who is negotiating
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.moss.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.isCaptain
                  ? '👨‍✈️ Captain negotiating fare'
                  : '👤 Passenger negotiating fare',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.moss,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _messageCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Note for captain (optional)',
                        hintText: 'e.g. I am at the building gate',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _pickupCtrl,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        if (_pickupError != null) {
                          setState(() => _pickupError = null);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Exact pickup point',
                        hintText: 'e.g. Main gate, Block B, near pharmacy',
                        prefixIcon: Icon(Icons.place_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_pickupError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _pickupError!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dropCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Drop point',
                        hintText: 'e.g. Office entrance, Mall gate 2',
                        prefixIcon: Icon(Icons.flag_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.sage.withValues(alpha: 0.3)),
                      ),
                      child: TextField(
                        controller: _offerCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: AppColors.bark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Your offer in Rs...',
                          hintStyle: TextStyle(
                              color: AppColors.sage,
                              fontWeight: FontWeight.w500),
                          prefixText: 'Rs  ',
                          prefixStyle: TextStyle(
                            color: AppColors.bark,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isCreatingDeal
                                ? null
                                : widget.isCaptain
                                    ? _sendCaptainOffer // ✅ Captain sends offer
                                    : _acceptCaptainFare, // ✅ Customer accepts
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(
                              widget.isCaptain
                                  ? 'Send Offer'
                                  : 'Done Rs ${widget.ride.suggestedFare.toStringAsFixed(0)}',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.moss,
                              foregroundColor: AppColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isCreatingDeal
                                ? null
                                : widget.isCaptain
                                    ? _sendCaptainOffer
                                    : _sendCustomerOffer,
                            icon: const Icon(Icons.price_change_outlined),
                            label: Text(
                              widget.isCaptain ? 'Send Offer' : 'Adjust Fare',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ CONFIRMATION AREA - After fare is done
  Widget _buildConfirmationArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
            top: BorderSide(
                color: AppColors.sage.withValues(alpha: 0.2), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.moss.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.moss.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ Fare finalized: Rs ${_finalAgreedFare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.moss,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Now confirm your exact pickup location',
                  style: TextStyle(
                    color: AppColors.bark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your pickup & drop',
            style: TextStyle(
              color: AppColors.bark,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _pickupCtrl,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_pickupError != null) {
                setState(() => _pickupError = null);
              }
            },
            decoration: const InputDecoration(
              labelText: 'Exact pickup point',
              hintText: 'e.g. Main gate, Block B',
              prefixIcon: Icon(Icons.place_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          if (_pickupError != null) ...[
            const SizedBox(height: 4),
            Text(
              _pickupError!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _dropCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Drop point (if different)',
              hintText: 'e.g. Office entrance, Mall gate 2',
              prefixIcon: Icon(Icons.flag_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _messageCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Note for captain (optional)',
              hintText: 'e.g. I am at the building gate',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isCreatingDeal ? null : _confirmAndBook,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.moss,
              foregroundColor: AppColors.cream,
              minimumSize: const Size(double.infinity, 56),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isCreatingDeal
                ? const CircularProgressIndicator(color: AppColors.white)
                : const Text(
                    'Confirm & Book Ride',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
            top: BorderSide(
                color: AppColors.sage.withValues(alpha: 0.2), width: 1)),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Confirming your booking...',
              style: TextStyle(
                color: AppColors.bark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isMe;
  final bool isSystem;
  final bool isAccepted;
  final String time;

  _ChatMessage({
    required this.text,
    this.isMe = false,
    this.isSystem = false,
    this.isAccepted = false,
    required this.time,
  });
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: message.isAccepted
                  ? AppColors.moss.withValues(alpha: 0.15)
                  : AppColors.bark.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: message.isAccepted
                  ? Border.all(color: AppColors.moss.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isAccepted) ...[
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.moss, size: 16),
                  const SizedBox(width: 8),
                ],
                Text(
                  message.text,
                  style: TextStyle(
                    color: AppColors.bark,
                    fontSize: 13,
                    fontWeight:
                        message.isAccepted ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isMe ? AppColors.moss : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isMe ? 20 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 20),
          ),
          border: message.isMe
              ? null
              : Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isMe ? AppColors.white : AppColors.bark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message.time,
              style: TextStyle(
                color: message.isMe
                    ? AppColors.white.withValues(alpha: 0.6)
                    : AppColors.sage,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
