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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inbento Kiosk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.pink500),
        scaffoldBackgroundColor: AppColors.cream200,
        useMaterial3: true,
      ),
      home: const KioskHome(),
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

  void _resetWelcomeScreen() {
    setState(() {
      _welcomeKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return IdleDetector(
      idleDuration: const Duration(seconds: 30),
      onIdleReturn: _resetWelcomeScreen,
      child: WelcomeScreen(key: _welcomeKey),
    );
  }
}
