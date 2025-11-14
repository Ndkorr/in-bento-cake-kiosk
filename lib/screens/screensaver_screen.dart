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
    'assets/images/cake_promo_1.png',
    'assets/images/cake_promo_2.png',
    'assets/images/cake_promo_3.png',
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
            // Background with sliding images
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 1500),
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(position: offsetAnimation, child: child);
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

            // Static logo in bottom right corner (no white background)
            Positioned(
              bottom: 24,
              right: 24,
              child: SizedBox(
                width: 120,
                height: 120,
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
