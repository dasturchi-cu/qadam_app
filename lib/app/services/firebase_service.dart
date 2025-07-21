import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'analytics_service.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Offline support
  static Future<void> enableOfflineSupport() async {
    await _firestore.enableNetwork();
    _firestore.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Real-time listeners boshqaruvi
  static final Map<String, StreamSubscription> _listeners = {};

  static void addListener(String key, StreamSubscription subscription) {
    _listeners[key]?.cancel();
    _listeners[key] = subscription;
  }

  static void removeListener(String key) {
    _listeners[key]?.cancel();
    _listeners.remove(key);
  }

  static void removeAllListeners() {
    _listeners.values.forEach((subscription) => subscription.cancel());
    _listeners.clear();
  }

  // Batch operations
  static Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    final batch = _firestore.batch();
    
    for (var operation in operations) {
      final type = operation['type'];
      final collection = operation['collection'];
      final docId = operation['docId'];
      final data = operation['data'];
      
      final docRef = docId != null 
          ? _firestore.collection(collection).doc(docId)
          : _firestore.collection(collection).doc();
      
      switch (type) {
        case 'set':
          batch.set(docRef, data);
          break;
        case 'update':
          batch.update(docRef, data);
          break;
        case 'delete':
          batch.delete(docRef);
          break;
      }
    }
    
    await batch.commit();
  }

  // Error handling
  static Future<T?> safeExecute<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      await AnalyticsService.logError(e.toString(), stackTrace);
      return null;
    }
  }

  // User data sync
  static Future<void> syncUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        // Yangi user yaratish
        await _firestore.collection('users').doc(userId).set({
          'uid': userId,
          'email': _auth.currentUser?.email,
          'name': _auth.currentUser?.displayName ?? 'Foydalanuvchi',
          'created_at': FieldValue.serverTimestamp(),
          'coins': 0,
          'totalSteps': 0,
          'isActive': true,
        });
      }
      
      // FCM token yangilash
      final fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      await AnalyticsService.logError('User sync error: $e', null);
    }
  }

  // Challenge progress yangilash
  static Future<void> updateChallengeProgress(String userId, int currentSteps) async {
    try {
      final activeChallenges = await _firestore
          .collection('user_challenges')
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      
      for (var doc in activeChallenges.docs) {
        final data = doc.data();
        final challengeId = data['challengeId'];
        
        // Challenge ma'lumotlarini olish
        final challengeDoc = await _firestore
            .collection('challenges')
            .doc(challengeId)
            .get();
        
        if (challengeDoc.exists) {
          final challengeData = challengeDoc.data()!;
          final targetSteps = challengeData['targetSteps'] ?? 1;
          final progress = (currentSteps / targetSteps).clamp(0.0, 1.0);
          
          batch.update(doc.reference, {
            'progress': progress,
            'currentSteps': currentSteps,
            'updated_at': FieldValue.serverTimestamp(),
          });
          
          // Challenge tugallangan bo'lsa
          if (progress >= 1.0 && !data['isCompleted']) {
            batch.update(doc.reference, {'isCompleted': true});
            
            // Reward berish
            final reward = challengeData['reward'] ?? 0;
            final userRef = _firestore.collection('users').doc(userId);
            
            batch.update(userRef, {
              'coins': FieldValue.increment(reward),
            });
            
            // Transaction yozuvi
            final transactionRef = _firestore.collection('transactions').doc();
            batch.set(transactionRef, {
              'userId': userId,
              'type': 'challenge_reward',
              'amount': reward,
              'description': 'Challenge tugallandi: ${challengeData['title']}',
              'date': FieldValue.serverTimestamp(),
            });
            
            // Analytics
            await AnalyticsService.logChallengeCompleted(
              challengeId: challengeId,
              reward: reward,
              completionTime: 1, // Bu yerda haqiqiy vaqtni hisoblash kerak
            );
          }
        }
      }
      
      await batch.commit();
    } catch (e) {
      await AnalyticsService.logError('Challenge progress update error: $e', null);
    }
  }
}