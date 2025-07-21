import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  final _payments = FirebaseFirestore.instance.collection('payments');

  Stream<List<Map<String, dynamic>>> getUserPayments(String userId) => _payments
      .where('userId', isEqualTo: userId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());
}
