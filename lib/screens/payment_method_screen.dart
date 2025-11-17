import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'thank_you_screen.dart';
import 'welcome_screen.dart' show TiledIcons;
import 'receipt_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethodScreen extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  final String orderType; // <-- add this

  const PaymentMethodScreen(
      {super.key, required this.cartItems, required this.orderType});

  double _calculateTotal(List<Map<String, dynamic>> cartItems) {
    double total = 0;
    for (final item in cartItems) {
      final price = (item['price'] is num)
          ? item['price'].toDouble()
          : (item['cakePrice'] is num)
              ? item['cakePrice'].toDouble()
              : 0.0;
      final qty = (item['quantity'] is int) ? item['quantity'] : 1;
      total += price * qty;
    }
    return total;
  }

  Future<int> _saveOrderToFirestore(
      List<Map<String, dynamic>> cartItems, String orderType) async {
    final counterRef =
        FirebaseFirestore.instance.collection('counters').doc('orders');
    final nextOrderNumber =
        await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      int latest = 0;
      if (snapshot.exists &&
          snapshot.data()!.containsKey('latestOrderNumber')) {
        latest = snapshot['latestOrderNumber'] as int;
      } else {
        transaction.set(counterRef, {'latestOrderNumber': 1});
        return 1;
      }
      final next = latest + 1;
      transaction.update(counterRef, {'latestOrderNumber': next});
      return next;
    });

    final total = _calculateTotal(cartItems);

    final now = DateTime.now();
    final orderData = {
      'orderNumber': nextOrderNumber,
      'cartItems': cartItems,
      'orderType': orderType,
      'total': total,
      'date': now.toIso8601String(),
      // Add other fields as needed
    };
    await FirebaseFirestore.instance.collection('orders').add(orderData);
    return nextOrderNumber;
  }

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
      body: Stack(
        children: [
          const TiledIcons(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                _PaymentOption(
                  icon: Icons.storefront,
                  label: 'Cash',
                  onTap: () async {
                    final nextOrderNumber =
                        await _saveOrderToFirestore(cartItems, orderType);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiptScreen(
                          cartItems: cartItems,
                          orderType: orderType,
                          orderNumber: nextOrderNumber,
                          
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                _PaymentOption(
                  icon: Icons.qr_code_2,
                  label: 'Card or Scan QR',
                  onTap: () async {
                    final nextOrderNumber =
                        await _saveOrderToFirestore(cartItems, orderType);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiptScreen(
                          cartItems: cartItems,
                          orderType: orderType,
                          orderNumber: nextOrderNumber,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
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
