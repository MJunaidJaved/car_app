import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'api_service.dart';

class DealChatService {
  CollectionReference<Map<String, dynamic>> _messages(String dealId) =>
      FirebaseFirestore.instance
          .collection('deals')
          .doc(dealId)
          .collection('messages');

  Stream<List<Map<String, dynamic>>> messagesStream(String dealId) {
    return _messages(dealId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
            .toList());
  }

  Future<void> sendMessage({
    required String dealId,
    required String text,
    required String senderRole,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await _messages(dealId).add({
      'senderId': uid,
      'senderRole': senderRole,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });

    try {
      await ApiService.post('/deals/$dealId/notify-message', {'text': trimmed});
    } catch (_) {}
  }

  /// Confirmed passengers on the same ride (first names only).
  Stream<List<Map<String, dynamic>>> coRidersStream(String rideId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('deals')
        .where('rideId', isEqualTo: rideId)
        .where('status', whereIn: ['confirmed', 'started', 'completed'])
        .snapshots()
        .map((snap) =>
            snap.docs.where((d) => d.data()['customerId'] != uid).map((d) {
              final data = d.data();
              final name = (data['customerName'] ?? 'Passenger').toString();
              final first = name.split(' ').first;
              final address = (data['passengerPickupAddress'] ?? '').toString();
              final area = address
                  .split(',')
                  .map((p) => p.trim())
                  .where((p) => p.isNotEmpty)
                  .toList();
              final pickupArea = area.length >= 2
                  ? area[area.length - 2]
                  : (area.isNotEmpty ? area.first : 'Along route');
              return <String, dynamic>{
                'dealId': d.id,
                'firstName': first,
                'pickupArea': pickupArea,
                'boardingStatus': data['boardingStatus'] ?? 'waiting',
                'status': data['status'],
              };
            }).toList());
  }
}
