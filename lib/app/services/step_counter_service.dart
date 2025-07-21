import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StepCounterService extends ChangeNotifier {
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  Timer? _syncTimer;
  int _steps = 0;
  String _status = 'unknown';
  Stream<StepCount>? _stepCountStream;
  late SharedPreferences _prefs;

  int _dailyGoal = 10000;
  DateTime? _lastResetDate;

  StepCounterService() {
    _initPrefs();
  }

  int get steps => _steps;
  int get dailyGoal => _prefs.getInt('dailyGoal') ?? 10000;
  String get status => _status;

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSteps();
    _loadGoal();
    _checkForDailyReset();
  }

  Future<void> _loadSteps() async {
    _steps = _prefs.getInt('steps') ?? 0;
    final lastResetString = _prefs.getString('lastResetDate');
    if (lastResetString != null) {
      _lastResetDate = DateTime.parse(lastResetString);
    }
    notifyListeners();
  }

  Future<void> _loadGoal() async {
    _dailyGoal = _prefs.getInt('dailyGoal') ?? 10000;
    notifyListeners();
  }

  Future<void> setDailyGoal(int goal) async {
    _dailyGoal = goal;
    await _prefs.setInt('dailyGoal', goal);
    notifyListeners();
  }

  Future<void> _saveSteps() async {
    await _prefs.setInt('steps', _steps);
    await _prefs.setString('lastResetDate', DateTime.now().toIso8601String());
  }

  Future<void> _checkForDailyReset() async {
    if (_lastResetDate == null) {
      _lastResetDate = DateTime.now();
      await _prefs.setString(
          'lastResetDate', _lastResetDate!.toIso8601String());
      return;
    }

    final now = DateTime.now();
    final lastMidnight = DateTime(now.year, now.month, now.day);
    final resetMidnight = DateTime(
      _lastResetDate!.year,
      _lastResetDate!.month,
      _lastResetDate!.day,
    );

    if (lastMidnight.isAfter(resetMidnight)) {
      // New day, reset steps
      _steps = 0;
      _lastResetDate = now;
      await _saveSteps();
      notifyListeners();
    }
  }

  void startCounting() {
    _setupPedometer();
    _status = 'counting';
    notifyListeners();
  }

  void stopCounting() {
    _status = 'stopped';
    notifyListeners();
  }

  void _setupPedometer() {
    _stepCountSubscription?.cancel();
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountSubscription = _stepCountStream?.listen(_onStepCount);
  }

  void _onStepCount(StepCount event) async {
    final previousSteps = _steps;
    _steps = event.steps;

    // Faqat qadamlar oshganda saqlash
    if (_steps > previousSteps) {
      await _saveSteps();
      _scheduleSyncWithFirestore();
    }

    notifyListeners();
  }

  void _onStepCountError(error) {
    _status = 'error: $error';
    debugPrint('Step counter error: $error');
    notifyListeners();
  }

  // For testing or manual entry
  void addSteps(int count) {
    _steps += count;
    _saveSteps();
    syncStepsWithFirestore();
    notifyListeners();
  }

  void resetSteps() {
    _steps = 0;
    _saveSteps();
    notifyListeners();
  }

  // Sinxronizatsiya: lokal qadamlarni Firestore bilan bir xil qilish
  Future<void> syncStepsWithFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final statsDoc = userDoc
          .collection('stats')
          .doc(DateTime.now().toIso8601String().substring(0, 10));
      // Firestore'dan mavjud qadamlarni olish
      final snapshot = await statsDoc.get();
      int firestoreSteps = 0;
      if (snapshot.exists) {
        firestoreSteps = snapshot.data()?['steps'] ?? 0;
      }
      // Agar lokal qadamlar ko'proq bo'lsa, Firestore'ga yozamiz
      if (_steps > firestoreSteps) {
        await statsDoc.set({
          'day': DateTime.now().weekday,
          'steps': _steps,
          'coins': 0, // coins logikasi CoinService'da
          'date': DateTime.now(),
        }, SetOptions(merge: true));
      } else if (firestoreSteps > _steps) {
        // Agar Firestore ko'proq bo'lsa, lokalga yozamiz
        _steps = firestoreSteps;
        await _saveSteps();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Sync error: $e');
      // Error reporting service'ga yuborish
      _status = 'sync_error';
      notifyListeners();
    }
  }

  Future<void> _updateAllChallengeProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userChallenges = await FirebaseFirestore.instance
        .collection('user_challenges')
        .where('userId', isEqualTo: user.uid)
        .get();
    for (var doc in userChallenges.docs) {
      final data = doc.data();
      final challengeId = data['challengeId'];
      final targetSteps = await _getChallengeTargetSteps(challengeId);
      if (targetSteps > 0) {
        final progress = (_steps / targetSteps).clamp(0.0, 1.0);
        await FirebaseFirestore.instance
            .collection('user_challenges')
            .doc('${user.uid}_$challengeId')
            .update({'progress': progress, 'isCompleted': progress >= 1.0});
      }
    }
  }

  Future<int> _getChallengeTargetSteps(String challengeId) async {
    final doc = await FirebaseFirestore.instance
        .collection('challenges')
        .doc(challengeId)
        .get();
    if (doc.exists) {
      return doc.data()?['targetSteps'] ?? 0;
    }
    return 0;
  }

  // Real-time Firestore listener qo'shish
  void _setupFirestoreListener() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('daily_stats')
        .doc(today)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final firestoreSteps = data?['steps'] ?? 0;

        // Agar Firestore'dagi qadamlar ko'proq bo'lsa, lokalga yangilash
        if (firestoreSteps > _steps) {
          _steps = firestoreSteps;
          _saveSteps();
          notifyListeners();
        }
      }
    });
  }

  // Batch sync - har 30 soniyada
  void _scheduleSyncWithFirestore() {
    _syncTimer?.cancel();
    _syncTimer = Timer(Duration(seconds: 30), () {
      syncStepsWithFirestore();
    });
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _firestoreSubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
