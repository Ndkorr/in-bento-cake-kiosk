import 'package:firebase_core/firebase_core.dart';
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
  late Future<void> _preloadFuture;

  @override
  void initState() {
    super.initState();
    _preloadFuture = _preloadResources();
  }

  Future<void> _preloadResources() async {
    // Warm up image cache size a bit for smoother scrolling
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        (PaintingBinding.instance.imageCache.maximumSizeBytes * 1.5).toInt();

    // Preload common asset images used in headers and placeholders
    // Note: requires a BuildContext; delay until first frame if needed
    await WidgetsBinding.instance.endOfFrame;
    final ctx = MyApp.navigatorKey.currentContext ?? MyApp.kioskHomeKey.currentContext;
    if (ctx != null) {
      final assets = <ImageProvider<Object>>[
        const AssetImage('assets/icons/icon-original.png'),
        const AssetImage('assets/images/cake_1.png'),
        const AssetImage('assets/images/cake_2.png'),
        const AssetImage('assets/images/cake_3.png'),
        const AssetImage('assets/images/cake_promo_1.png'),
        const AssetImage('assets/images/cake_promo_2.png'),
        const AssetImage('assets/images/cake_promo_3.png'),
      ];
      for (final ImageProvider<Object> provider in assets) {
        try {
          await precacheImage(provider, ctx);
        } catch (_) {}
      }
    }

    // Preload menuCombos network images to smooth first grid paint
    try {
      final combosSnap = await FirebaseFirestore.instance
          .collection('menuCombos')
          .orderBy('name')
          .get();
      final ctx2 = MyApp.navigatorKey.currentContext ?? ctx;
      if (ctx2 != null) {
        for (final doc in combosSnap.docs) {
          final data = doc.data();
          final img = data['image'];
          if (img is String && img.startsWith('http')) {
            try {
              await precacheImage(NetworkImage(img), ctx2);
            } catch (_) {}
          }
        }
      }
    } catch (_) {
      // ignore caching failures
    }

    // Small delay to smooth out first paint if needed
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

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
      home: FutureBuilder<void>(
        future: _preloadFuture,
        builder: (context, snapshot) {
          // Show a minimal splash while preloading
          if (snapshot.connectionState != ConnectionState.done) {
            return const _SplashScreen();
          }
          return KioskHome(key: MyApp.kioskHomeKey);
        },
      ),
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

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream200,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: AppColors.pink700),
            SizedBox(height: 12),
            Text('Loading resources...',
                style: TextStyle(color: AppColors.pink700)),
          ],
        ),
      ),
    );
  }
}
