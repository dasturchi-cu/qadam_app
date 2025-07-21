import 'package:cloud_firestore/cloud_firestore.dart';

class UserChallengeService {
  final _userChallenges =
      FirebaseFirestore.instance.collection('user_challenges');

  Stream<List<Map<String, dynamic>>> getUserChallenges(String userId) =>
      _userChallenges
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((s) => s.docs.map((d) => d.data()).toList());

  Future<void> updateProgress(
      String userId, String challengeId, double progress) async {
    await _userChallenges.doc('${userId}_$challengeId').update({
      'progress': progress,
      'isCompleted': progress >= 1.0,
    });
  }
}
