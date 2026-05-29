import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../utils/phone_utils.dart';

class CaptainCustomerRequestsScreen extends StatefulWidget {
  const CaptainCustomerRequestsScreen({super.key});

  @override
  State<CaptainCustomerRequestsScreen> createState() =>
      _CaptainCustomerRequestsScreenState();
}

class _CaptainCustomerRequestsScreenState
    extends State<CaptainCustomerRequestsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _requests = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _loadRequests(showLoading: false),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<Position?> _position() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadRequests({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _loading = true);
    try {
      final pos = await _position();
      final res = await ApiService.get(
        '/customer-requests',
        queryParams: {
          if (pos != null) 'lat': pos.latitude.toString(),
          if (pos != null) 'lng': pos.longitude.toString(),
          if (pos != null) 'radiusKm': '20',
        },
      );
      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(res['requests'] ?? []);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _offer(String requestId) async {
    final ctrl = TextEditingController();
    final fare = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send fare offer'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Your fare offer',
            prefixText: 'Rs ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(ctrl.text.trim());
              if (value == null || value <= 0) return;
              Navigator.pop(ctx, value);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (fare == null || fare <= 0) {
      return;
    }
    try {
      await ApiService.post('/customer-requests/$requestId/offers', {
        'fare': fare,
      });
      await _loadRequests(showLoading: false);
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Offer sent to customer');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Offer failed: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Customer Requests'),
        backgroundColor: AppColors.bark,
        foregroundColor: AppColors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadRequests(showLoading: false),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: _requests.isEmpty
                    ? const [
                        SizedBox(height: 160),
                        Center(child: Text('No nearby customer requests yet.')),
                      ]
                    : _requests.map(_requestCard).toList(),
              ),
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> request) {
    final status = (request['status'] ?? '').toString();
    final customerPhone = (request['customerPhoneRevealed'] == true)
        ? (request['customerPhone'] ?? '').toString()
        : '';
    final distance = double.tryParse((request['distanceKm'] ?? '').toString());
    final distanceLabel = distance == null
        ? 'Distance unavailable'
        : distance <= 10
            ? '${distance.toStringAsFixed(1)} km away - nearby'
            : '${distance.toStringAsFixed(1)} km away';
    final requestedAt = DateTime.tryParse(
      (request['requestedAt'] ?? '').toString(),
    );
    final requestedLabel = requestedAt == null
        ? '-'
        : '${requestedAt.toLocal().day}/${requestedAt.toLocal().month}/${requestedAt.toLocal().year} ${TimeOfDay.fromDateTime(requestedAt.toLocal()).format(context)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${request['startLocation']} -> ${request['endLocation']}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          if ((request['pickupLocation'] ?? '')
              .toString()
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Exact pickup: ${request['pickupLocation']}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if ((request['dropLocation'] ?? '').toString().trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Exact drop: ${request['dropLocation']}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            distanceLabel,
            style: const TextStyle(
              color: AppColors.moss,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Time: $requestedLabel',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          if ((request['city'] ?? '').toString().trim().isNotEmpty)
            Text(
              'City: ${request['city']}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          if ((request['desiredFare'] ?? '').toString().isNotEmpty)
            Text('Customer budget Rs ${request['desiredFare']}'),
          Text(
            'Status: ${status.toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (customerPhone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Customer: $customerPhone',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => dialPhone(context, customerPhone),
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                ),
                TextButton.icon(
                  onPressed: () => openWhatsApp(context, customerPhone),
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                ),
              ],
            ),
          ],
          if (status != 'accepted') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _offer((request['id'] ?? '').toString()),
                icon: const Icon(Icons.local_offer_outlined),
                label: const Text('Send offer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.moss,
                  foregroundColor: AppColors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
