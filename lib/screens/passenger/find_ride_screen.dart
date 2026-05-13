import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/ride_model.dart';
import '../../services/ride_service.dart';

class _C {
  static const primary   = Color(0xFF39988E);
  static const dark      = Color(0xFF1F6059);
  static const light     = Color(0xFFB6D7D1);
  static const bg        = Color(0xFFF5F5F5);
  static const white     = Color(0xFFFFFFFF);
  static const textDark  = Color(0xFF0D1F1E);
  static const textMuted = Color(0xFF7A9E9B);
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
                  colors: [_C.dark, _C.primary],
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
                      boxShadow: [
                        BoxShadow(
                          color:      _C.dark.withOpacity(0.15),
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
                                color: _C.light,
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
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSearching ? null : _search,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _C.primary,
                              foregroundColor: _C.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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
                                      fontSize: 15, fontWeight: FontWeight.w700,
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
                  height: 36,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _types.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final t          = _types[i];
                      final isSelected = _selectedType == t;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedType = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color:        isSelected ? _C.primary : _C.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? _C.primary : _C.light,
                            ),
                          ),
                          child: Text(
                            t[0].toUpperCase() + t.substring(1),
                            style: TextStyle(
                              color:      isSelected ? _C.white : _C.textMuted,
                              fontSize:   13,
                              fontWeight: FontWeight.w600,
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
                                  color: _C.light, size: 64),
                              const SizedBox(height: 12),
                              Text(
                                'Search to find available rides',
                                style: TextStyle(
                                    color: _C.textMuted, fontSize: 14),
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
    final matchScore = 92; // wire to matching logic

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              CircleAvatar(
                radius: 20,
                backgroundColor: _C.light.withOpacity(0.5),
                child: Text(
                  (ride.captainName ?? 'C')[0].toUpperCase(),
                  style: const TextStyle(
                    color: _C.primary, fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.captainName ?? 'Captain',
                      style: const TextStyle(
                        color: _C.textDark, fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFC107), size: 14),
                        const SizedBox(width: 3),
                        Text(
                          '${ride.captainRating ?? 4.8}  •  Trust Score',
                          style: const TextStyle(
                              color: _C.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Match score badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:        _C.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$matchScore% match',
                  style: const TextStyle(
                    color:      _C.primary,
                    fontSize:   12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF0F0F0), height: 1),
          const SizedBox(height: 14),

          // Route
          Row(
            children: [
              Column(
                children: [
                  const Icon(Icons.circle, color: _C.primary, size: 10),
                  Container(
                      width: 1.5, height: 24,
                      color: _C.light),
                  Icon(Icons.circle_outlined, color: _C.primary, size: 10),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.from,
                      style: const TextStyle(
                        color: _C.textDark, fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      ride.to,
                      style: const TextStyle(
                        color: _C.textDark, fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Bottom row
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
              const SizedBox(width: 8),
              // Seats filling fast
              if ((ride.availableSeats ?? 2) <= 1)
                _RideChip(
                  icon:  Icons.local_fire_department_rounded,
                  label: 'Filling fast!',
                  isAlert: true,
                ),
              const Spacer(),
              Text(
                'Rs ${ride.offeredFare ?? '--'}',
                style: const TextStyle(
                  color:      _C.primary,
                  fontSize:   16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Book button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/fare-negotiate',
                      arguments: ride),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: _C.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Negotiate & Book',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:        isAlert
            ? Colors.orange.withOpacity(0.1)
            : _C.light.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size:  13,
            color: isAlert ? Colors.orange : _C.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color:      isAlert ? Colors.orange : _C.primary,
              fontSize:   11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}