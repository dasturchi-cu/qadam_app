import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'referral_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Email va parol bilan ro'yxatdan o'tish
  Future<bool> registerWithEmail(
      String email, String password, String name) async {
    _setLoading(true);

    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await result.user!.updateDisplayName(name);
        await _createUserDocument(result.user!, name);
        _clearError();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Ro\'yxatdan o\'tishda xatolik: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Email va parol bilan kirish
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);

    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _updateLastLogin(result.user!);
        _clearError();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Kirishda xatolik: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Google bilan kirish
  Future<bool> signInWithGoogle() async {
    _setLoading(true);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result =
          await _auth.signInWithCredential(credential);

      if (result.user != null) {
        await _createUserDocument(
            result.user!, result.user!.displayName ?? 'Foydalanuvchi');
        await _updateLastLogin(result.user!);
        _clearError();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Google bilan kirishda xatolik: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Parolni tiklash
  Future<bool> resetPassword(String email) async {
    _setLoading(true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Parol tiklashda xatolik: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  //Signupwith email

  Future<bool> signUpWithEmail(String email, String password, String username,
      {String? referralCode}) async {
    _setLoading(true);

    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await result.user!.updateDisplayName(username);
        await _createUserDocument(result.user!, username);
      }

      return true;
    } catch (e) {
      print(e);

      return false;
    }
  }

  // Chiqish
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _clearError();
    } catch (e) {
      _setError('Chiqishda xatolik: $e');
    }
  }

  // Foydalanuvchi hujjatini yaratish
  Future<void> _createUserDocument(User user, String name) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'name': name,
        'email': user.email,
        'photoURL': user.photoURL,
        'coins': 0,
        'totalSteps': 0,
        'dailyGoal': 10000,
        'level': 1,
        'experience': 0,
        'joinDate': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
        'settings': {
          'notifications': true,
          'soundEnabled': true,
          'vibrationEnabled': true,
        },
      });

      // Statistika subcollection yaratish
      await userDoc.collection('stats').doc('daily').set({
        'date': FieldValue.serverTimestamp(),
        'steps': 0,
        'distance': 0.0,
        'calories': 0,
        'activeTime': 0,
      });
    }
  }

  // Oxirgi kirish vaqtini yangilash
  Future<void> _updateLastLogin(User user) async {
    await _firestore.collection('users').doc(user.uid).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  // Auth xatolik xabarlarini tarjima qilish
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Bunday foydalanuvchi topilmadi';
      case 'wrong-password':
        return 'Noto\'g\'ri parol';
      case 'email-already-in-use':
        return 'Bu email allaqachon ishlatilmoqda';
      case 'weak-password':
        return 'Parol juda zaif';
      case 'invalid-email':
        return 'Noto\'g\'ri email format';
      case 'user-disabled':
        return 'Foydalanuvchi hisobi o\'chirilgan';
      case 'too-many-requests':
        return 'Juda ko\'p urinish. Keyinroq qayta urining';
      case 'operation-not-allowed':
        return 'Bu operatsiya ruxsat etilmagan';
      default:
        return 'Noma\'lum xatolik yuz berdi';
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
}

class AchievementService extends ChangeNotifier {
  List<AchievementModel> _achievements = [];
  bool _isLoading = false;
  String? _error;

  List<AchievementModel> get achievements => _achievements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAchievements(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .orderBy('date', descending: true)
          .get();
      _achievements = snapshot.docs
          .map((doc) => AchievementModel.fromMap(doc.data(), doc.id))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addAchievement(
      String userId, AchievementModel achievement) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .add(achievement.toMap());
      await fetchAchievements(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
