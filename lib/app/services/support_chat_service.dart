import 'package:cloud_firestore/cloud_firestore.dart';

class SupportChatService {
  final _chats = FirebaseFirestore.instance.collection('support_chats');

  Stream<List<Map<String, dynamic>>> getChats(String userId) => _chats
      .where('userId', isEqualTo: userId)
      .orderBy('timestamp')
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());

  Future<void> sendMessage(Map<String, dynamic> data) async {
    await _chats.add(data);
  }
}
