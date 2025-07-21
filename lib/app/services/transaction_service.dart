import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionService {
  final _tx = FirebaseFirestore.instance.collection('transactions');

  Stream<List<Map<String, dynamic>>> getUserTransactions(String userId) => _tx
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());

  Future<void> addTransaction(Map<String, dynamic> data) async {
    await _tx.add(data);
  }
}
