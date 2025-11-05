import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'menu_screen.dart'; // We need _CakeCard, so we import the whole file.

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

    final options = [
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
                          onViewTap: () {},
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
  const _OptionButton({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
      child: Column(
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
    );
  }
}
