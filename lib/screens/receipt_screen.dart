import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';

class ReceiptScreen extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;

  const ReceiptScreen({super.key, required this.cartItems});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final orderNumber = now.millisecondsSinceEpoch.toString().substring(6);
    final dateStr = DateFormat('yyyy-MM-dd  HH:mm').format(now);

    // Calculate total price
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

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(title: const Text('Receipt')),
      body: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'IN-BENTO CAKE KIOSK',
                  style: const TextStyle(
                    fontFamily: 'RobotoMono',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  'Order #$orderNumber',
                  style: const TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(thickness: 1, color: Colors.black87),
                ...cartItems.map((cartItem) {
                  final toppingsImage = cartItem['toppingsImage'] as Uint8List?;
                  final toppings = cartItem['selectedToppings'] as List<String> ?;
                  // Compose the name and description for combos and custom
                  bool isCustom = (cartItem['isCustom'] == true) ||
                      (cartItem['toppingsImage'] != null);

                  String itemTitle;
                  final name = cartItem['name']?.toString() ?? '';
                  final description = cartItem['description']?.toString() ?? '';
                  final isComboA = name.trim().toLowerCase() == 'combo a';

                  if (isCustom) {
                    if (isComboA && description.isNotEmpty) {
                      itemTitle = '$name | $description | Custom';
                    } else if (isComboA) {
                      itemTitle = '$name | Custom';
                    } else if (name.isNotEmpty && description.isNotEmpty) {
                      itemTitle = '$name | $description | Custom';
                    } else if (name.isNotEmpty) {
                      itemTitle = '$name | Custom';
                    } else {
                      itemTitle = 'Custom Cake';
                    }
                  } else {
                    if (name.isNotEmpty && description.isNotEmpty) {
                      itemTitle = '$name | $description';
                    } else if (name.isNotEmpty) {
                      itemTitle = name;
                    } else {
                      itemTitle = 'Cake';
                    }
                  }

                  // Add "Classic" for non-customized cakes
                  String classic(String? value) =>
                      isCustom ? (value ?? '') : 'Classic ${value ?? ''}';

                  final price = (cartItem['price'] is num)
                      ? cartItem['price'].toDouble()
                      : (cartItem['cakePrice'] is num)
                          ? cartItem['cakePrice'].toDouble()
                          : 0.0;
                  final qty =
                      (cartItem['quantity'] is int) ? cartItem['quantity'] : 1;
                  final subtotal = price * qty;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemTitle.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'RobotoMono',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _receiptRow(
                          'Shape',
                          (() {
                            final shape = cartItem['shape'];
                            if (isCustom) {
                              return shape ?? '';
                            } else {
                              return (shape != null &&
                                      shape.toString().isNotEmpty)
                                  ? 'Classic $shape'
                                  : 'Classic';
                            }
                          })(),
                        ),
                        _receiptRow(
                          'Layers',
                          (() {
                            final layers = cartItem['layers'] as List?;
                            if (isCustom) {
                              return (layers?.isNotEmpty ?? false)
                                  ? layers!.join(', ')
                                  : '';
                            } else {
                              return (layers?.isNotEmpty ?? false)
                                  ? layers!.map((e) => 'Classic $e').join(', ')
                                  : 'Classic';
                            }
                          })(),
                        ),
                        _receiptRow(
                          'Fillings',
                          (() {
                            final fillings = cartItem['fillings'] as List?;
                            if (isCustom) {
                              return (fillings?.isNotEmpty ?? false)
                                  ? fillings!.join(', ')
                                  : '';
                            } else {
                              return (fillings?.isNotEmpty ?? false)
                                  ? fillings!
                                      .map((e) => 'Classic $e')
                                      .join(', ')
                                  : 'Classic';
                            }
                          })(),
                        ),
                        _receiptRow(
                            'Frosting',
                            isCustom
                                ? (cartItem['frosting'] ?? '')
                                : 'Classic ${cartItem['frosting'] ?? ''}'),
                        _receiptRow(
                          'Toppings',
                          (isCustom && toppings != null && toppings.isNotEmpty)
                              ? toppings.join(', ')
                              : (isCustom ? 'None' : ''),
                        ),
                        _receiptRow('Qty', qty.toString()),
                        _receiptRow('Price',
                            price > 0 ? '₱${price.toStringAsFixed(2)}' : '-'),
                        _receiptRow(
                            'Subtotal',
                            subtotal > 0
                                ? '₱${subtotal.toStringAsFixed(2)}'
                                : '-'),
                        if (toppingsImage != null) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'Toppings Preview',
                                  style: TextStyle(
                                    fontFamily: 'RobotoMono',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child:
                                      Image.memory(toppingsImage, height: 80),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Text('----------------------------------------',
                            style: TextStyle(
                                fontFamily: 'RobotoMono', fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 8),
                const Divider(thickness: 1, color: Colors.black87),
                Row(
                  children: [
                    const Spacer(),
                    Text(
                      'TOTAL: ',
                      style: const TextStyle(
                        fontFamily: 'RobotoMono',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '₱${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'RobotoMono',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(thickness: 1, color: Colors.black87),
                const SizedBox(height: 8),
                Text(
                  'THANK YOU FOR YOUR ORDER!',
                  style: const TextStyle(
                    fontFamily: 'RobotoMono',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please present this receipt at the counter.',
                  style: TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Text(
            label.padRight(10),
            style: const TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const Text(': ',
              style: TextStyle(fontFamily: 'RobotoMono', fontSize: 13)),
          Expanded(
            child: Text(
              value ?? '',
              style: const TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 13,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
