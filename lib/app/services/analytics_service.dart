import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // User Properties
  static Future<void> setUserProperties({
    required String userId,
    required String userType,
    int? totalSteps,
    int? totalCoins,
  }) async {
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(name: 'user_type', value: userType);
    if (totalSteps != null) {
      await _analytics.setUserProperty(name: 'total_steps', value: totalSteps.toString());
    }
    if (totalCoins != null) {
      await _analytics.setUserProperty(name: 'total_coins', value: totalCoins.toString());
    }
  }

  // Step Events
  static Future<void> logStepEvent({
    required int steps,
    required int dailyGoal,
  }) async {
    await _analytics.logEvent(
      name: 'step_count_updated',
      parameters: {
        'steps': steps,
        'daily_goal': dailyGoal,
        'goal_percentage': ((steps / dailyGoal) * 100).round(),
      },
    );
  }

  // Challenge Events
  static Future<void> logChallengeStarted({
    required String challengeId,
    required String challengeType,
    required int targetSteps,
  }) async {
    await _analytics.logEvent(
      name: 'challenge_started',
      parameters: {
        'challenge_id': challengeId,
        'challenge_type': challengeType,
        'target_steps': targetSteps,
      },
    );
  }

  static Future<void> logChallengeCompleted({
    required String challengeId,
    required int reward,
    required int completionTime,
  }) async {
    await _analytics.logEvent(
      name: 'challenge_completed',
      parameters: {
        'challenge_id': challengeId,
        'reward': reward,
        'completion_time_days': completionTime,
      },
    );
  }

  // Purchase Events
  static Future<void> logPurchase({
    required String itemId,
    required String itemName,
    required int cost,
    required String currency,
  }) async {
    await _analytics.logPurchase(
      currency: currency,
      value: cost.toDouble(),
      parameters: {
        'item_id': itemId,
        'item_name': itemName,
        'item_category': 'shop_item',
      },
    );
  }

  // Referral Events
  static Future<void> logReferralInvite({
    required String inviteMethod,
  }) async {
    await _analytics.logEvent(
      name: 'referral_invite_sent',
      parameters: {
        'method': inviteMethod,
      },
    );
  }

  static Future<void> logReferralSuccess({
    required int reward,
  }) async {
    await _analytics.logEvent(
      name: 'referral_successful',
      parameters: {
        'reward': reward,
      },
    );
  }

  // Withdrawal Events
  static Future<void> logWithdrawalRequest({
    required int amount,
    required String method,
  }) async {
    await _analytics.logEvent(
      name: 'withdrawal_requested',
      parameters: {
        'amount': amount,
        'method': method,
      },
    );
  }

  // Error Logging
  static Future<void> logError(String error, StackTrace? stackTrace) async {
    await _crashlytics.recordError(error, stackTrace);
  }

  // Custom Events
  static Future<void> logCustomEvent(String eventName, Map<String, dynamic> parameters) async {
    await _analytics.logEvent(name: eventName, parameters: parameters);
  }
}