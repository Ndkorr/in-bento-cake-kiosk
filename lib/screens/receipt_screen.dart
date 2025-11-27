import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
// ignore: depend_on_referenced_packages
import 'package:image/image.dart' as img;
import 'thank_you_screen.dart';

class ReceiptScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final String orderType;
  final int? orderNumber;
  final bool showDoneButton;
  final bool fromStaff;

  const ReceiptScreen({
    super.key,
    required this.cartItems,
    required this.orderType,
    this.orderNumber,
    this.showDoneButton = true,
    this.fromStaff = false,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  Uint8List? _overlayImage;

  String _formatToppingsSummary(Map<String, dynamic> cartItem) {
    if (cartItem['toppingsSummary'] is String &&
        (cartItem['toppingsSummary'] as String).isNotEmpty) {
      return cartItem['toppingsSummary'] as String;
    }
    if (cartItem['toppingsCounts'] is Map) {
      try {
        final counts =
            Map<String, dynamic>.from(cartItem['toppingsCounts'] as Map);
        return counts.entries.map((e) {
          final v = e.value;
          final numVal = (v is num) ? v : int.tryParse(v.toString()) ?? 0;
          return '${e.key}(x${numVal})';
        }).join(', ');
      } catch (_) {}
    }
    // fallback: extract from common fields and respect quantity
    final counts = <String, int>{};
    final qty = (cartItem['quantity'] is num)
        ? (cartItem['quantity'] as num).toInt()
        : 1;
    final candidateFields = [
      cartItem['toppings'],
      cartItem['selectedToppings'],
      cartItem['extras'],
      cartItem['topping'],
      cartItem['toppingsSelected']
    ];
    for (var field in candidateFields) {
      if (field == null) continue;
      if (field is String) {
        final s = field.trim();
        if (s.isNotEmpty) counts[s] = (counts[s] ?? 0) + qty;
      } else if (field is List) {
        for (var e in field) {
          if (e is String) {
            final s = e.trim();
            if (s.isNotEmpty) counts[s] = (counts[s] ?? 0) + qty;
          } else if (e is Map) {
            final name = e['name'] ?? e['title'] ?? e['label'] ?? e['topping'];
            if (name is String && name.trim().isNotEmpty) {
              counts[name.trim()] = (counts[name.trim()] ?? 0) + qty;
            }
          }
        }
      } else if (field is Map) {
        final name = field['name'] ??
            field['title'] ??
            field['label'] ??
            field['topping'];
        if (name is String && name.trim().isNotEmpty)
          counts[name.trim()] = (counts[name.trim()] ?? 0) + qty;
      }
    }
    if (counts.isNotEmpty)
      return counts.entries.map((e) => '${e.key}(x${e.value})').join(', ');
    return '';
  }

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

  Future<Uint8List> createThumbnail(Uint8List originalBytes,
      {int maxSizeInBytes = 180000}) async {
    final image = img.decodeImage(originalBytes);
    if (image == null) {
      return originalBytes;
    }

    int width = 128;
    int quality = 80;
    Uint8List jpgBytes =
        Uint8List.fromList(img.encodeJpg(image, quality: quality));

    while (jpgBytes.lengthInBytes > maxSizeInBytes &&
        (width > 32 || quality > 30)) {
      // Reduce size by lowering width and quality
      width = (width * 0.7).toInt().clamp(32, width);
      quality = (quality - 15).clamp(30, quality);
      final thumb = img.copyResize(image, width: width);
      jpgBytes = Uint8List.fromList(img.encodeJpg(thumb, quality: quality));
    }

    // Final guard: if still too large, return an empty byte list to indicate skip.
    if (jpgBytes.lengthInBytes > maxSizeInBytes) {
      return Uint8List(0);
    }
    return jpgBytes;
  }

  Future<int> _saveOrderToFirestore() async {
    final now = DateTime.now();

    // compute total
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

    final nextOrderNumber = await _getNextOrderNumber();

    // Create minimal order document (keeps this document small)
    final orderDoc = await FirebaseFirestore.instance.collection('orders').add({
      'orderNumber': nextOrderNumber,
      'orderType': widget.orderType,
      'date': now.toIso8601String(),
      'total': total,
      'createdAt': FieldValue.serverTimestamp(),
      'itemCount': widget.cartItems.length,
    });

    // Add each cart item as a separate document in subcollection orders/{orderId}/items
    int idx = 0;
    final Map<String, int> toppingsCounts = {};
    for (final item in widget.cartItems) {
      idx++;
      final newItem = Map<String, dynamic>.from(item);

      // helper: robust qty parser (accept int/num/string or alternate keys)
      int _parseQty(dynamic v) {
        if (v == null) return 1;
        if (v is int) return v;
        if (v is num) return v.toInt();
        if (v is String) return int.tryParse(v) ?? 1;
        return 1;
      }

      int _getQtyFromItem(Map<String, dynamic> it) {
        // common alternate keys
        final keys = ['quantity', 'qty', 'count', 'pieces'];
        for (var k in keys) {
          if (it.containsKey(k)) return _parseQty(it[k]);
        }
        // fallback
        return 1;
      }

      // Create small thumbnail per item (more aggressive target)
      if (newItem['toppingsImage'] != null &&
          newItem['toppingsImage'] is Uint8List) {
        final thumb = await createThumbnail(
            newItem['toppingsImage'] as Uint8List,
            maxSizeInBytes: 40000);
        if (thumb.isNotEmpty) {
          newItem['toppingsThumbnail'] = thumb;
          newItem['toppingsThumbnailStored'] = true;
        } else {
          newItem['toppingsThumbnailStored'] = false;
        }
      }

      // Remove raw large fields
      newItem.remove('toppingsImage');
      newItem.remove('imageBytes');
      newItem.remove('photo');

      // Add metadata
      newItem['orderNumber'] = nextOrderNumber;
      newItem['orderCreatedAt'] = now.toIso8601String();
      newItem['index'] = idx;

      // -- toppings extraction & aggregation (match PaymentMethodScreen) --
      List<String> _extractToppings(dynamic raw) {
        final out = <String>[];
        if (raw == null) return out;
        if (raw is String) {
          final s = raw.trim();
          if (s.isNotEmpty) out.add(s);
          return out;
        }
        if (raw is List) {
          for (var e in raw) {
            out.addAll(_extractToppings(e));
          }
          return out;
        }
        if (raw is Map) {
          final candidates = [
            raw['name'],
            raw['title'],
            raw['label'],
            raw['topping'],
            raw['value'],
            raw['text']
          ];
          for (var c in candidates) {
            if (c is String && c.trim().isNotEmpty) {
              out.add(c.trim());
              return out;
            }
          }
          for (var v in raw.values) {
            if (v is String && v.trim().isNotEmpty) {
              out.add(v.trim());
              return out;
            } else if (v is List || v is Map) {
              out.addAll(_extractToppings(v));
            }
          }
          return out;
        }
        return out;
      }

      String _sanitizeKey(String s) =>
          s.replaceAll(RegExp(r'[.$\[\]#/\\]'), '_').trim();

      final qty = _getQtyFromItem(newItem);
      final candidateFields = [
        newItem['toppings'],
        newItem['selectedToppings'],
        newItem['extras'],
        newItem['topping'],
        newItem['toppingsSelected']
      ];
      final perItemCounts = <String, int>{};
      for (var field in candidateFields) {
        for (final name in _extractToppings(field)) {
          final sanitized = _sanitizeKey(name);
          perItemCounts[sanitized] = (perItemCounts[sanitized] ?? 0) + qty;
          toppingsCounts[sanitized] = (toppingsCounts[sanitized] ?? 0) + qty;
        }
      }
      if (perItemCounts.isNotEmpty) {
        newItem['toppingsCounts'] = perItemCounts;
        newItem['toppingsSummary'] = perItemCounts.entries
            .map((e) => '${e.key}(x${e.value})')
            .join(', ');
      }

      // debug log (remove when verified)
      debugPrint(
          'ReceiptScreen saving item #$idx qty=$qty perItemCounts=$perItemCounts');

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderDoc.id)
          .collection('items')
          .add(newItem);
    }

    // persist aggregated toppings usage per day (like PaymentMethodScreen)
    if (toppingsCounts.isNotEmpty) {
      final dateKey = now.toIso8601String().substring(0, 10);
      final usageRef =
          FirebaseFirestore.instance.collection('toppingsUsage').doc(dateKey);
      final incData = <String, dynamic>{};
      toppingsCounts.forEach((k, v) => incData[k] = FieldValue.increment(v));
      await usageRef.set(incData, SetOptions(merge: true));
    }

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
      appBar: AppBar(
        title: const Text('Receipt'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.fromStaff) {
              Navigator.of(context).pop(); // Go back to staff panel
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const ThankYouScreen()),
                (route) => false,
              );
            }
          },
        ),
      ),
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
                                'Toppings', _formatToppingsSummary(cartItem)),
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
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const ThankYouScreen()),
                            (route) => false,
                          );
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // fixed-width label column so values align and wrap consistently
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 13,
                color: Colors.black87,
              ),
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
              softWrap: true,
              // allow long toppings text to wrap onto multiple lines
            ),
          ),
        ],
      ),
    );
  }
}
