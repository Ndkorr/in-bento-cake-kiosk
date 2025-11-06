import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'menu_screen.dart'; 

class LoadingOverlay extends StatefulWidget {
  const LoadingOverlay({super.key, required this.orderType});

  final String orderType; // 'Dine In' or 'Takeout'

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<IconData> _cakeIcons = [
    Icons.cake,
    Icons.emoji_food_beverage,
    Icons.cookie,
    Icons.shopping_bag,
    Icons.local_cafe,
    Icons.restaurant,
    Icons.egg,
    Icons.sell,
    Icons.table_bar,
    

  ];

  final List<Color> _iconColors = [
    AppColors.pink700,
    AppColors.pink500,
    AppColors.salmon400,
    AppColors.peach300,
    AppColors.cream200,
    Colors.white,
  ];

  final List<int> _iconIndices = [-1, -1, -1]; // -1 means still a circle
  final List<Color> _currentColors = [Colors.white, Colors.white, Colors.white];

  bool _shouldStop = false;
  final int _randomEndPoint = math.Random().nextInt(
    7,
  ); // 0-6 for different end points

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _startAnimation();
  }

  void _startAnimation() async {

    while (mounted && !_shouldStop) {
      // Phase 1: Dots to Icons (left to right)
      await Future.delayed(const Duration(milliseconds: 200));

      for (int i = 0; i < 3; i++) {
        // Check if we should stop at 1, 2, or 3 icons showing
        if (_randomEndPoint == i) {
          _shouldStop = true;
          _finishAnimation();
          return;
        }

        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          setState(() {
            _iconIndices[i] = math.Random().nextInt(_cakeIcons.length);
            _currentColors[i] =
                _iconColors[math.Random().nextInt(_iconColors.length)];
          });
          _controller.forward(from: 0);
        }
      }

      // Check if we should stop with all 3 icons visible
      if (_randomEndPoint == 3) {
        _shouldStop = true;
        _finishAnimation();
        return;
      }

      // Wait a bit with all icons visible
      await Future.delayed(const Duration(milliseconds: 500));

      // Phase 2: Icons back to Dots (randomly)
      List<int> randomOrder = [0, 1, 2]..shuffle();

      for (int i = 0; i < randomOrder.length; i++) {
        int index = randomOrder[i];

        // Check if we should stop at 2, 1, or 0 dots (after converting some icons)
        if (_randomEndPoint == 4 && i == 1) {
          // Stop with 1 dot (2 icons converted)
          _shouldStop = true;
          _finishAnimation();
          return;
        }
        if (_randomEndPoint == 5 && i == 2) {
          // Stop with 2 dots (1 icon converted)
          _shouldStop = true;
          _finishAnimation();
          return;
        }

        await Future.delayed(const Duration(milliseconds: 250));
        if (mounted) {
          setState(() {
            _iconIndices[index] = -1;
            _currentColors[index] =
                _iconColors[math.Random().nextInt(_iconColors.length)];
          });
          _controller.forward(from: 0);
        }
      }

      // Check if we should stop with all 3 dots (longest cycle)
      if (_randomEndPoint == 6) {
        _shouldStop = true;
        _finishAnimation();
        return;
      }

      // Wait before restarting
      await Future.delayed(const Duration(milliseconds: 400));

    }
  }

  void _finishAnimation() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      Navigator.pop(context); // Close loading overlay
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MenuScreen(orderType: widget.orderType),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
  color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title text with gradient color for better visibility
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.cream200, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Preparing your cake',
                style: GoogleFonts.ubuntu(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Animated icons/circles
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _AnimatedIconCircle(
                    isRevealed: _iconIndices[index] != -1,
                    icon: _iconIndices[index] != -1
                        ? _cakeIcons[_iconIndices[index]]
                        : null,
                    color: _currentColors[index],
                    animation: _controller,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedIconCircle extends StatelessWidget {
  const _AnimatedIconCircle({
    required this.isRevealed,
    required this.icon,
    required this.color,
    required this.animation,
  });

  final bool isRevealed;
  final IconData? icon;
  final Color color;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    if (!isRevealed) {
      // Show empty circle outline with color palette
      return SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.8), width: 3),
            ),
          ),
        ),
      );
    }

    // Show animated icon with color palette
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (animation.value * 0.3),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: color, size: 32),
          ),
        );
      },
    );
  }
}
