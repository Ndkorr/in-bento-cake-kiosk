import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';
// Use CakeCard from menu_screen
import 'menu_screen.dart';
import 'cake_customizer_screen.dart';

class CakeDetailsScreen extends StatelessWidget {
  const CakeDetailsScreen({
    super.key,
    required this.cake,
    required this.cakeIndex,
  });

  final Map<String, dynamic> cake;
  final int cakeIndex;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    const options = [
      {'title': '2 LAYERS', 'subtitle': 'SAME FLAVOR FOR BOTH LAYERS'},
      {'title': '1 FILLING', 'subtitle': 'SAME FLAVOR AS CAKE LAYER'},
      {'title': 'FROSTING', 'subtitle': 'SAME FLAVOR AS CAKE LAYER'},
      {'title': '2 TOPPINGS', 'subtitle': 'OF YOUR CHOICE'},
      {'title': 'DEDICATION', 'subtitle': 'PERSONALIZED'},
    ];

    return Scaffold(
      backgroundColor: AppColors.cream200,
      body: Stack(
        children: [
          // Pulsating background icons
          const Positioned.fill(
            child: _TiledIcons(),
          ),
          // Main content
          SafeArea(
            child: Center(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(42),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // The card that grows
                        SizedBox(
                          height: screenHeight * 0.4,
                          child: Hero(
                            tag: 'cake_card_$cakeIndex',
                            child: CakeCard(
                              cake: cake,
                              isSelected: true,
                              isLandscape: false, // Keep portrait layout
                              onTap: () {}, // No action needed here
                              onViewTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CakeCustomizerScreen(
                                      cakeShape: 'round',
                                    ),
                                  ),
                                );
                              },
                              viewButtonText: 'Customize',
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Customization options
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              return _OptionButton(
                                title: options[index]['title']!,
                                subtitle: options[index]['subtitle']!,
                                onTap: null,
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.pink700, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton(
      {required this.title, required this.subtitle, this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.pink500,
              AppColors.salmon400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 12),
            const _PulsatingIcon(icon: Icons.auto_awesome, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.ubuntu(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.ubuntu(
                      color: AppColors.cream200,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _PulsatingIcon extends StatefulWidget {
  const _PulsatingIcon({required this.icon, this.size = 20});

  final IconData icon;
  final double size;

  @override
  State<_PulsatingIcon> createState() => _PulsatingIconState();
}

class _PulsatingIconState extends State<_PulsatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.20, end: 0.40).animate(
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size + 12,
          height: widget.size + 12,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.salmon400.withOpacity(_glow.value),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
            gradient: const LinearGradient(
              colors: [AppColors.pink500, AppColors.salmon400],
            ),
          ),
          child: Transform.scale(
            scale: _scale.value,
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}

// Tiled Icons Widget
class _TiledIcons extends StatelessWidget {
  const _TiledIcons();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        const cell = 120.0;
        final cols = (w / cell).ceil().clamp(3, 12);
        final rows = (h / cell).ceil().clamp(3, 12);

        const icons = <IconData>[
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
            const double opacityBase = 0.12;
            final opacity = (opacityBase + (distToCenter / maxDist) * 0.06)
                .clamp(0.06, 0.20);

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
      },
    );
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
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500 + (widget.index % 500)),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
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
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            widget.icon,
            size: widget.size,
            color: AppColors.pink500.withOpacity(widget.opacity),
          ),
        );
      },
    );
  }
}
