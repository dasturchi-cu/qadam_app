import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qadam_app/app/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:qadam_app/app/services/challenge_service.dart';
import 'package:qadam_app/app/services/step_counter_service.dart'
    as step_service;
import 'package:qadam_app/app/services/coin_service.dart';
import 'package:qadam_app/app/services/auth_service.dart';
import 'package:qadam_app/app/screens/login_screen.dart';
import 'package:qadam_app/app/services/ranking_service.dart';
import 'package:qadam_app/app/services/settings_service.dart';
import 'package:qadam_app/app/services/transaction_service.dart';
import 'package:qadam_app/app/services/referral_service.dart';
import 'package:qadam_app/app/services/statistics_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:qadam_app/app/screens/register_screen.dart';
import 'package:qadam_app/app/models/challenge_model.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'qadam_channel',
  'Qadam Notifications',
  description: 'Notifications for Qadam app',
  importance: Importance.high,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  await Firebase.initializeApp();

  // FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // FCM foreground listener
  setupFcmListener();

  await setupFlutterNotifications();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(
            create: (_) => step_service.StepCounterService()),
        ChangeNotifierProvider(create: (_) => CoinService()),
        ChangeNotifierProvider(create: (_) => RankingService()),
        ChangeNotifierProvider(create: (_) => SettingsService()),
        ChangeNotifierProvider(create: (_) => ReferralService()),
        ChangeNotifierProvider(create: (_) => StatisticsService()),
        ChangeNotifierProvider(create: (_) => AchievementService()),
      ],
      child: const QadamApp(),
    ),
  );
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
  print('Background message data: ${message.data}');
  print('Background message notification: ${message.notification?.title}');
}

Future<void> saveFcmTokenToFirestore() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final fcmToken = await FirebaseMessaging.instance.getToken();
  print("FCM TOKEN $fcmToken");

  if (fcmToken != null) {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': fcmToken,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('FCM token saved successfully');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }
}

void setupFcmListener() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        await flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    }
  });

  // Handle notification tap when app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('A new onMessageOpenedApp event was published!');
    print('Message data: ${message.data}');
  });
}

Future<void> setupFlutterNotifications() async {
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Request permission
  NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');
}

// URL dan referral code ni olish
String? extractReferralCodeFromUrl(String url) {
  try {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;

    if (pathSegments.isNotEmpty &&
        pathSegments.first == 'ref' &&
        pathSegments.length > 1) {
      return pathSegments[1]; // /ref/userId formatida
    }

    // Query parameter dan ham olish mumkin
    final referralCode = uri.queryParameters['ref'];
    if (referralCode != null) {
      return referralCode;
    }

    return null;
  } catch (e) {
    print('URL parse xatolik: $e');
    return null;
  }
}

class QadamApp extends StatefulWidget {
  const QadamApp({Key? key}) : super(key: key);

  @override
  State<QadamApp> createState() => _QadamAppState();
}

class _QadamAppState extends State<QadamApp> {
  String? _referralCode;

  @override
  void initState() {
    super.initState();
    _handleInitialDynamicLink();
  }

  Future<void> _handleInitialDynamicLink() async {
    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;
    if (deepLink != null && deepLink.pathSegments.contains('ref')) {
      final referralCode = deepLink.pathSegments.last;
      // Use navigatorKey to push RegisterScreen
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => RegisterScreen(referralCode: referralCode),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final settingsService = Provider.of<SettingsService>(context);

    // FCM token saqlash foydalanuvchi tizimga kirgandan keyin
    if (authService.isLoggedIn) {
      saveFcmTokenToFirestore();
    }

    return MaterialApp(
      title: 'Qadam++',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF4CAF50),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.green,
          accentColor: const Color(0xFFFFC107),
          backgroundColor: const Color(0xFFF5F5F5),
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121)),
          displayMedium: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121)),
          bodyLarge: TextStyle(fontSize: 16.0, color: Color(0xFF424242)),
          bodyMedium: TextStyle(fontSize: 14.0, color: Color(0xFF616161)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF4CAF50),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF212121),
        colorScheme: ColorScheme.fromSwatch(
          brightness: Brightness.dark,
          primarySwatch: Colors.green,
          accentColor: const Color(0xFFFFC107),
          backgroundColor: const Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.white),
          displayMedium: TextStyle(
              fontSize: 24.0, fontWeight: FontWeight.w600, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 16.0, color: Colors.white70),
          bodyMedium: TextStyle(fontSize: 14.0, color: Colors.white60),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF4CAF50),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
        ),
      ),
      themeMode: settingsService.themeMode,
      locale: settingsService.locale,
      supportedLocales: const [
        Locale('uz'),
        Locale('ru'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: authService.isLoggedIn
          ? const SplashScreen()
          : LoginScreen(referralCode: _referralCode),
      navigatorKey: navigatorKey,
    );
  }
}

// Navigator uchun global key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
