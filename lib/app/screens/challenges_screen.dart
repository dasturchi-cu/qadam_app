import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChallengesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Challenge\'lar'),
        backgroundColor: Color(0xFF4CAF50),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('challenges')
            .orderBy('startDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Xatolik: ${snapshot.error}'));
          }

          final challenges = snapshot.data?.docs ?? [];

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index].data() as Map<String, dynamic>;
              final challengeId = challenges[index].id;
              
              return ChallengeCard(
                challengeId: challengeId,
                challenge: challenge,
              );
            },
          );
        },
      ),
    );
  }
}

class ChallengeCard extends StatelessWidget {
  final String challengeId;
  final Map<String, dynamic> challenge;

  const ChallengeCard({
    required this.challengeId,
    required this.challenge,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge['title'] ?? 'Challenge',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(challenge['description'] ?? ''),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.directions_walk, color: Colors.blue),
                SizedBox(width: 8),
                Text('Maqsad: ${challenge['targetSteps']} qadam'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.amber),
                SizedBox(width: 8),
                Text('Mukofot: ${challenge['reward']} coin'),
              ],
            ),
            SizedBox(height: 12),
            
            // Progress bar
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('user_challenges')
                  .doc('${user?.uid}_$challengeId')
                  .snapshots(),
              builder: (context, userChallengeSnapshot) {
                double progress = 0.0;
                bool isCompleted = false;
                
                if (userChallengeSnapshot.hasData && userChallengeSnapshot.data!.exists) {
                  final data = userChallengeSnapshot.data!.data() as Map<String, dynamic>;
                  progress = (data['progress'] ?? 0.0).toDouble();
                  isCompleted = data['isCompleted'] ?? false;
                }
                
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? Colors.green : Colors.blue,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${(progress * 100).toInt()}% bajarildi'),
                        if (isCompleted)
                          Chip(
                            label: Text('Tugallandi'),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}