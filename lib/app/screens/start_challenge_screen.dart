import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/analytics_service.dart';

class StartChallengeScreen extends StatefulWidget {
  @override
  _StartChallengeScreenState createState() => _StartChallengeScreenState();
}

class _StartChallengeScreenState extends State<StartChallengeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Challenge Boshlash'),
        backgroundColor: Color(0xFF4CAF50),
      ),
      body: Column(
        children: [
          _buildActiveChallenge(),
          Expanded(child: _buildAvailableChallenges()),
        ],
      ),
    );
  }

  Widget _buildActiveChallenge() {
    final user = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('startChallenge')
          .where('user_id', isEqualTo: user?.uid)
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SizedBox();
        }

        final activeChallenge = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        
        return Card(
          margin: EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.play_circle_filled, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Faol Challenge',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text('Maqsad: ${activeChallenge['target']} qadam'),
                SizedBox(height: 4),
                Text('Boshlangan: ${_formatDate(activeChallenge['startDate'])}'),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (activeChallenge['progress'] ?? 0.0).toDouble(),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvailableChallenges() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('challenges')
          .where('isCompleted', isEqualTo: false)
          .orderBy('startDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final challenges = snapshot.data?.docs ?? [];

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index].data() as Map<String, dynamic>;
            final challengeId = challenges[index].id;
            
            return AvailableChallengeCard(
              challengeId: challengeId,
              challenge: challenge,
            );
          },
        );
      },
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    DateTime dateTime = (date as Timestamp).toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class AvailableChallengeCard extends StatelessWidget {
  final String challengeId;
  final Map<String, dynamic> challenge;

  const AvailableChallengeCard({
    required this.challengeId,
    required this.challenge,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    challenge['title'] ?? 'Challenge',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(challenge['type'] ?? 'daily'),
                  backgroundColor: Colors.green[100],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(challenge['description'] ?? ''),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.directions_walk, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text('${challenge['targetSteps']} qadam'),
                SizedBox(width: 20),
                Icon(Icons.monetization_on, size: 20, color: Colors.amber),
                SizedBox(width: 8),
                Text('${challenge['reward']} coin'),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  '${challenge['duration']} kun',
                  style: TextStyle(color: Colors.grey),
                ),
                Spacer(),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('startChallenge')
                      .where('user_id', isEqualTo: user?.uid)
                      .where('challenge_id', isEqualTo: challengeId)
                      .where('status', isEqualTo: 'active')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final hasActiveChallenge = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                    
                    return ElevatedButton(
                      onPressed: hasActiveChallenge ? null : () => _startChallenge(context, challengeId),
                      child: Text(hasActiveChallenge ? 'Faol' : 'Boshlash'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasActiveChallenge ? Colors.grey : Color(0xFF4CAF50),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startChallenge(BuildContext context, String challengeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Faol challenge borligini tekshirish
      final activeChallenge = await FirebaseFirestore.instance
          .collection('startChallenge')
          .where('user_id', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .get();

      if (activeChallenge.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sizda allaqachon faol challenge bor!')),
        );
        return;
      }

      // Yangi challenge boshlash
      await FirebaseFirestore.instance.collection('startChallenge').add({
        'user_id': user.uid,
        'challenge_id': challengeId,
        'status': 'active',
        'progress': 0.0,
        'target': challenge['targetSteps'],
        'startDate': FieldValue.serverTimestamp(),
      });

      // User challenges collection'ga ham qo'shish
      await FirebaseFirestore.instance
          .collection('user_challenges')
          .doc('${user.uid}_$challengeId')
          .set({
        'userId': user.uid,
        'challengeId': challengeId,
        'progress': 0.0,
        'isCompleted': false,
        'rewardClaimed': false,
        'startDate': FieldValue.serverTimestamp(),
      });

      // Analytics
      await AnalyticsService.logChallengeStarted(
        challengeId: challengeId,
        challengeType: challenge['type'] ?? 'daily',
        targetSteps: challenge['targetSteps'] ?? 0,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Challenge muvaffaqiyatli boshlandi!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e')),
      );
    }
  }
}