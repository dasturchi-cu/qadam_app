import 'package:flutter/material.dart';
import 'package:qadam_app/app/services/challenge_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChallengeScreen extends StatelessWidget {
  final challengeService = ChallengeService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Challengelar')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: challengeService.getChallengesStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final challenges = snapshot.data!;
          if (challenges.isEmpty) {
            return const Center(child: Text('Challengelar topilmadi.'));
          }
          return ListView.builder(
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              final isCompleted = challenge['isCompleted'] == true;
              final progress = (challenge['progress'] ?? 0.0) * 1.0;
              return ListTile(
                title: Text(challenge['title'] ?? ''),
                subtitle: Text('Target: ${challenge['targetSteps']} steps'),
                trailing:
                    isCompleted ? Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  // Misol uchun progressni yangilash (test uchun)
                  challengeService.updateChallengeProgress(
                    challenge['id'] ?? challenge['docId'] ?? '',
                    (progress + 0.1).clamp(0.0, 1.0),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
