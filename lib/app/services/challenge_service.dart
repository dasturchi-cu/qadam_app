import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/challenge_model.dart';
import 'coin_service.dart';

class ChallengeService extends ChangeNotifier {
  final List<ChallengeModel> _activeChallenges = [];
  final List<ChallengeModel> _completedChallenges = [];
  final List<ChallengeModel> _availableChallenges = [];

  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<QuerySnapshot>? _challengesSubscription;
  StreamSubscription<QuerySnapshot>? _userChallengesSubscription;

  // Getters
  List<ChallengeModel> get activeChallenges => _activeChallenges;
  List<ChallengeModel> get completedChallenges => _completedChallenges;
  List<ChallengeModel> get availableChallenges => _availableChallenges;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ChallengeService() {
    _initService();
  }

  Future<void> _initService() async {
    await loadChallenges();
    _startListeningToChallenges();
  }

  Future<void> loadChallenges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _setLoading(true);

    try {
      await _loadAvailableChallenges();
      await _loadUserChallenges(user.uid);
      _clearError();
    } catch (e) {
      _setError('Challenge\'lar yuklanmadi: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadAvailableChallenges() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('challenges')
        .where('isActive', isEqualTo: true)
        .orderBy('priority', descending: true)
        .get();

    _availableChallenges.clear();
    for (var doc in snapshot.docs) {
      _availableChallenges.add(ChallengeModel.fromFirestore(doc));
    }
  }

  Future<void> _loadUserChallenges(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('user_challenges')
        .where('userId', isEqualTo: userId)
        .get();

    _activeChallenges.clear();
    _completedChallenges.clear();

    for (var doc in snapshot.docs) {
      final challenge = ChallengeModel.fromFirestore(doc);

      if (challenge.isCompleted) {
        _completedChallenges.add(challenge);
      } else if (challenge.isActive) {
        _activeChallenges.add(challenge);
      }
    }
  }

  Future<bool> startChallenge(String challengeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    _setLoading(true);

    try {
      final challengeDoc = await FirebaseFirestore.instance
          .collection('challenges')
          .doc(challengeId)
          .get();

      if (!challengeDoc.exists) {
        throw Exception('Challenge topilmadi');
      }

      final challengeData = challengeDoc.data()!;

      await FirebaseFirestore.instance
          .collection('user_challenges')
          .doc('${user.uid}_$challengeId')
          .set({
        'userId': user.uid,
        'challengeId': challengeId,
        'title': challengeData['title'],
        'description': challengeData['description'],
        'targetSteps': challengeData['targetSteps'],
        'rewardCoins': challengeData['rewardCoins'],
        'type': challengeData['type'],
        'progress': 0.0,
        'currentSteps': 0,
        'isActive': true,
        'isCompleted': false,
        'rewardClaimed': false,
        'startDate': FieldValue.serverTimestamp(),
        'endDate': _calculateEndDate(challengeData['type']),
        'created_at': FieldValue.serverTimestamp(),
      });

      await loadChallenges();
      _clearError();
      return true;
    } catch (e) {
      _setError('Challenge boshlanmadi: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateChallengeProgress(
      String challengeId, double currentSteps) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('user_challenges')
          .doc('${user.uid}_$challengeId');

      final doc = await docRef.get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final targetSteps = data['targetSteps'] as int;
      final progress = (currentSteps / targetSteps).clamp(0.0, 1.0);
      final isCompleted = progress >= 1.0;

      await docRef.update({
        'progress': progress,
        'currentSteps': currentSteps.toInt(),
        'isCompleted': isCompleted,
        'completedDate': isCompleted ? FieldValue.serverTimestamp() : null,
      });

      if (isCompleted) {
        final challenge = ChallengeModel.fromFirestore(doc);
        await _giveReward(challenge);
      }

      return true;
    } catch (e) {
      _setError('Progress yangilanmadi: $e');
      return false;
    }
  }

  Future<bool> claimReward(String challengeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('user_challenges')
          .doc('${user.uid}_$challengeId');

      final doc = await docRef.get();
      if (!doc.exists) return false;

      final challenge = ChallengeModel.fromFirestore(doc);

      if (!challenge.isCompleted || challenge.rewardClaimed) {
        return false;
      }

      await _giveReward(challenge);
      return true;
    } catch (e) {
      _setError('Mukofot olinmadi: $e');
      return false;
    }
  }

  Future<void> _giveReward(ChallengeModel challenge) async {
    try {
      final coinService = CoinService();
      await coinService.addCoins(challenge.rewardCoins)

      await FirebaseFirestore.instance
          .collection('user_challenges')
          .doc('${FirebaseAuth.instance.currentUser!.uid}_${challenge.id}')
          .update({
        'rewardClaimed': true,
        'rewardClaimedDate': FieldValue.serverTimestamp(),
      });

      debugPrint('Challenge mukofoti berildi: ${challenge.rewardCoins} tanga');
    } catch (e) {
      debugPrint('Mukofot berishda xatolik: $e');
    }
  }

  void _startListeningToChallenges() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userChallengesSubscription = FirebaseFirestore.instance
        .collection('user_challenges')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      _activeChallenges.clear();
      _completedChallenges.clear();

      for (var doc in snapshot.docs) {
        final challenge = ChallengeModel.fromFirestore(doc);

        if (challenge.isCompleted) {
          _completedChallenges.add(challenge);
        } else if (challenge.isActive) {
          _activeChallenges.add(challenge);
        }
      }

      notifyListeners();
    });

    _challengesSubscription = FirebaseFirestore.instance
        .collection('challenges')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      _availableChallenges.clear();

      for (var doc in snapshot.docs) {
        _availableChallenges.add(ChallengeModel.fromFirestore(doc));
      }

      notifyListeners();
    });
  }

  Timestamp _calculateEndDate(String type) {
    final now = DateTime.now();
    DateTime endDate;

    switch (type) {
      case 'daily':
        endDate = DateTime(now.year, now.month, now.day + 1);
        break;
      case 'weekly':
        endDate = now.add(const Duration(days: 7));
        break;
      case 'monthly':
        endDate = DateTime(now.year, now.month + 1, now.day);
        break;
      default:
        endDate = now.add(const Duration(days: 1));
    }

    return Timestamp.fromDate(endDate);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _challengesSubscription?.cancel();
    _userChallengesSubscription?.cancel();
    super.dispose();
  }
}

class MyBannerAdWidget extends StatefulWidget {
  const MyBannerAdWidget({Key? key}) : super(key: key);

  @override
  State<MyBannerAdWidget> createState() => _MyBannerAdWidgetState();
}

class _MyBannerAdWidgetState extends State<MyBannerAdWidget> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7180097986291909/1830667352',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() {}),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd == null) {
      return const SizedBox.shrink();
    }
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
