import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _users = FirebaseFirestore.instance.collection('users');

  Stream<List<Map<String, dynamic>>> getUsersStream() =>
      _users.snapshots().map((s) => s.docs.map((d) => d.data()).toList());

  Future<void> addUser(String userId, String name, String email) async {
    await _users.doc(userId).set({
      'name': name,
      'email': email,
      'created_at': FieldValue.serverTimestamp(),
      'coins': 0,
      'steps': 0,
      'isAdmin': false,
    });
  }

  Future<void> updateUserCoins(String userId, int coins) async {
    await _users.doc(userId).update({'coins': coins});
  }
}
