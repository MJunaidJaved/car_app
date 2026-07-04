import 'package:cloud_firestore/cloud_firestore.dart';

class WalletModel {
  final String id;
  final String userId;
  final double balance;
  final DateTime updatedAt;

  WalletModel({
    required this.id,
    required this.userId,
    required this.balance,
    required this.updatedAt,
  });

  factory WalletModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return WalletModel.fromMap(data, doc.id);
  }

  factory WalletModel.fromMap(Map<String, dynamic> data, [String? id]) {
    return WalletModel(
      id: id ?? data['id']?.toString() ?? data['userId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      balance: (data['balance'] ?? 0.0).toDouble(),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'balance': balance,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class TransactionModel {
  final String id;
  final String walletId;
  final String type; // 'topup', 'deduction', 'refund'
  final double amount;
  final String reference;
  final String? description;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.reference,
    this.description,
    required this.createdAt,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      walletId: data['walletId'] ?? '',
      type: data['type'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      reference: data['reference'] ?? '',
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'walletId': walletId,
      'type': type,
      'amount': amount,
      'reference': reference,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
