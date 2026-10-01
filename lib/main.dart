import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_colors.dart';
import 'utils/idle_detector.dart';
import 'screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
      authDomain: "in-bento-kiosk.firebaseapp.com",
      projectId: "in-bento-kiosk",
      storageBucket: "in-bento-kiosk.appspot.com",
      messagingSenderId: "903181498096",
      appId: "1:903181498096:web:77a6adb884c80f1968f435",
      measurementId: "G-ZKN5VYX022",
    ),
  );
  if (kIsWeb) {
    try {
      // This web-only API supports a shared cache when multiple tabs are open.
      // ignore: deprecated_member_use
      await FirebaseFirestore.instance.enablePersistence(
        const PersistenceSettings(synchronizeTabs: true),
      );
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'Could not enable persistent Firestore cache; using memory cache: '
        '$error\n$stackTrace',
      );
    }
  }
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // Create a GlobalKey for the KioskHome state
  static final GlobalKey<_KioskHomeState> kioskHomeKey =
      GlobalKey<_KioskHomeState>();
  // Create a GlobalKey for the Navigator
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyApp.navigatorKey, // Assign the navigator key
      debugShowCheckedModeBanner: false,
      title: 'Inbento Kiosk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.pink500),
        scaffoldBackgroundColor: AppColors.cream200,
        useMaterial3: true,
      ),
      // Use the builder to wrap the app in the IdleDetector
      builder: (context, child) {
        return IdleDetector(
          navigatorKey: MyApp.navigatorKey, // Pass the key to the detector
          idleDuration: const Duration(seconds: 60),
          onIdleReturn: () {
            // Use the GlobalKey to call the reset method
            MyApp.kioskHomeKey.currentState?.resetWelcomeScreen();
          },
          child: child!,
        );
      },
      home: KioskHome(key: MyApp.kioskHomeKey),
    );
  }
}

class KioskHome extends StatefulWidget {
  const KioskHome({super.key});

  @override
  State<KioskHome> createState() => _KioskHomeState();
}

class _KioskHomeState extends State<KioskHome> {
  Key _welcomeKey = UniqueKey();
  bool _loggedIn = false;

  void resetWelcomeScreen() {
    setState(() {
      _welcomeKey = UniqueKey();
    });
  }

  void _handleContinueKiosk() {
    setState(() {
      _loggedIn = true;
    });
  }

  void _handleStaffLogin(String password) {
    // TODO: Navigate to staff screen
    // For now, just show a dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Staff Login'),
        content: const Text('Staff login successful! (Implement navigation)'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Optionally, set _loggedIn = true to go to kiosk after staff login
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loggedIn) {
      return LoginScreen(
        onContinueKiosk: _handleContinueKiosk,
        onStaffLogin: _handleStaffLogin,
      );
    }
    return WelcomeScreen(key: _welcomeKey);
  }
}
