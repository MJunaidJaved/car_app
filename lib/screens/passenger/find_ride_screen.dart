import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/ride_model.dart';
import '../../services/ride_service.dart';

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

class FindRideScreen extends StatefulWidget {
  const FindRideScreen({super.key});
  @override
  State<FindRideScreen> createState() => _FindRideScreenState();
}

class _FindRideScreenState extends State<FindRideScreen> {
  final _fromCtrl = TextEditingController();
  final _toCtrl   = TextEditingController();
  String _selectedType = 'all';
  bool   _isSearching  = false;
  List<RideModel> _results = [];

  final _types = ['all', 'office', 'random', 'delivery', 'tour'];

  Future<void> _search() async {
    if (_fromCtrl.text.isEmpty || _toCtrl.text.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final rideService = Provider.of<RideService>(context, listen: false);
      final results = await rideService.findRides(
        from: _fromCtrl.text.trim(),
        to:   _toCtrl.text.trim(),
        type: _selectedType == 'all' ? null : _selectedType,
      );
      setState(() => _results = results);
    } catch (e) {
      // handle error
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 280,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.dark, Color(0xFF414833)],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
            ),
          ),

          SafeArea(
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
                            color: _C.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: _C.white, size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Find a Ride',
                        style: TextStyle(
                          color: _C.white, fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Search Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _C.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color:      Colors.black.withOpacity(0.04),
                          blurRadius: 24,
                          offset:     const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // From
                        Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: _C.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _fromCtrl,
                                style: const TextStyle(
                                  color: _C.textDark, fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  hintText:        'Pickup location',
                                  hintStyle:       TextStyle(color: _C.textMuted),
                                  border:          InputBorder.none,
                                  isDense:         true,
                                  contentPadding:  EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 2,
                                height: 24,
                                color: _C.primary.withOpacity(0.2),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                              ),
                            ],
                          ),
                        ),
                        // To
                        Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _C.primary, width: 2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _toCtrl,
                                style: const TextStyle(
                                  color: _C.textDark, fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  hintText:       'Drop location',
                                  hintStyle:      TextStyle(color: _C.textMuted),
                                  border:         InputBorder.none,
                                  isDense:        true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Search Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSearching ? null : _search,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _C.primary,
                              foregroundColor: _C.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSearching
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                      color: _C.white, strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Search Rides',
                                    style: TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Filter chips
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _types.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final t          = _types[i];
                      final isSelected = _selectedType == t;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedType = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color:        isSelected ? _C.primary : _C.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isSelected ? [BoxShadow(color: _C.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
                            border: Border.all(
                              color: isSelected ? _C.primary : const Color(0xFFCCBFA3),
                            ),
                          ),
                          child: Text(
                            t[0].toUpperCase() + t.substring(1),
                            style: TextStyle(
                              color:      isSelected ? _C.white : _C.textMuted,
                              fontSize:   13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Results
                Expanded(
                  child: _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_rounded,
                                  color: const Color(0xFF737A5D).withOpacity(0.4), size: 64),
                              const SizedBox(height: 12),
                              Text(
                                'Search to find available rides',
                                style: TextStyle(
                                    color: _C.textMuted, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: _results.length,
                          itemBuilder: (context, i) =>
                              _RideResultCard(ride: _results[i]),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RideResultCard extends StatelessWidget {
  final RideModel ride;
  const _RideResultCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    const matchScore = 92;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        _C.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.03),
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
              CircleAvatar(
                radius: 22,
                backgroundColor: _C.primary.withOpacity(0.1),
                child: Text(
                  (ride.captainName ?? 'C')[0].toUpperCase(),
                  style: const TextStyle(
                    color: _C.primary, fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.captainName ?? 'Captain',
                      style: const TextStyle(
                        color: _C.textDark, fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: _C.primary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${ride.captainRating ?? 4.8}  •  Trust Score',
                          style: const TextStyle(
                              color: _C.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:        _C.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '$matchScore% match',
                  style: TextStyle(
                    color:      _C.black,
                    fontSize:   11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFCCBFA3)),
          const SizedBox(height: 20),

          // Route
          Row(
            children: [
              Column(
                children: [
                  const Icon(Icons.circle, color: Color(0xFF4A7C59), size: 10),
                  Container(
                      width: 1.5, height: 24,
                      color: const Color(0xFFCCBFA3)),
                  const Icon(Icons.circle, color: _C.primary, size: 10),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.from,
                      style: const TextStyle(
                        color: _C.black, fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      ride.to,
                      style: const TextStyle(
                        color: _C.black, fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Chips
          Row(
            children: [
              _RideChip(
                icon:  Icons.access_time_rounded,
                label: '${ride.departureTime.hour}:${ride.departureTime.minute.toString().padLeft(2, '0')} ${ride.departureTime.hour >= 12 ? 'PM' : 'AM'}',
              ),
              const SizedBox(width: 8),
              _RideChip(
                icon:  Icons.event_seat_rounded,
                label: '${ride.availableSeats ?? 2} seats',
              ),
              const Spacer(),
              Text(
                'Rs ${ride.offeredFare ?? '--'}',
                style: const TextStyle(
                  color:      _C.primary,
                  fontSize:   18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Book button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/fare-negotiate',
                      arguments: ride),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: _C.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Negotiate & Book',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RideChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isAlert;

  const _RideChip({
    required this.icon,
    required this.label,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:        isAlert
            ? _C.primary.withOpacity(0.1)
            : _C.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size:  14,
            color: isAlert ? _C.primary : _C.black,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color:      isAlert ? _C.primary : _C.black,
              fontSize:   12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}


