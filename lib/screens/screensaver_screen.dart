// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import 'welcome_screen.dart';

class ScreensaverScreen extends StatefulWidget {
  const ScreensaverScreen({super.key});

  @override
  State<ScreensaverScreen> createState() => _ScreensaverScreenState();
}

class _ScreensaverScreenState extends State<ScreensaverScreen> with SingleTickerProviderStateMixin {
  Timer? _imageTimer;
  int _currentImageIndex = 0;
  int _previousImageIndex = 0;
  late AnimationController _controller;
  late Animation<Offset> _currentOffset;
  late Animation<Offset> _nextOffset;
  bool _isAnimating = false;

  // Loaded dynamically from Firestore collection `screensaver` (fields: image, name)
  List<String> _images = [];
  StreamSubscription<QuerySnapshot>? _screensaverSub;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _currentOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _nextOffset = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Subscribe to Firestore updates once
    _subscribeScreensaverImages();

    // Advance images on a timer
    _imageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isAnimating && _images.isNotEmpty) {
        _startTransition();
      }
    });
  }

  void _subscribeScreensaverImages() {
    _screensaverSub?.cancel();
    _screensaverSub = FirebaseFirestore.instance
        .collection('screensaver')
        .snapshots()
        .listen((snapshot) {
      final urls = <String>[];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final url = (data['image'] ?? '').toString();
        if (url.isNotEmpty) urls.add(url);
      }
      if (!mounted) return;
      setState(() {
        _images = urls;
        if (_images.isEmpty) {
          _currentImageIndex = 0;
          _previousImageIndex = 0;
        } else {
          _currentImageIndex = _currentImageIndex % _images.length;
          _previousImageIndex = _previousImageIndex % _images.length;
        }
      });
    });
  }

  void _startTransition() {
    if (_images.isEmpty) return;
    setState(() {
      _isAnimating = true;
      _previousImageIndex = _currentImageIndex;
      _currentImageIndex = (_currentImageIndex + 1) % _images.length;
    });
    _controller.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _isAnimating = false;
      });
    });
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _screensaverSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _exitScreensaver() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildNetworkImage(String url) {
    return Center(
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.broken_image,
          size: 80,
          color: AppColors.pink500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final double framePadding = isLandscape ? (size.width - size.height) / 2 : 0;

    return GestureDetector(
      onTap: _exitScreensaver,
      child: Scaffold(
        backgroundColor: AppColors.cream200,
        body: Stack(
          children: [
            // Pulsating icon background (from welcome_screen)
            const Positioned.fill(
              child: TiledIcons(),
            ),
            Center(
              child: AspectRatio(
                aspectRatio: 3 / 4, // or use your preferred aspect ratio
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        color: AppColors.cream200,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            if (_images.isEmpty) {
                              return Center(
                                child: Text(
                                  'No screensaver images configured',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: AppColors.pink700),
                                ),
                              );
                            }
                            return Stack(
                              children: [
                                // Previous image slides out to the left
                                SlideTransition(
                                  position: _currentOffset,
                                  child: _buildNetworkImage(_images[_previousImageIndex]),
                                ),
                                // Next image slides in from the right
                                SlideTransition(
                                  position: _nextOffset,
                                  child: _buildNetworkImage(_images[_currentImageIndex]),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Static logo in bottom right corner with white background
            Positioned(
              bottom: 24,
              right: 24,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      offset: Offset(0, 2),
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

// Pulsating icon background (copied from welcome_screen.dart)
class _PulsatingIconBackground extends StatefulWidget {
  const _PulsatingIconBackground();

  @override
  State<_PulsatingIconBackground> createState() => _PulsatingIconBackgroundState();
}

class _PulsatingIconBackgroundState extends State<_PulsatingIconBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/icons/icon-original.png',
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
