import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_colors.dart';
import 'utils/idle_detector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Create a GlobalKey for the KioskHome state
  static final GlobalKey<_KioskHomeState> kioskHomeKey =
      GlobalKey<_KioskHomeState>();
  // Create a GlobalKey for the Navigator
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Assign the navigator key
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
          navigatorKey: navigatorKey, // Pass the key to the detector
          idleDuration: const Duration(seconds: 60),
          onIdleReturn: () {
            // Use the GlobalKey to call the reset method
            kioskHomeKey.currentState?.resetWelcomeScreen();
          },
          child: child!,
        );
      },
      home: KioskHome(key: kioskHomeKey),
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

  void resetWelcomeScreen() {
    setState(() {
      _welcomeKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    // The IdleDetector is no longer here
    return WelcomeScreen(key: _welcomeKey);
  }
}
