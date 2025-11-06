import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'package:in_bento_kiosk/widgets/cake_card.dart';

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
      body: SafeArea(
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
                                builder: (context) => const CakeCustomizerScreen(
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
                            onTap: () {
                              if (options[index]['title'] == '2 LAYERS') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CakeCustomizerScreen(
                                      cakeShape: 'round',
                                    ),
                                  ),
                                );
                              }
                            },
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
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.pink700, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.title, required this.subtitle, this.onTap});

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
