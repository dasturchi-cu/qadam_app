import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qadam_app/app/services/step_counter_service.dart';
import 'package:qadam_app/app/services/coin_service.dart';
import 'package:qadam_app/app/services/challenge_service.dart';
import 'package:qadam_app/app/models/challenge_model.dart';
import 'package:qadam_app/app/services/auth_service.dart';
import 'package:confetti/confetti.dart';
import 'package:qadam_app/app/components/loading_widget.dart';
import 'package:qadam_app/app/components/error_widget.dart';
import 'package:qadam_app/app/utils/progress_utils.dart';
import 'package:qadam_app/app/components/app_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({Key? key}) : super(key: key);

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isClaiming = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChallengeService>(context, listen: false).fetchChallenges();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _updateChallengesProgress(List<Challenge> challenges, int currentSteps,
      ChallengeService challengeService) {
    for (var challenge in challenges) {
      if (!challenge.isCompleted && challenge.progress < 1.0) {
        final challengeModel = challengeService.challenges.firstWhere(
          (c) => c.id == challenge.id,
          orElse: () => ChallengeModel(
            id: challenge.id,
            title: challenge.title,
            description: challenge.description,
            reward: challenge.reward,
            targetSteps: 5000,
            duration: 1,
            type: 'daily',
          ),
        );

        final progress =
            calculateChallengeProgress(challengeModel, currentSteps);

        if (progress != challenge.progress) {
          challengeService.updateChallengeProgress(challenge.id, progress);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepService = Provider.of<StepCounterService>(context);
    final challengeService = Provider.of<ChallengeService>(context);
    final user = Provider.of<AuthService>(context).user;

    // Filter challenges by type
    final dailyChallenges = challengeService.challenges
        .where((c) => c.type == 'daily' && !c.isCompleted)
        .map((c) => Challenge(
              title: c.title,
              description: c.description,
              reward: c.reward,
              progress: calculateChallengeProgress(c, stepService.steps),
              isCompleted: c.isCompleted,
              icon: getIconForChallenge(c.title),
              id: c.id,
              rewardClaimed: c.rewardClaimed,
            ))
        .toList();

    final weeklyChallenges = challengeService.challenges
        .where((c) => c.type == 'weekly' && !c.isCompleted)
        .map((c) => Challenge(
              title: c.title,
              description: c.description,
              reward: c.reward,
              progress: calculateChallengeProgress(c, stepService.steps),
              isCompleted: c.isCompleted,
              icon: getIconForChallenge(c.title),
              id: c.id,
              rewardClaimed: c.rewardClaimed,
            ))
        .toList();

    final completedChallenges = challengeService.challenges
        .where((c) => c.isCompleted)
        .map((c) => Challenge(
              title: c.title,
              description: c.description,
              reward: c.reward,
              progress: 1.0,
              isCompleted: true,
              icon: getIconForChallenge(c.title),
              id: c.id,
              rewardClaimed: c.rewardClaimed,
            ))
        .toList();

    // Update progress for challenges
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateChallengesProgress(
          dailyChallenges, stepService.steps, challengeService);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Challengelar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(
              icon: Icon(Icons.today),
              text: 'mmm',
            ),
            Tab(
              icon: Icon(Icons.date_range),
              text: 'mmm',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Tugallangan',
            ),
          ],
        ),
      ),
      body: challengeService.isLoading
          ? const LoadingWidget(message: 'Challengelar yuklanmoqda...')
          : challengeService.error != null
              ? AppErrorWidget(
                  message: challengeService.error ?? 'Noma\'lum xatolik',
                  onRetry: () => challengeService.fetchChallenges(),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Container(
                        color: Colors.grey[100],
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildChallengeList(
                                dailyChallenges,
                                user,
                                challengeService,
                                'Kunlik challengelar topilmadi',
                                context),
                            _buildChallengeList(
                                weeklyChallenges,
                                user,
                                challengeService,
                                'Haftalik challengelar topilmadi',
                                context),
                            _buildChallengeList(
                                completedChallenges,
                                user,
                                challengeService,
                                'Tugallangan challengelar topilmadi',
                                context),
                          ],
                        ),
                      ),
                    ),
                    MyBannerAdWidget(),
                  ],
                ),
    );
  }

  Widget _buildChallengeList(
      List<Challenge> challenges,
      user,
      ChallengeService challengeService,
      String emptyText,
      BuildContext mainContext) {
    if (challenges.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(color: Colors.black54, fontSize: 18),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseAuth.instance.currentUser == null
              ? null
              : FirebaseFirestore.instance
                  .collection('user_challenges')
                  .doc(
                      '${FirebaseAuth.instance.currentUser!.uid}_${challenge.id}')
                  .snapshots(),
          builder: (context, snapshot) {
            final stepService = Provider.of<StepCounterService>(context);
            bool joined = false;
            double progress = 0.0;
            bool isCompleted = false;
            bool rewardClaimed = false;
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              joined = true;
              progress = (data['progress'] ?? 0.0) * 1.0;
              isCompleted = data['isCompleted'] ?? false;
              rewardClaimed = data['rewardClaimed'] ?? false;
            } else if (FirebaseAuth.instance.currentUser != null) {
              // Avtomatik qo'shish
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final challengeService = context.read<ChallengeService>();
                challengeService.joinChallenge(challenge.id);
              });
            }
            final isDone = progress >= 1.0 || isCompleted;
            print(
                'StreamBuilder: docId=${FirebaseAuth.instance.currentUser!.uid}_${challenge.id}');
            print('Firestore hujjatlari:');

            return AppCard(
              color: isDone ? Colors.green[50] : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          challenge.icon,
                          color: isDone ? Colors.green : Colors.deepPurple,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              challenge.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: isDone
                                        ? Colors.green
                                        : Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              challenge.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.black87,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  LinearProgressIndicator(
                    value: progress > 1.0 ? 1.0 : progress,
                    backgroundColor: isDone
                        ? Colors.green.withOpacity(0.15)
                        : Colors.deepPurple.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isDone ? Colors.green : Colors.deepPurple),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress: ${(progress * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDone ? Colors.green : Colors.deepPurple,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDone
                              ? Colors.green.withOpacity(0.1)
                              : Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.monetization_on,
                                color: Color(0xFFFFD700), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '+${challenge.reward}',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: () {
                          if (!joined) {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              onPressed: joined
                                  ? null
                                  : () async {
                                      final challengeService =
                                          mainContext.read<ChallengeService>();
                                      // Faqat bir marta chaqirish uchun: joined false bo'lsa chaqiramiz
                                      if (!joined) {
                                        try {
                                          await challengeService
                                              .joinChallenge(challenge.id);
                                          ScaffoldMessenger.of(mainContext)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Challengega qo\'shildingiz!')),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(mainContext)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text('Xatolik: $e')),
                                          );
                                        }
                                      }
                                    },
                              child: const Text(
                                "Qo'shish",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          } else if (isDone && !rewardClaimed) {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[800],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _isClaiming
                                  ? null
                                  : () => _onClaimReward(
                                      challenge,
                                      user,
                                      Provider.of<ChallengeService>(context,
                                          listen: false)),
                              child: _isClaiming
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text("Mukofotni olish",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                            );
                          } else if (isDone && rewardClaimed) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              child: const Text(
                                "Mukofot olingan",
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold),
                              ),
                            );
                          } else {
                            return Container();
                          }
                        }(),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showInviteFriendDialog(BuildContext context, String challengeId) {
    final _emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Do'stni taklif qilish"),
        content: TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: "Do'st emaili",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = _emailController.text.trim();
              if (email.isNotEmpty) {
                // TODO: Firestore'ga taklif yozuvi va push notification
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Taklif yuborildi: $email')),
                );
              }
            },
            child: const Text('Yuborish'),
          ),
        ],
      ),
    );
  }

  void _onClaimReward(
      Challenge challenge, user, ChallengeService challengeService) {
    setState(() {
      _isClaiming = true;
    });
    challengeService
        .claimChallengeReward(challenge.id, challenge.reward)
        .then((_) {
      // Add coins to user balance
      Provider.of<CoinService>(context, listen: false)
          .addCoins(challenge.reward);
      // Add achievement for yutuqlar
      Provider.of<CoinService>(context, listen: false)
          .addChallengeAchievement(challenge.title, challenge.reward);
      // Immediately refresh UI so challenge moves to completed tab
      setState(() {
        _isClaiming = false;
      });
      _confettiController.play();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mukofot olindi! +${challenge.reward} tanga')),
      );
    }).catchError((e) {
      setState(() {
        _isClaiming = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik yuz berdi: $e')),
      );
    });
  }

  IconData getIconForChallenge(String title) {
    if (title.contains('qadam')) return Icons.directions_walk;
    if (title.contains('do\'st')) return Icons.people;
    if (title.contains('kun')) return Icons.calendar_today;
    return Icons.emoji_events;
  }
}

class Challenge {
  final String title;
  final String description;
  final int reward;
  final double progress;
  final bool isCompleted;
  final IconData icon;
  final String id;
  final bool? rewardClaimed;

  Challenge({
    required this.title,
    required this.description,
    required this.reward,
    required this.progress,
    required this.isCompleted,
    required this.icon,
    required this.id,
    this.rewardClaimed,
  });
}

List<ChallengeModel> filterValidChallenges(List<ChallengeModel> challenges) {
  return challenges; // vaqtincha hech narsa filtrlamaydi
}

/// Progresslarni yangilash uchun utility funksiya
void updateChallengesProgress(List<ChallengeModel> challenges, int currentSteps,
    ChallengeService challengeService) {
  for (var challenge in challenges) {
    if (!challenge.isCompleted && challenge.progress < 1.0) {
      final progress = (currentSteps / challenge.targetSteps).clamp(0.0, 1.0);
      if (progress != challenge.progress) {
        challengeService.updateChallengeProgress(challenge.id, progress);
      }
    }
  }
}
