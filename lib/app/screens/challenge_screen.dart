import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/challenge_service.dart';
import '../models/challenge_model.dart';
import '../services/coin_service.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge\'lar'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Consumer<ChallengeService>(
        builder: (context, challengeService, child) {
          if (challengeService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (challengeService.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Xatolik: ${challengeService.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => challengeService.loadChallenges(),
                    child: const Text('Qayta urinish'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => challengeService.loadChallenges(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildActiveChallenges(challengeService.activeChallenges),
                const SizedBox(height: 20),
                _buildCompletedChallenges(challengeService.completedChallenges),
                const SizedBox(height: 20),
                _buildAvailableChallenges(challengeService.availableChallenges),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveChallenges(List<ChallengeModel> challenges) {
    if (challenges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Faol Challenge\'lar',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...challenges.map((challenge) =>
            _buildChallengeCard(challenge, ChallengeCardType.active)),
      ],
    );
  }

  Widget _buildCompletedChallenges(List<ChallengeModel> challenges) {
    if (challenges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tugallangan Challenge\'lar',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...challenges.map((challenge) =>
            _buildChallengeCard(challenge, ChallengeCardType.completed)),
      ],
    );
  }

  Widget _buildAvailableChallenges(List<ChallengeModel> challenges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mavjud Challenge\'lar',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (challenges.isEmpty)
          const Center(
            child: Text('Hozircha mavjud challenge\'lar yo\'q'),
          )
        else
          ...challenges.map((challenge) =>
              _buildChallengeCard(challenge, ChallengeCardType.available)),
      ],
    );
  }

  Widget _buildChallengeCard(ChallengeModel challenge, ChallengeCardType type) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getChallengeTypeColor(challenge.type),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getChallengeTypeText(challenge.type),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              challenge.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.directions_walk, size: 20),
                const SizedBox(width: 8),
                Text('Maqsad: ${challenge.targetSteps} qadam'),
                const SizedBox(width: 20),
                const Icon(Icons.monetization_on,
                    size: 20, color: Colors.amber),
                const SizedBox(width: 8),
                Text('Mukofot: ${challenge.rewardCoins} tanga'),
              ],
            ),
            const SizedBox(height: 12),
            if (type == ChallengeCardType.active) ...[
              LinearProgressIndicator(
                value: challenge.progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  challenge.isCompleted
                      ? Colors.green
                      : const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(challenge.progress * 100).toInt()}% bajarildi'),
                  if (challenge.isCompleted && !challenge.rewardClaimed)
                    ElevatedButton(
                      onPressed: () => _claimReward(challenge),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Mukofot olish'),
                    ),
                ],
              ),
            ] else if (type == ChallengeCardType.completed) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '✅ Tugallandi',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (challenge.rewardClaimed)
                    const Text(
                      'Mukofot olindi',
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ] else ...[
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _startChallenge(challenge),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Boshlash'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getChallengeTypeColor(String type) {
    switch (type) {
      case 'daily':
        return const Color(0xFF4CAF50);
      case 'weekly':
        return const Color(0xFF2196F3);
      case 'monthly':
        return const Color(0xFFFFB020);
      default:
        return Colors.grey;
    }
  }

  String _getChallengeTypeText(String type) {
    switch (type) {
      case 'daily':
        return 'Kunlik';
      case 'weekly':
        return 'Haftalik';
      case 'monthly':
        return 'Oylik';
      default:
        return 'Boshqa';
    }
  }

  String _formatRemainingTime(Duration remainingTime) {
    final hours = remainingTime.inHours;
    final minutes = remainingTime.inMinutes.remainder(60);
    return '${hours} soat ${minutes} minut';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _claimReward(ChallengeModel challenge) async {
    final challengeService =
        Provider.of<ChallengeService>(context, listen: false);

    final success = await challengeService.claimReward(challenge.id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${challenge.rewardCoins} tanga muvaffaqiyatli olindi!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Mukofot olishda xatolik: ${challengeService.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startChallenge(ChallengeModel challenge) async {
    final challengeService =
        Provider.of<ChallengeService>(context, listen: false);

    final success = await challengeService.startChallenge(challenge.id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challenge muvaffaqiyatli boshlandi!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xatolik: ${challengeService.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

enum ChallengeCardType {
  active,
  completed,
  available,
}
