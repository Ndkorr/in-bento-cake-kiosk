// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'loading_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _showOrderTypeSelection = false;

  void _handleOrderNowTap() {
    setState(() {
      _showOrderTypeSelection = true;
    });
  }

  void _handleDineInTap() {
    _showLoadingOverlay('Dine In');
  }

  void _handleTakeoutTap() {
    _showLoadingOverlay('Takeout');
  }

  void _showLoadingOverlay(String orderType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => LoadingOverlay(orderType: orderType),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream200,
      body: Stack(
        children: [
          // Full-screen tiled icons background
          const _TiledIcons(),

          // Main content - card uses 80% of screen, portrait-friendly
          SafeArea(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final usableWidth = constraints.maxWidth;
                  final usableHeight = constraints.maxHeight;

                  final cardWidth = usableWidth * 0.80;
                  final cardHeight = usableHeight * 0.80;

                  final logoH = (cardHeight * 0.18).clamp(64.0, 140.0);
                  final titleSize = (cardWidth * 0.18).clamp(36.0, 96.0);
                  final labelSize = (cardWidth * 0.042).clamp(16.0, 26.0);
                  final innerPadding = (cardHeight * 0.06).clamp(20.0, 56.0);

                  return SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: innerPadding,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top: logo
                            SizedBox(
                              height: logoH,
                              child: Image.asset(
                                'assets/icons/icon-original.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.cake,
                                  size: 72,
                                  color: Colors.black54,
                                ),
                              ),
                            ),

                            // Middle: welcome text + animated title + tagline
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // WELCOME TO - pink700, constrained width
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: cardWidth * 0.95,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'WELCOME TO',
                                        style: GoogleFonts.ubuntu(
                                          fontSize: labelSize * 1.6,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -1.5,
                                          fontStyle: FontStyle.italic,
                                          color: AppColors.pink700,
                                          height: 0.85,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Animated rotating text
                                  _AnimatedTitleText(
                                    cardWidth: cardWidth,
                                    titleSize: titleSize,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Sweet Moments in Every Bite',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: (labelSize * 0.78),
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Bottom: Order Now button or Order Type Selection
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.2),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: _showOrderTypeSelection
                                  ? _OrderTypeSelection(
                                      key: const ValueKey('order-type'),
                                      onDineInTap: _handleDineInTap,
                                      onTakeoutTap: _handleTakeoutTap,
                                    )
                                  : _OrderNowButton(
                                      key: const ValueKey('order-now'),
                                      onTap: _handleOrderNowTap,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated title text that rotates between INBENTO, YOUR CAKE, YOUR WAY
class _AnimatedTitleText extends StatefulWidget {
  const _AnimatedTitleText({
    required this.cardWidth,
    required this.titleSize,
  });

  final double cardWidth;
  final double titleSize;

  @override
  State<_AnimatedTitleText> createState() => _AnimatedTitleTextState();
}

class _AnimatedTitleTextState extends State<_AnimatedTitleText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentIndex = 0;

  final List<String> _texts = [
    'INBENTO',
    'YOUR CAKE',
    'YOUR WAY',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % _texts.length;
          });
          _controller.reset();
          _controller.forward();
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.cardWidth * 0.95),
      child: SizedBox(
        height: widget.titleSize * 1.1,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: FittedBox(
            key: ValueKey<int>(_currentIndex),
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              _texts[_currentIndex],
              style: GoogleFonts.ubuntu(
                fontSize: widget.titleSize,
                fontWeight: FontWeight.w900,
                letterSpacing: -5.5,
                fontStyle: FontStyle.italic,
                color: AppColors.salmon400,
                height: 0.9,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Order Now button
class _OrderNowButton extends StatefulWidget {
  const _OrderNowButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<_OrderNowButton> createState() => _OrderNowButtonState();
}

class _OrderNowButtonState extends State<_OrderNowButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _isPressed || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: !isActive
                ? const LinearGradient(
                    colors: [AppColors.pink500, AppColors.peach300],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(37),
              gradient: isActive
                  ? const LinearGradient(
                      colors: [AppColors.pink500, AppColors.peach300],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(34),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Order Now!',
                    style: GoogleFonts.ubuntu(
                      color: !isActive ? Colors.white : AppColors.pink500,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: !isActive ? Colors.white : AppColors.pink500,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Order Type Selection - Dine In and Takeout buttons side by side
class _OrderTypeSelection extends StatelessWidget {
  const _OrderTypeSelection({
    super.key,
    required this.onDineInTap,
    required this.onTakeoutTap,
  });

  final VoidCallback onDineInTap;
  final VoidCallback onTakeoutTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Dine In Button
        Expanded(
          child: _OrderTypeButton(
            label: 'Dine In',
            icon: Icons.restaurant,
            gradient: const LinearGradient(
              colors: [AppColors.pink500, AppColors.salmon400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: onDineInTap,
          ),
        ),
        const SizedBox(width: 12),
        // Takeout Button
        Expanded(
          child: _OrderTypeButton(
            label: 'Takeout',
            icon: Icons.shopping_bag_outlined,
            gradient: const LinearGradient(
              colors: [AppColors.salmon400, AppColors.peach300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: onTakeoutTap,
          ),
        ),
      ],
    );
  }
}

/// Order Type Button (Dine In / Takeout)
class _OrderTypeButton extends StatefulWidget {
  const _OrderTypeButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  State<_OrderTypeButton> createState() => _OrderTypeButtonState();
}

class _OrderTypeButtonState extends State<_OrderTypeButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _isPressed || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            // Gradient background when NOT active
            gradient: !isActive ? widget.gradient : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.08),
                blurRadius: _isHovered ? 16 : 12,
                offset: Offset(0, _isHovered ? 6 : 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              // Gradient border when active
              gradient: isActive ? widget.gradient : null,
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                // White when active, transparent when not
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    // Colored icon when active, white when not
                    color: isActive
                        ? (widget.gradient as LinearGradient).colors.first
                        : Colors.white,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      // Colored text when active, white when not
                      color: isActive
                          ? (widget.gradient as LinearGradient).colors.first
                          : Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiled icons with individual animations
class _TiledIcons extends StatelessWidget {
  const _TiledIcons();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      final cell = 120.0;
      final cols = (w / cell).ceil().clamp(3, 12);
      final rows = (h / cell).ceil().clamp(3, 12);

      final icons = <IconData>[
        Icons.cake_outlined,
        Icons.celebration_outlined,
        Icons.star_border_rounded,
        Icons.cookie_outlined,
        Icons.local_cafe_outlined,
        Icons.bakery_dining_outlined,
        Icons.favorite_border,
        Icons.card_giftcard_outlined,
      ];

      final widgets = <Widget>[];
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          final idx = (r * cols + c) % icons.length;
          final fractionX = (c + 0.5) / cols;
          final fractionY = (r + 0.5) / rows;

          final offsetX =
              (math.sin((r + 1) * 1.3) + math.cos((c + 1) * 0.7)) * 6;
          final offsetY =
              (math.cos((c + 1) * 1.1) + math.sin((r + 1) * 0.9)) * 6;

          final left = (fractionX * w) + offsetX - (cell * 0.25);
          final top = (fractionY * h) + offsetY - (cell * 0.25);

          final size = (cell * 0.28) + ((r + c) % 3) * 6;

          final distToCenter =
              (Offset(left + size / 2, top + size / 2) - Offset(w / 2, h / 2))
                  .distance;
          final maxDist = math.sqrt(w * w + h * h) / 2;
          final opacityBase = 0.12;
          final opacity =
              (opacityBase + (distToCenter / maxDist) * 0.06).clamp(0.06, 0.20);

          widgets.add(
            Positioned(
              left: left.clamp(-cell, w + cell),
              top: top.clamp(-cell, h + cell),
              child: _AnimatedIcon(
                icon: icons[idx],
                size: size,
                opacity: opacity,
                index: r * cols + c,
              ),
            ),
          );
        }
      }

      return Stack(children: widgets);
    });
  }
}

class _AnimatedIcon extends StatefulWidget {
  const _AnimatedIcon({
    required this.icon,
    required this.size,
    required this.opacity,
    required this.index,
  });

  final IconData icon;
  final double size;
  final double opacity;
  final int index;

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 2500 + (widget.index * 350)),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            math.sin(_controller.value * 2 * math.pi) * 12,
            math.cos(_controller.value * 2 * math.pi) * 18,
          ),
          child: Transform.rotate(
            angle: math.sin(_controller.value * 2 * math.pi) * 0.1,
            child: Opacity(
              opacity: widget.opacity +
                  (math.sin(_controller.value * math.pi) * 0.04),
              child: Icon(
                widget.icon,
                size: widget.size,
                color: AppColors.pink500,
              ),
            ),
          ),
        );
      },
    );
  }
}