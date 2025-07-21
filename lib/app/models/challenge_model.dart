import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qadam_app/app/services/step_counter_service.dart'
    as step_service;
import 'package:qadam_app/app/services/challenge_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Challenge model
class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final int targetSteps;
  final int rewardCoins;
  final String type; // daily, weekly, monthly
  final double progress;
  final int currentSteps;
  final bool isActive;
  final bool isCompleted;
  final bool rewardClaimed;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? completedDate;
  final int priority;
  final String? iconUrl;

  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetSteps,
    required this.rewardCoins,
    required this.type,
    this.progress = 0.0,
    this.currentSteps = 0,
    this.isActive = true,
    this.isCompleted = false,
    this.rewardClaimed = false,
    this.startDate,
    this.endDate,
    this.completedDate,
    this.priority = 0,
    this.iconUrl,
  });

  factory ChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      targetSteps: data['targetSteps'] ?? 0,
      rewardCoins: data['rewardCoins'] ?? 0,
      type: data['type'] ?? 'daily',
      progress: (data['progress'] ?? 0.0).toDouble(),
      currentSteps: data['currentSteps'] ?? 0,
      isActive: data['isActive'] ?? true,
      isCompleted: data['isCompleted'] ?? false,
      rewardClaimed: data['rewardClaimed'] ?? false,
      startDate: data['startDate']?.toDate(),
      endDate: data['endDate']?.toDate(),
      completedDate: data['completedDate']?.toDate(),
      priority: data['priority'] ?? 0,
      iconUrl: data['iconUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetSteps': targetSteps,
      'rewardCoins': rewardCoins,
      'type': type,
      'progress': progress,
      'currentSteps': currentSteps,
      'isActive': isActive,
      'isCompleted': isCompleted,
      'rewardClaimed': rewardClaimed,
      'startDate': startDate,
      'endDate': endDate,
      'completedDate': completedDate,
      'priority': priority,
      'iconUrl': iconUrl,
    };
  }
}

// Progress update function
void updateChallengesProgress(List<ChallengeModel> challenges, int currentSteps,
    ChallengeService service) {
  for (var challenge in challenges) {
    if (!challenge.isCompleted && challenge.progress < 1.0) {
      final progress = (currentSteps / challenge.targetSteps).clamp(0.0, 1.0);
      if (progress != challenge.progress) {
        service.updateChallengeProgress(challenge.id, currentSteps.toDouble());
      }
    }
  }
}

// Main App Widget - FIXED VERSION
class MyChallengeScreen extends StatelessWidget {
  const MyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        backgroundColor: Colors.blue[600],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_challenges')
            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No challenges found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final challengeDoc = snapshot.data!.docs[index];
              final challengeData = challengeDoc.data() as Map<String, dynamic>;
              final challengeId = challengeDoc.id;

              final progress = (challengeData['progress'] ?? 0.0).toDouble();
              final isCompleted = challengeData['isCompleted'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCompleted ? Colors.green : Colors.blue,
                    child: Icon(
                      isCompleted ? Icons.check : Icons.flag,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(challengeData['title'] ?? 'Challenge'),
                  subtitle: Text(
                    '${(progress * 100).toStringAsFixed(1)}% completed',
                  ),
                  trailing: isCompleted
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : Icon(Icons.play_arrow, color: Colors.blue[600]),
                  onTap: () {
                    debugPrint('Challenge tapped: $challengeId');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// App Entry Point
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => step_service.StepCounterService()),
        Provider<ChallengeService>(
          create: (_) => ChallengeService(),
        ),
      ],
      child: const MaterialApp(
        home: MyChallengeScreen(),
      ),
    ),
  );
}
