// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_colors.dart';

class ScreensaverScreen extends StatefulWidget {
  const ScreensaverScreen({super.key});

  @override
  State<ScreensaverScreen> createState() => _ScreensaverScreenState();
}

class _ScreensaverScreenState extends State<ScreensaverScreen> {
  Timer? _imageTimer;
  int _currentImageIndex = 0;

  final List<String> _images = [
    'assets/images/cake_1.png',
    'assets/images/cake_2.png',
    'assets/images/cake_3.png',
  ];

  @override
  void initState() {
    super.initState();

    _imageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _images.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    super.dispose();
  }

  void _exitScreensaver() {
    // Pop back to the root (WelcomeScreen with IdleDetector)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _exitScreensaver,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Background with sliding images - no darkening
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 1500),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Container(
                key: ValueKey<int>(_currentImageIndex),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(_images[_currentImageIndex]),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      debugPrint(
                        'Error loading image: ${_images[_currentImageIndex]}',
                      );
                    },
                  ),
                ),
              ),
            ),

            // Static logo in bottom right corner
            Positioned(
              bottom: 24,
              right: 24,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'assets/icons/icon-original.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.cake,
                    size: 80,
                    color: AppColors.pink500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
