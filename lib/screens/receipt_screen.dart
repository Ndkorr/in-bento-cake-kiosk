import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
// ignore: depend_on_referenced_packages
import 'package:image/image.dart' as img;

class ReceiptScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final String orderType;
  final int? orderNumber;
  final bool showDoneButton;

  const ReceiptScreen({
    super.key,
    required this.cartItems,
    required this.orderType,
    this.orderNumber,
    this.showDoneButton = true,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  Uint8List? _overlayImage;

  Future<int> _getNextOrderNumber() async {
    final counterRef =
        FirebaseFirestore.instance.collection('counters').doc('orders');
    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      int latest = 0;
      if (snapshot.exists &&
          snapshot.data()!.containsKey('latestOrderNumber')) {
        latest = snapshot['latestOrderNumber'] as int;
      } else {
        // If the document doesn't exist, create it with 1
        transaction.set(counterRef, {'latestOrderNumber': 1});
        return 1;
      }
      final next = latest + 1;
      transaction.update(counterRef, {'latestOrderNumber': next});
      return next;
    });
  }

  Future<Uint8List> createThumbnail(Uint8List originalBytes) async {
    final image = img.decodeImage(originalBytes);
    final thumbnail = img.copyResize(image!, width: 100, height: 100);
    return Uint8List.fromList(img.encodePng(thumbnail));
  }

  Future<int> _saveOrderToFirestore() async {
    final now = DateTime.now();

    // Process cart items and create thumbnails
    final cartItemsForFirestore = <Map<String, dynamic>>[];
    for (final item in widget.cartItems) {
      final newItem = Map<String, dynamic>.from(item);
      if (newItem['toppingsImage'] != null &&
          newItem['toppingsImage'] is Uint8List) {
        final thumb = await createThumbnail(newItem['toppingsImage']);
        newItem['toppingsThumbnail'] = thumb;
      }
      newItem.remove('toppingsImage');
      cartItemsForFirestore.add(newItem);
    }

    final nextOrderNumber = await _getNextOrderNumber();
    final orderData = {
      'orderNumber': nextOrderNumber,
      'cartItems': cartItemsForFirestore,
      'total': cartItemsForFirestore.fold<double>(
        0,
        (sum, item) {
          final price = (item['price'] is num)
              ? item['price'].toDouble()
              : (item['cakePrice'] is num)
                  ? item['cakePrice'].toDouble()
                  : 0.0;
          final qty = (item['quantity'] is int) ? item['quantity'] : 1;
          return sum + price * qty;
        },
      ),
      'orderType': widget.orderType,
      'date': now.toIso8601String(),
      // Add more fields as needed, e.g. customer info
    };
    await FirebaseFirestore.instance.collection('orders').add(orderData);
    return nextOrderNumber;
  }

  void _showImageOverlay(Uint8List image) {
    setState(() {
      _overlayImage = image;
    });
  }

  void _hideImageOverlay() {
    setState(() {
      _overlayImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final orderNumber = now.millisecondsSinceEpoch.toString().substring(6);
    final dateStr = DateFormat('yyyy-MM-dd  HH:mm').format(now);
    final displayOrderNumber =
        (widget.orderNumber ?? 0).toString().padLeft(5, '0');

    // Calculate total price
    double total = 0;
    for (final item in widget.cartItems) {
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
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 340,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400, width: 1.5),
                boxShadow: const [
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
                    const Text(
                      'IN-BENTO CAKE KIOSK',
                      style: TextStyle(
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
                      'Order #$displayOrderNumber',
                      style: const TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      widget.orderType,
                      style: const TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(thickness: 1, color: Colors.black87),
                    ...widget.cartItems.map((cartItem) {
                      final toppingsImage =
                          cartItem['toppingsImage'] as Uint8List? ??
                              cartItem['toppingsThumbnail'] as Uint8List?;
                      final toppings = (cartItem['selectedToppings'] as List?)
                          ?.cast<String>();
                      bool isCustom = (cartItem['isCustom'] == true) ||
                          (cartItem['toppingsImage'] != null);

                      String itemTitle;
                      final name = cartItem['name']?.toString() ?? '';
                      final description =
                          cartItem['description']?.toString() ?? '';
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

                      String classic(String? value) =>
                          isCustom ? (value ?? '') : 'Classic ${value ?? ''}';

                      final price = (cartItem['price'] is num)
                          ? cartItem['price'].toDouble()
                          : (cartItem['cakePrice'] is num)
                              ? cartItem['cakePrice'].toDouble()
                              : 0.0;
                      final qty = (cartItem['quantity'] is int)
                          ? cartItem['quantity']
                          : 1;
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
                                      ? layers!
                                          .map((e) => 'Classic $e')
                                          .join(', ')
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
                              (isCustom &&
                                      toppings != null &&
                                      toppings.isNotEmpty)
                                  ? toppings.join(', ')
                                  : (isCustom ? 'None' : ''),
                            ),
                            _receiptRow(
                              'Dedication',
                              cartItem['dedication'] != null &&
                                      (cartItem['dedication'] as String)
                                          .isNotEmpty
                                  ? cartItem['dedication']
                                  : 'None',
                            ),
                            _receiptRow('Qty', qty.toString()),
                            _receiptRow(
                                'Price',
                                price > 0
                                    ? '₱${price.toStringAsFixed(2)}'
                                    : '-'),
                            _receiptRow(
                                'Subtotal',
                                subtotal > 0
                                    ? '₱${subtotal.toStringAsFixed(2)}'
                                    : '-'),
                            if (toppingsImage != null) ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _showImageOverlay(toppingsImage),
                                child: const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 0),
                                    child: Text(
                                      'Toppings Preview',
                                      style: TextStyle(
                                        fontFamily: 'RobotoMono',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            const Text(
                                '----------------------------------------',
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
                        const Text(
                          'TOTAL: ',
                          style: TextStyle(
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
                    const Text(
                      'THANK YOU FOR YOUR ORDER!',
                      style: TextStyle(
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
                    if (widget.showDoneButton)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        child: const Text('Done'),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_overlayImage != null)
            GestureDetector(
              onTap: _hideImageOverlay,
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_overlayImage!, height: 320),
                  ),
                ),
              ),
            ),
        ],
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
