import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'thank_you_screen.dart';
import 'welcome_screen.dart' show TiledIcons;
import 'receipt_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class PaymentMethodScreen extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  final String orderType; // <-- add this

  const PaymentMethodScreen(
      {super.key, required this.cartItems, required this.orderType});

  double _calculateTotal(List<Map<String, dynamic>> cartItems) {
    double total = 0;
    int _parseQty(dynamic v) {
      if (v == null) return 1;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 1;
      return 1;
    }

    for (final item in cartItems) {
      final price = (item['price'] is num)
          ? item['price'].toDouble()
          : (item['cakePrice'] is num)
              ? item['cakePrice'].toDouble()
              : 0.0;
      final qty = _parseQty(item['quantity']);
      total += price * qty;
    }
    return total;
  }

  Future<Uint8List> _createThumbnail(Uint8List originalBytes,
      {int maxSizeInBytes = 40000}) async {
    final image = img.decodeImage(originalBytes);
    if (image == null) return originalBytes;

    int width = 128;
    int quality = 80;
    Uint8List jpg = Uint8List.fromList(img.encodeJpg(image, quality: quality));

    while (jpg.lengthInBytes > maxSizeInBytes && (width > 32 || quality > 30)) {
      width = (width * 0.7).toInt().clamp(32, width);
      quality = (quality - 15).clamp(30, quality);
      final thumb = img.copyResize(image, width: width);
      jpg = Uint8List.fromList(img.encodeJpg(thumb, quality: quality));
    }

    if (jpg.lengthInBytes > maxSizeInBytes) return Uint8List(0);
    return jpg;
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

    // create a minimal order doc to avoid large single-document writes
    final orderRef = await FirebaseFirestore.instance.collection('orders').add({
      'orderNumber': nextOrderNumber,
      'orderType': orderType,
      'total': total,
      'date': now.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
      'itemCount': cartItems.length,
    });

    // write each item into orders/{orderId}/items subcollection
    int idx = 0;

    final Map<String, int> toppingsCounts = {};

    // helper to extract topping names from many possible shapes
    List<String> _extractToppings(dynamic raw) {
      final out = <String>[];
      if (raw == null) return out;
      // plain string
      if (raw is String) {
        final s = raw.trim();
        if (s.isNotEmpty) out.add(s);
        return out;
      }
      // list of strings or maps
      if (raw is List) {
        for (var e in raw) {
          out.addAll(_extractToppings(e));
        }
        return out;
      }
      // map: try common keys, then search values for first suitable string
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
        // fallback: examine map values (first string found)
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

    // sanitize keys used as field names in Firestore (remove problematic chars)
    String _sanitizeKey(String s) {
      return s.replaceAll(RegExp(r'[.$\[\]#/\\]'), '_').trim();
    }

    for (final item in cartItems) {
      idx++;
      final newItem = Map<String, dynamic>.from(item);

      int _parseQty(dynamic v) {
        if (v == null) return 1;
        if (v is int) return v;
        if (v is num) return v.toInt();
        if (v is String) return int.tryParse(v) ?? 1;
        return 1;
      }

      // compress toppingsImage if present and small enough
      if (newItem['toppingsImage'] != null &&
          newItem['toppingsImage'] is Uint8List) {
        final thumb = await _createThumbnail(
            newItem['toppingsImage'] as Uint8List,
            maxSizeInBytes: 40000); // target ~40KB
        if (thumb.isNotEmpty) {
          newItem['toppingsThumbnail'] = thumb;
          newItem['toppingsThumbnailStored'] = true;
        } else {
          newItem['toppingsThumbnailStored'] = false;
        }
      }

      // remove any large raw fields
      newItem.remove('toppingsImage');
      newItem.remove('imageBytes');
      newItem.remove('photo');

      // add metadata
      newItem['orderNumber'] = nextOrderNumber;
      newItem['orderCreatedAt'] = now.toIso8601String();
      newItem['index'] = idx;

      // count toppings for aggregation (respect quantity if present)
      final qty = _parseQty(newItem['quantity']);
      final Map<String,int> perItemCounts = {};

     // If the customizer already supplied toppingsCounts, use it (scale by qty).
     if (newItem.containsKey('toppingsCounts') && newItem['toppingsCounts'] is Map) {
       final provided = Map<String,dynamic>.from(newItem['toppingsCounts'] as Map);
       provided.forEach((rawKey, rawVal) {
         final key = _sanitizeKey(rawKey.toString());
         final val = (rawVal is num) ? rawVal.toInt() : int.tryParse(rawVal.toString()) ?? 0;
         if (val == 0) return;
         perItemCounts[key] = (perItemCounts[key] ?? 0) + val * qty;
         toppingsCounts[key] = (toppingsCounts[key] ?? 0) + val * qty;
       });
     } else {
       // fallback to existing extraction when toppingsCounts not provided
       final candidateFields = [
         newItem['toppings'],
         newItem['selectedToppings'],
         newItem['extras'],
         newItem['topping'],
         newItem['toppingsSelected']
       ];
       for (var field in candidateFields) {
         for (final name in _extractToppings(field)) {
           final sanitized = _sanitizeKey(name);
           final add = qty;
           toppingsCounts[sanitized] = (toppingsCounts[sanitized] ?? 0) + add;
           perItemCounts[sanitized] = (perItemCounts[sanitized] ?? 0) + add;
         }
       }
     }

    if (perItemCounts.isNotEmpty) {
      newItem['toppingsCounts'] = perItemCounts;
      newItem['toppingsSummary'] = perItemCounts.entries.map((e) => '${e.key}(x${e.value})').join(', ');
    }

      

     // debug: print to console so you can check values in debug log
     // (remove in production)
     debugPrint('Saving item #$idx -> qty=$qty perItemCounts=$perItemCounts toppingsCountsSoFar=$toppingsCounts');

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderRef.id)
          .collection('items')
          .add(newItem);
    }

    // persist aggregated toppings usage: doc per day (yyyy-mm-dd)
    if (toppingsCounts.isNotEmpty) {
      final dateKey = now.toIso8601String().substring(0, 10);
      final usageRef =
          FirebaseFirestore.instance.collection('toppingsUsage').doc(dateKey);
      final Map<String, dynamic> incData = {};
      toppingsCounts.forEach((name, count) {
        incData[name] = FieldValue.increment(count);
      });
      await usageRef.set(incData, SetOptions(merge: true));

      // optional: also increment global totals
      final globalRef =
          FirebaseFirestore.instance.collection('toppingsUsage').doc('global');
      final Map<String, dynamic> incGlobal = {};
      toppingsCounts.forEach((name, count) {
        incGlobal[name] = FieldValue.increment(count);
      });
      await globalRef.set(incGlobal, SetOptions(merge: true));
    }

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
                  icon: Icons.credit_card,
                  label: 'Card',
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
                  label: 'Scan QR',
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
