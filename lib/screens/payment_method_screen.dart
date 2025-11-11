import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Payment Method',
          style: GoogleFonts.ubuntu(
            fontWeight: FontWeight.w900,
            color: AppColors.pink700,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.pink700),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            _PaymentOption(
              icon: Icons.storefront,
              label: 'Pay at the Counter',
              onTap: () {
                // TODO: Handle pay at counter logic
                Navigator.pop(context, 'counter');
              },
            ),
            const SizedBox(height: 24),
            _PaymentOption(
              icon: Icons.qr_code_2,
              label: 'Card or Scan QR',
              onTap: () {
                // TODO: Handle card/QR logic
                Navigator.pop(context, 'card_or_qr');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
          child: Row(
            children: [
              Icon(icon, size: 36, color: AppColors.pink700),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.ubuntu(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pink700,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
