import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/phone_utils.dart';

class CaptainCustomerRequestsScreen extends StatefulWidget {
  const CaptainCustomerRequestsScreen({super.key});

  @override
  State<CaptainCustomerRequestsScreen> createState() => _CaptainCustomerRequestsScreenState();
}

class _CaptainCustomerRequestsScreenState extends State<CaptainCustomerRequestsScreen> {
  final _fareCtrl = TextEditingController();
  bool _loading = true;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _fareCtrl.dispose();
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

  Future<void> _loadRequests() async {
    try {
      final pos = await _position();
      final res = await ApiService.get('/customer-requests', queryParams: {
        if (pos != null) 'lat': pos.latitude.toString(),
        if (pos != null) 'lng': pos.longitude.toString(),
      });
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
    final fare = double.tryParse(_fareCtrl.text.trim());
    if (fare == null || fare <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valid fare likhein')));
      return;
    }
    try {
      await ApiService.post('/customer-requests/$requestId/offers', {'fare': fare});
      _fareCtrl.clear();
      await _loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer sent to customer')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Offer failed: $e')));
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
        onRefresh: _loadRequests,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${request['startLocation']} -> ${request['endLocation']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Time: ${request['requestedAt'] ?? '-'}', style: const TextStyle(color: AppColors.textMuted)),
          if ((request['desiredFare'] ?? '').toString().isNotEmpty)
            Text('Customer budget Rs ${request['desiredFare']}'),
          Text('Status: ${status.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w700)),
          if (customerPhone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Customer: $customerPhone', style: const TextStyle(fontWeight: FontWeight.w800)),
            Row(children: [
              TextButton.icon(onPressed: () => dialPhone(context, customerPhone), icon: const Icon(Icons.call), label: const Text('Call')),
              TextButton.icon(onPressed: () => openWhatsApp(context, customerPhone), icon: const Icon(Icons.chat), label: const Text('WhatsApp')),
            ]),
          ],
          if (status != 'accepted') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _fareCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Your fare offer'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _offer((request['id'] ?? '').toString()),
                icon: const Icon(Icons.local_offer_outlined),
                label: const Text('Send offer'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.moss, foregroundColor: AppColors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
