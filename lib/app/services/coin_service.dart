import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoinService extends ChangeNotifier {
  static const int STEPS_PER_COIN = 1000; // 1000 qadam = 1 tanga
  static const int DAILY_COIN_LIMIT = 100; // Kunlik maksimal tanga
  static const int LOGIN_BONUS = 10; // Kunlik kirish bonusi

  int _totalCoins = 0;
  int _todayEarned = 0;
  DateTime? _lastResetDate;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<DocumentSnapshot>? _userSubscription;
  late SharedPreferences _prefs;

  // Getters
  int get totalCoins => _totalCoins;
  int get todayEarned => _todayEarned;
  int get remainingDailyLimit => DAILY_COIN_LIMIT - _todayEarned;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CoinService() {
    _initService();
  }

  Future<void> _initService() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadLocalData();
    _checkDailyReset();
    _startListeningToUserCoins();
  }

  Future<void> _loadLocalData() async {
    _totalCoins = _prefs.getInt('totalCoins') ?? 0;
    _todayEarned = _prefs.getInt('todayEarned') ?? 0;
    final lastResetString = _prefs.getString('lastResetDate');
    if (lastResetString != null) {
      _lastResetDate = DateTime.parse(lastResetString);
    }
    notifyListeners();
  }

  void _checkDailyReset() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastResetDate == null || _lastResetDate!.isBefore(today)) {
      _todayEarned = 0;
      _lastResetDate = today;
      _saveLocalData();
      _giveLoginBonus();
    }
  }

  Future<void> _giveLoginBonus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await addCoins(LOGIN_BONUS, 'login_bonus');
      debugPrint('Kunlik kirish bonusi berildi: $LOGIN_BONUS tanga');
    } catch (e) {
      debugPrint('Login bonus xatosi: $e');
    }
  }

  // Qadamdan tanga hisoblash
  Future<int> calculateCoinsFromSteps(int steps) async {
    if (_todayEarned >= DAILY_COIN_LIMIT) return 0;

    int earnableCoins = (steps / STEPS_PER_COIN).floor();
    int actualCoins = (earnableCoins + _todayEarned > DAILY_COIN_LIMIT)
        ? DAILY_COIN_LIMIT - _todayEarned
        : earnableCoins;

    if (actualCoins > 0) {
      await addCoins(actualCoins, 'step_reward');
    }

    return actualCoins;
  }

  // Tanga qo'shish (umumiy funksiya)
  Future<void> addCoins(int amount, String source) async {
    if (amount <= 0) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Foydalanuvchi tizimga kirmagan');

    _setLoading(true);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        final userDoc = await transaction.get(userRef);

        final currentCoins = userDoc.data()?['coins'] ?? 0;

        transaction.update(userRef, {
          'coins': currentCoins + amount,
          'updated_at': FieldValue.serverTimestamp(),
        });

        // Tranzaksiya yozuvi
        final transactionRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transactions')
            .doc();

        transaction.set(transactionRef, {
          'type': source,
          'amount': amount,
          'date': FieldValue.serverTimestamp(),
          'description': _getTransactionDescription(source, amount),
        });
      });

      if (source == 'step_reward') {
        _todayEarned += amount;
        await _saveLocalData();
      }

      _clearError();
    } catch (e) {
      _setError('Tanga qo\'shishda xatolik: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Tanga sarflash
  Future<bool> spendCoins(int amount, String purpose) async {
    if (amount <= 0) return false;
    if (_totalCoins < amount) {
      _setError('Yetarli tanga yo\'q');
      return false;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    _setLoading(true);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        final userDoc = await transaction.get(userRef);

        final currentCoins = userDoc.data()?['coins'] ?? 0;

        if (currentCoins < amount) {
          throw Exception('Yetarli tanga yo\'q');
        }

        transaction.update(userRef, {
          'coins': currentCoins - amount,
          'updated_at': FieldValue.serverTimestamp(),
        });

        // Sarflash tranzaksiyasi
        final transactionRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transactions')
            .doc();

        transaction.set(transactionRef, {
          'type': 'spend',
          'amount': -amount,
          'purpose': purpose,
          'date': FieldValue.serverTimestamp(),
          'description': _getTransactionDescription('spend', amount, purpose),
        });
      });

      _clearError();
      return true;
    } catch (e) {
      _setError('Tanga sarflashda xatolik: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _startListeningToUserCoins() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        _totalCoins = data['coins'] ?? 0;
        notifyListeners();
      }
    });
  }

  String _getTransactionDescription(String type, int amount,
      [String? purpose]) {
    switch (type) {
      case 'step_reward':
        return '$amount tanga qadam mukofoti sifatida olindi';
      case 'login_bonus':
        return '$amount tanga kunlik kirish bonusi';
      case 'challenge_reward':
        return '$amount tanga challenge mukofoti';
      case 'referral_bonus':
        return '$amount tanga taklif bonusi';
      case 'spend':
        return '$amount tanga ${purpose ?? 'xarid'} uchun sarflandi';
      default:
        return '$amount tanga';
    }
  }

  Future<void> _saveLocalData() async {
    await _prefs.setInt('totalCoins', _totalCoins);
    await _prefs.setInt('todayEarned', _todayEarned);
    if (_lastResetDate != null) {
      await _prefs.setString(
          'lastResetDate', _lastResetDate!.toIso8601String());
    }
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
    _userSubscription?.cancel();
    super.dispose();
  }
}
