import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final double amount;
  final DateTime date;
  final String type;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.date,
    required this.type,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      amount: map['amount'] is String
          ? double.tryParse(map['amount']) ?? 0.0
          : (map['amount'] as num).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      type: map['type'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': date,
      'type': type,
    };
  }
}
