import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final _notifs = FirebaseFirestore.instance.collection('notifications');

  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) =>
      _notifs
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => d.data()).toList());
}
