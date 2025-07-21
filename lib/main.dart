import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qadam_app/app/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:qadam_app/app/services/challenge_service.dart';
import 'package:qadam_app/app/services/referral_service.dart';
import 'package:qadam_app/app/services/statistics_service.dart';
import 'package:qadam_app/app/services/step_counter_service.dart';
import 'package:qadam_app/app/services/coin_service.dart';
import 'package:qadam_app/app/services/auth_service.dart';
import 'package:qadam_app/app/services/ranking_service.dart';
import 'package:qadam_app/app/screens/login_screen.dart';
import 'package:qadam_app/app/screens/home_screen.dart';
import 'package:qadam_app/app/screens/challenge_screen.dart';
import 'package:qadam_app/app/screens/leaderboard_screen.dart';
import 'package:qadam_app/app/screens/shop_screen.dart';
import 'package:qadam_app/app/screens/transaction_history_screen.dart';
import 'package:qadam_app/app/screens/withdraw_screen.dart';
import 'package:qadam_app/app/screens/invite_friends_screen.dart';
import 'package:qadam_app/app/screens/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'ni ishga tushirish
  await Firebase.initializeApp();

  // Google Mobile Ads'ni ishga tushirish
  await MobileAds.instance.initialize();

  // Local notifications'ni ishga tushirish
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const QadamApp());
}

class QadamApp extends StatelessWidget {
  const QadamApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => StepCounterService()),
        ChangeNotifierProvider(create: (_) => CoinService()),
        ChangeNotifierProvider(create: (_) => ChallengeService()),
        ChangeNotifierProvider(create: (_) => RankingService()),
        ChangeNotifierProvider(create: (_) => ReferralService()),
        ChangeNotifierProvider(create: (_) => StatisticsService()),
      ],
      child: MaterialApp(
        title: 'Qadam++',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Roboto',
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/challenges': (context) => const ChallengeScreen(),
          '/shop': (context) => ShopScreen(),
          '/transactions': (context) => TransactionHistoryScreen(),
          '/withdraw': (context) => WithdrawScreen(),
          '/invite': (context) => InviteFriendsScreen(),
          '/notifications': (context) => NotificationsScreen(),
        },
      ),
    );
  }
}
