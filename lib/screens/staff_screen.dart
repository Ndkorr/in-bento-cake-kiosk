import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import 'welcome_screen.dart';
import 'receipt_screen.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
// Removed web-only dart:html import to keep Android/iOS builds working.


class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {

  bool _showEditKiosk = false;
  bool _showMenuManager = false;
  List<Map<String, dynamic>> _menuCombos = [];
  int? _selectedComboIndex;
  String? _selectedComboDocId;
  
  // Dummy user list for demonstration
  int? _selectedUserIndex;
  bool _showUserManager = false;
  bool _showOrdersManager = false;
  String? _selectedUserDocId;
  String? _selectedUserName;
  final String _protectedUser = 'mathewsa';
  int? _selectedOrderIndex;
  bool _showSalesDetails = false;

  bool _showToppingsDetails = false;
  bool _loadingToppings = false;
  List<String> _toppingsLabels = [];
  List<String> _topToppings = [];
  Map<String, List<FlSpot>> _toppingSpots = {};
  int? _selectedToppingIndex;
  Set<String> _visibleToppings = {};
  Map<String, double> _toppingsTotals = {};

  List<FlSpot> _salesSpots = [];
  List<FlSpot> _targetSaleSpots = [];
  List<String> _salesLabels = [];
  bool _loadingSales = false;

  String _salesFilter = 'days';
  List<String> _allCakeNames = [];
  List<String> _selectedCakeNames = [];

  double? _targetSale;
  bool _loadingTargetSale = false;
  String? _currentTargetDate;

  int? _selectedSalesIndex;

  double _todaySales = 0.0;
  double _todayTarget = 0.0;

  double? _defaultDailyTarget;

  final List<Color> _toppingColors = [
    AppColors.pink700,
    Colors.deepOrange,
    AppColors.salmon400,
    Colors.teal,
    Colors.indigo,
  ];

  void _showManageOrders() {
    setState(() {
      _showOrdersManager = true;
    });
  }

  void _hideManageOrders() {
    setState(() {
      _showOrdersManager = false;
    });
  }

  void _showManageUsers() {
    setState(() {
      _showUserManager = true;
    });
  }

  void _hideManageUsers() {
    setState(() {
      _showUserManager = false;
      _selectedUserIndex = null;
      _selectedUserDocId = null;
    });
  }

  void _showEditKioskOptions() {
    setState(() {
      _showEditKiosk = true;
    });
  }

  void _hideEditKioskOptions() {
    setState(() {
      _showEditKiosk = false;
      _showMenuManager = false;
      _selectedComboIndex = null;
      _selectedComboDocId = null;
    });
  }

  void _showMenuManagerScreen() {
    setState(() {
      _showMenuManager = true;
    });
    _loadMenuCombos();
  }

  void _hideMenuManagerScreen() {
    setState(() {
      _showMenuManager = false;
      _selectedComboIndex = null;
      _selectedComboDocId = null;
    });
  }

  // ImgBB API key (free tier: 5000 uploads/month, no login required)
  final String _imgbbApiKey =
      '03519e78bf178a14f33e42235be3a963';

// Upload image to ImgBB and return direct URL
  // Upload image to ImgBB and return direct URL
  Future<String?> _uploadImageToImgBB(
      Uint8List imageBytes, String fileName) async {
    try {
      debugPrint('Uploading image: $fileName (${imageBytes.length} bytes)');
      debugPrint('ImgBB key length: ${_imgbbApiKey.length}');

      // Safety: bail if key is empty
      if (_imgbbApiKey.isEmpty) {
        debugPrint('ImgBB API key is empty!');
        return null;
      }

      final base64Image = base64Encode(imageBytes);

      // Build URL explicitly to avoid losing the value
      final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey');
      debugPrint('Sending request to: $uri');

      final request = http.MultipartRequest('POST', uri);
      request.fields['image'] = base64Image;
      request.fields['name'] =
          fileName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('ImgBB response status: ${response.statusCode}');
      debugPrint('ImgBB response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          // Prefer the direct image URL to avoid loading a webpage on mobile
          final data = json['data'];
          String? directUrl;
          try {
            directUrl = data['image']?['url'] as String?; // direct content URL
          } catch (_) {}
          directUrl ??= data['display_url'] as String?; // fallback to display url
          directUrl ??= data['url'] as String?; // last resort: viewer page

          if (directUrl != null) {
            debugPrint('Upload successful! Direct URL: $directUrl');
            return directUrl;
          }
          debugPrint('Upload succeeded but URL fields missing');
          return null;
        }
        debugPrint('ImgBB error: ${json['error']}');
        return null;
      }

      debugPrint('HTTP error: ${response.statusCode}');
      return null;
    } catch (e, stackTrace) {
      debugPrint('ImgBB upload error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }  
  }

  Future<void> _loadMenuCombos() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('menuCombos')
          .orderBy('name')
          .get();

      setState(() {
        _menuCombos = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown',
            'description': data['description'] ?? '',
            'price': (data['price'] as num?)?.toDouble() ?? 0.0,
            'image': data['image'] ?? 'assets/images/cake_1.png',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading menu combos: $e');
    }
  }

  Future<void> _addMenuCombo() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Cake Combo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Combo Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Details'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final description = descriptionController.text.trim();
              final price = double.tryParse(priceController.text.trim()) ?? 0.0;

              if (name.isNotEmpty) {
                Navigator.pop(context, {
                  'name': name,
                  'description': description,
                  'price': price,
                  'image': 'assets/images/cake_1.png', // Default image
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      await FirebaseFirestore.instance.collection('menuCombos').add(result);
      await _loadMenuCombos();
    }
  }

  Future<void> _updateMenuCombo() async {
    if (_selectedComboIndex == null) return;

    final combo = _menuCombos[_selectedComboIndex!];
    final nameController = TextEditingController(text: combo['name']);
    final descriptionController =
        TextEditingController(text: combo['description']);
    final priceController =
        TextEditingController(text: combo['price'].toString());

    String? selectedImageUrl = combo['image'];
    Uint8List? imagePreviewBytes;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Cake Combo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Details'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Image upload section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cake Image:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    // Preview
                    if (imagePreviewBytes != null)
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(imagePreviewBytes!,
                              fit: BoxFit.cover),
                        ),
                      )
                    else if (selectedImageUrl != null)
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(selectedImageUrl,
                              fit: BoxFit.cover),
                        ),
                      ), 

                    const SizedBox(height: 8),

                    // Upload button (cross-platform via file_picker)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Choose Image'),
                      onPressed: () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowMultiple: false,
                            withData: true, // ensures bytes are available on web/mobile
                          );

                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            final bytes = file.bytes;

                            if (bytes != null) {
                              setDialogState(() {
                                imagePreviewBytes = Uint8List.fromList(bytes);
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Image selected: ${file.name ?? 'image'}'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not read file bytes.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          debugPrint('File selection error: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();
                final price =
                    double.tryParse(priceController.text.trim()) ?? 0.0;

                if (name.isEmpty) return;

                // Upload new image if selected
                String? finalImageUrl = selectedImageUrl;
                if (imagePreviewBytes != null) {
                  // Show uploading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Uploading image...')),
                  );

                  finalImageUrl = await _uploadImageToImgBB(
                    imagePreviewBytes!,
                    '${name.replaceAll(' ', '_')}.png',
                  );

                  if (finalImageUrl == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Image upload failed. Keeping old image.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    finalImageUrl = combo['image']; // Fallback to old image
                  }
                }

                Navigator.pop(context, {
                  'name': name,
                  'description': description,
                  'price': price,
                  'image': finalImageUrl,
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await FirebaseFirestore.instance
          .collection('menuCombos')
          .doc(combo['id'])
          .update(result);
      await _loadMenuCombos();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cake combo updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteMenuCombo() async {
    if (_selectedComboIndex == null) return;

    final combo = _menuCombos[_selectedComboIndex!];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Combo'),
        content: Text('Are you sure you want to delete "${combo['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('menuCombos')
          .doc(combo['id'])
          .delete();
      setState(() {
        _selectedComboIndex = null;
        _selectedComboDocId = null;
      });
      await _loadMenuCombos();
    }
  }

  Future<void> _resetOrderCount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Order Count'),
        content: const Text(
          'This will reset the order counter to 0. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('counters')
            .doc('orders')
            .set({'latestOrderNumber': 0});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order count reset successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting order count: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadOrderItems(
      String orderId, Map<String, dynamic> orderData) async {
    final List<Map<String, dynamic>> items = [];

    // helper to normalize a raw item map into {name, price (double), quantity (int), ...}
    Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
      final m = Map<String, dynamic>.from(raw);

      // name fallback chain
      final name = m['name'] ??
          m['cakeName'] ??
          m['title'] ??
          m['productName'] ??
          (m['isCustom'] == true ? 'Custom Cake' : 'Item');
      m['name'] = name;

      // quantity fallback
      int qty = 1;
      final qv = m['quantity'] ?? m['qty'] ?? m['count'];
      if (qv is int) qty = qv;
      if (qv is String) qty = int.tryParse(qv) ?? 1;
      if (qv is double) qty = qv.toInt();
      m['quantity'] = qty;

      // price fallback and computation for custom cakes
      double price = 0.0;
      dynamic pv =
          m['price'] ?? m['cakePrice'] ?? m['unitPrice'] ?? m['totalPrice'];
      if (pv == null) {
        // try compute from cakePrice + toppings (if available)
        final base = m['cakePrice'] ?? m['basePrice'] ?? 0;
        double baseD = 0;
        if (base is num) baseD = base.toDouble();
        if (base is String) baseD = double.tryParse(base) ?? 0;
        double toppingsSum = 0.0;
        final toppings = m['toppings'] ?? m['selectedToppings'] ?? m['extras'];
        if (toppings is List) {
          for (var t in toppings) {
            if (t is Map && t['price'] != null) {
              final tv = t['price'];
              if (tv is num) toppingsSum += tv.toDouble();
              if (tv is String) toppingsSum += double.tryParse(tv) ?? 0.0;
            } else if (t is num) {
              toppingsSum += t.toDouble();
            }
          }
        }
        price = baseD + toppingsSum;
      } else {
        if (pv is num) price = pv.toDouble();
        if (pv is String) price = double.tryParse(pv) ?? 0.0;
        if (pv is List) {
          // sometimes Firestore returns bytes for blobs; ignore in price context
          price = 0.0;
        }
      }
      m['price'] = price;

      // Normalize thumbnail if present (keep existing logic)
      if (m['toppingsThumbnail'] != null) {
        final thumb = m['toppingsThumbnail'];
        if (thumb is String) {
          try {
            m['toppingsThumbnail'] = base64Decode(thumb);
          } catch (_) {
            m['toppingsThumbnail'] = Uint8List.fromList(thumb.codeUnits);
          }
        } else if (thumb is List) {
          m['toppingsThumbnail'] = Uint8List.fromList(thumb.cast<int>());
        } else if (thumb.runtimeType.toString() == '_Blob') {
          m['toppingsThumbnail'] = thumb.bytes;
        }
      }

      return m;
    }

    // If the older single-document format exists, use it
    if (orderData.containsKey('cartItems') && orderData['cartItems'] is List) {
      final raw = orderData['cartItems'] as List;
      for (var item in raw) {
        final map = Map<String, dynamic>.from(item as Map);
        items.add(_normalize(map));
      }
      return items;
    }

    // Otherwise load items from subcollection orders/{orderId}/items
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .collection('items')
        .get();
    for (var doc in snapshot.docs) {
      final map = Map<String, dynamic>.from(doc.data());
      items.add(_normalize(map));
    }
    return items;
  }

  Future<double> _computeSalesFromDocs(List<QueryDocumentSnapshot> docs) async {
    double sales = 0.0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final items = await _loadOrderItems(doc.id, data);
      for (var item in items) {
        final name = item['name'];
        final price = (item['price'] is int)
            ? (item['price'] as int).toDouble()
            : (item['price'] as double? ?? 0.0);
        final qty = (item['quantity'] as int? ?? 1);
        if (_selectedCakeNames.isEmpty || _selectedCakeNames.contains(name)) {
          sales += price * qty;
        }
      }
    }
    return sales;
  }

  Future<Map<String, dynamic>> _computeToppingsTotalsFromDocs(
      List<QueryDocumentSnapshot> docs) async {
    final Map<String, double> totals = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final items = await _loadOrderItems(doc.id, data);

      for (var item in items) {
        final itemQty = (item['quantity'] is int)
            ? item['quantity'] as int
            : (item['quantity'] is num)
                ? (item['quantity'] as num).toInt()
                : 1;

        // Parse toppings from the item
        final toppingsData = item['toppingsCounts'] ??
            item['toppings'] ??
            item['selectedToppings'] ??
            item['extras'];

        if (toppingsData is Map) {
          toppingsData.forEach((key, value) {
            final name = key.toString().trim();
            if (name.isNotEmpty) {
              final count = (value is num) ? value.toDouble() : 1.0;
              totals[name] = (totals[name] ?? 0.0) + (count * itemQty);
            }
          });
        } else if (toppingsData is List) {
          for (var topping in toppingsData) {
            if (topping is Map) {
              final name = (topping['name'] ??
                      topping['title'] ??
                      topping['label'] ??
                      '')
                  .toString()
                  .trim();
              if (name.isNotEmpty) {
                final count = (topping['count'] ?? topping['qty'] ?? 1);
                final countDouble = (count is num) ? count.toDouble() : 1.0;
                totals[name] = (totals[name] ?? 0.0) + (countDouble * itemQty);
              }
            } else if (topping is String) {
              final name = topping.trim();
              if (name.isNotEmpty) {
                totals[name] = (totals[name] ?? 0.0) + itemQty;
              }
            }
          }
        }
      }
    }

    // Sort by usage count descending
    final topList = totals.keys.toList()
      ..sort((a, b) => totals[b]!.compareTo(totals[a]!));

    return {
      'totals': totals,
      'top': topList,
    };
  }

  Future<void> _addUser() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'user@inbento.com',
              ),
              autofocus: true,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'password',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final email = emailController.text.trim();
              final password = passwordController.text.trim();
              if (email.isNotEmpty && password.isNotEmpty) {
                Navigator.pop(context, {'user': email, 'password': password});
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null) {
      await FirebaseFirestore.instance.collection('users').add(result);
    }
  }

  Future<void> _deleteUser() async {
    if (_selectedUserDocId != null) {
      if ((_selectedUserName ?? '').toLowerCase() == _protectedUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This account cannot be deleted.')),
        );
        return;
      }
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete User'),
          content: const Text(
              'Are you sure you want to delete this user? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pink700,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_selectedUserDocId)
            .delete();
        setState(() {
          _selectedUserIndex = null;
          _selectedUserDocId = null;
          _selectedUserName = null;
        });
      }
    }
  }

  String _getCurrentTargetDate() {
    // Use the first visible period in the chart, fallback to today
    if (_salesLabels.isNotEmpty) {
      return _salesLabels.first;
    }
    DateTime now = DateTime.now();
    switch (_salesFilter) {
      case 'year':
        return DateFormat('yyyy').format(now);
      case 'months':
        return DateFormat('yyyy-MM').format(now);
      case 'days':
      default:
        return DateFormat('yyyy-MM-dd').format(now);
    }
  }

  Future<void> _loadDefaultDailyTarget() async {
    try {
      final settingsSnapshot = await FirebaseFirestore.instance
          .collection('settings')
          .doc('targetSales')
          .get();
      if (settingsSnapshot.exists && settingsSnapshot.data() != null) {
        _defaultDailyTarget =
            (settingsSnapshot.data()!['defaultDaily'] as num?)?.toDouble();
      } else {
        _defaultDailyTarget = null;
      }
    } catch (_) {
      _defaultDailyTarget = null;
    }
  }

  Future<void> _fetchTargetSaleSpots() async {
    _targetSaleSpots = [];
    final periodCollection = FirebaseFirestore.instance
        .collection('settings')
        .doc('targetSales')
        .collection('periods');

    // Fetch all daily targets at once
    final allDocs = await periodCollection.get();
    final Map<String, double> dailyTargets = {};
    for (var doc in allDocs.docs) {
      final dateStr = doc.id; // 'yyyy-MM-dd'
      final value = (doc.data()['value'] as num?)?.toDouble() ?? 0.0;
      dailyTargets[dateStr] = value;
    }

    for (int i = 0; i < _salesLabels.length; i++) {
      final label = _salesLabels[i];
      double target = 0.0;

      if (_salesFilter == 'days') {
        // Direct match
        target = dailyTargets[label] ?? (_defaultDailyTarget ?? 0.0);
      } else if (_salesFilter == 'months') {
        // Sum all daily targets in this month
        target = dailyTargets.entries
            .where((e) => e.key.startsWith(label)) // label is 'yyyy-MM'
            .fold(0.0, (double sum, e) => sum + e.value);
      } else if (_salesFilter == 'year') {
        // Sum all daily targets in this year
        target = dailyTargets.entries
            .where((e) => e.key.startsWith(label)) // label is 'yyyy'
            .fold(0.0, (double sum, e) => sum + e.value);
      }

      _targetSaleSpots.add(FlSpot(i.toDouble(), target));
    }
    setState(() {});
  }

  // Fetch target sale for current period from Firestore
  Future<void> _fetchTargetSale({int? forIndex}) async {
    setState(() => _loadingTargetSale = true);
    String period;
    if (forIndex != null &&
        _salesLabels.isNotEmpty &&
        forIndex < _salesLabels.length) {
      period = _salesLabels[forIndex];
    } else {
      period = _getCurrentTargetDate();
    }

    final periodCollection = FirebaseFirestore.instance
        .collection('settings')
        .doc('targetSales')
        .collection('periods');
    final allDocs = await periodCollection.get();

    double? target;
    if (_salesFilter == 'days') {
      final doc = allDocs.docs.where((d) => d.id == period).isNotEmpty
          ? allDocs.docs.firstWhere((d) => d.id == period)
          : null;
      if (doc != null && doc.data()['value'] != null) {
        target = (doc.data()['value'] as num).toDouble();
      } else {
        // fallback to defaultDaily if set, otherwise null
        target = _defaultDailyTarget;
      }
    } else if (_salesFilter == 'months') {
      target = allDocs.docs.where((d) => d.id.startsWith(period)).fold(0.0,
          (sum, d) => sum! + ((d.data()['value'] as num?)?.toDouble() ?? 0.0));
      if (target == 0.0) target = null;
    } else if (_salesFilter == 'year') {
      target = allDocs.docs.where((d) => d.id.startsWith(period)).fold(0.0,
          (sum, d) => sum! + ((d.data()['value'] as num?)?.toDouble() ?? 0.0));
      if (target == 0.0) target = null;
    }

    setState(() {
      _currentTargetDate = period;
      _targetSale = target;
      _loadingTargetSale = false;
    });
  }

  // Edit target sale dialog for current period
  Future<void> _editTargetSaleDialog() async {
    // Present choice: set default target sale or customize (existing calendar flow)
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Target Sale'),
        content: const Text(
            'Choose action: set a default daily target, or customize a target for a specific date.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'customize'),
            child: const Text('Customize target sale'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'default'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.pink700),
            child: const Text('Set default target sale'),
          ),
        ],
      ),
    );

    if (choice == null) return;

    // Helper to save default into settings/targetSales doc and ensure today's period exists
    Future<void> _saveDefaultDailyTarget(double value) async {
      final settingsRef =
          FirebaseFirestore.instance.collection('settings').doc('targetSales');
      await settingsRef.set({'defaultDaily': value}, SetOptions(merge: true));

      // ensure today's period doc exists so UI shows a target for today
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final periodRef = settingsRef.collection('periods').doc(todayStr);
      final doc = await periodRef.get();
      if (!doc.exists) {
        await periodRef.set({'value': value});
      }
      setState(() {
        _defaultDailyTarget = value;
      });
      await _fetchTargetSale();
      await _fetchTodaySalesAndTarget();
    }

    // If user chose default -> prompt for amount, save as default and create today's if missing
    if (choice == 'default') {
      // fetch existing default if any
      final settingsSnapshot = await FirebaseFirestore.instance
          .collection('settings')
          .doc('targetSales')
          .get();
      double? existingDefault;
      if (settingsSnapshot.exists && settingsSnapshot.data() != null) {
        existingDefault =
            (settingsSnapshot.data()!['defaultDaily'] as num?)?.toDouble();
      }

      final controller = TextEditingController(
          text: existingDefault != null
              ? existingDefault.toStringAsFixed(2)
              : '');
      final result = await showDialog<double>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Set default daily target'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Default target sale (₱)',
              hintText: 'Enter default amount for each day',
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null && value > 0) Navigator.pop(context, value);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (result != null) {
        await _saveDefaultDailyTarget(result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Default daily target saved. Today\'s target set if missing.')),
        );
      }
      return;
    }

    // If user chose customize -> run the previous calendar + value flow (unchanged)
    DateTime selectedDate = DateTime.now();
    double? targetValue;

    // Show date picker
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    selectedDate = picked;

    // Fetch existing target for that date
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('targetSales')
        .collection('periods')
        .doc(DateFormat('yyyy-MM-dd').format(selectedDate))
        .get();
    targetValue = (doc.exists && doc.data()?['value'] != null)
        ? (doc.data()!['value'] as num).toDouble()
        : null;

    final controller = TextEditingController(
      text: targetValue?.toStringAsFixed(2) ?? '',
    );

    final customResult = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Set Target Sale for ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Target Sale (₱)',
            hintText: 'Enter target sale amount',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (customResult != null) {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('targetSales')
          .collection('periods')
          .doc(DateFormat('yyyy-MM-dd').format(selectedDate))
          .set({'value': customResult});
      await _fetchTargetSale();
    }
  }

  // Fetch all unique cake names from orders
  Future<void> _fetchAllCakeNames() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('orders').get();
    final Set<String> cakeNames = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final items = await _loadOrderItems(doc.id, data);
      for (var item in items) {
        final name = item['name'];
        if (name is String) cakeNames.add(name);
      }
    }
    setState(() {
      _allCakeNames = cakeNames.toList()..sort();
      if (_selectedCakeNames.isEmpty) {
        _selectedCakeNames = List.from(_allCakeNames);
      }
    });
  }

  // Fetch sales data from Firestore and prepare chart data (by day)
  Future<void> _fetchSalesData() async {
    setState(() {
      _loadingSales = true;
    });

    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .orderBy('date')
        .get();

    Map<String, double> salesMap = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateStr = data['date'];
      // load items from subcollection or top-level cartItems via helper
      final items = await _loadOrderItems(doc.id, data);

      double filteredTotal = 0.0;

      for (var item in items) {
        final name = item['name'];
        final price = (item['price'] is int)
            ? (item['price'] as int).toDouble()
            : (item['price'] as double? ?? 0.0);
        final qty = (item['quantity'] as int? ?? 1);

        if (_selectedCakeNames.isEmpty || _selectedCakeNames.contains(name)) {
          filteredTotal += price * qty;
        }
      }

      if (filteredTotal == 0) continue;

      DateTime? date;
      if (dateStr is String) {
        try {
          date = DateTime.parse(dateStr);
        } catch (_) {
          try {
            date = DateFormat('MM/dd/yyyy').parse(dateStr);
          } catch (_) {}
        }
      } else if (dateStr is Timestamp) {
        date = dateStr.toDate();
      }

      if (date != null) {
        String label;
        switch (_salesFilter) {
          case 'months':
            label = DateFormat('yyyy-MM').format(date);
            break;
          case 'year':
            label = DateFormat('yyyy').format(date);
            break;
          case 'days':
          default:
            label = DateFormat('yyyy-MM-dd').format(date);
        }
        salesMap[label] = (salesMap[label] ?? 0) + filteredTotal;
      }
    }

    final sortedKeys = salesMap.keys.toList()..sort((a, b) => a.compareTo(b));
    final spots = <FlSpot>[];
    final labels = <String>[];
    for (int i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), salesMap[sortedKeys[i]] ?? 0));
      labels.add(sortedKeys[i]);
    }

    setState(() {
      _salesSpots = spots;
      _salesLabels = labels;
      _loadingSales = false;
    });

    await _fetchTargetSaleSpots();
  }

  // Show filter dialog for cake names
  Future<void> _showCakeFilterDialog() async {
    await _fetchAllCakeNames();
    final List<String> tempSelected = List.from(_selectedCakeNames);
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter by Cake Name'),
          content: SizedBox(
            width: 300,
            child: ListView(
              shrinkWrap: true,
              children: _allCakeNames.map((cake) {
                return CheckboxListTile(
                  value: tempSelected.contains(cake),
                  title: Text(cake),
                  onChanged: (checked) {
                    if (checked == true) {
                      tempSelected.add(cake);
                    } else {
                      tempSelected.remove(cake);
                    }
                    // Force rebuild
                    (context as Element).markNeedsBuild();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (tempSelected.isEmpty) {
                  // Prevent empty selection
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select at least one cake.')),
                  );
                  return;
                }
                Navigator.pop(context, tempSelected);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedCakeNames = result;
      });
      await _fetchSalesData();
      await _fetchTodaySalesAndTarget();
    }
  }

  Future<void> _fetchTodaySalesAndTarget() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Fetch today's orders
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('date', isGreaterThanOrEqualTo: todayStr)
        .get();

    double sales = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final items = await _loadOrderItems(doc.id, data);
      for (var item in items) {
        final name = item['name'];
        final price = (item['price'] is int)
            ? (item['price'] as int).toDouble()
            : (item['price'] as double? ?? 0.0);
        final qty = (item['quantity'] as int? ?? 1);
        if (_selectedCakeNames.isEmpty || _selectedCakeNames.contains(name)) {
          sales += price * qty;
        }
      }
    }

    // Fetch today's target
    final targetDoc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('targetSales')
        .collection('periods')
        .doc(todayStr)
        .get();
    final target = (targetDoc.exists && targetDoc.data()?['value'] != null)
        ? (targetDoc.data()!['value'] as num).toDouble()
        : (_defaultDailyTarget ?? 0.0);

    setState(() {
      _todaySales = sales;
      _todayTarget = target;
    });
  }

  // Call fetch when opening sales details
  void _showSalesDetailsScreen() {
    setState(() {
      _showSalesDetails = true;
    });
    _fetchSalesData();
    _fetchTargetSale();
  }

  // Show toppings (ingredients) usage timeline for top 5 toppings
  void _showToppingsDetailsScreen() {
    setState(() {
      _showToppingsDetails = true;
    });
    _fetchToppingsData();
  }

  void _showAboutScreen() {
    const appName = 'In Bento Cake Kiosk';
    const fullVersion = '6.0.2';
    final displayVersion = fullVersion.split('+').first;
    const repoUrl = 'https://github.com/Ndkorr/in-bento-cake-kiosk';
    const supportEmail = 'mathewastorga321@gmail.com';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('About'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            children: [
              const TiledIcons(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Inbento icon (use asset, fallback to text box)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 96,
                          height: 96,
                          child: Image.asset(
                            'assets/icons/icon.png',
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, st) => Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: Colors.black, width: 2),
                              ),
                              child: const Center(
                                child: Text(
                                  'Inbento\nIcon',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(appName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Version $displayVersion',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 20),

                      const SizedBox(height: 22),
                      const Text(
                        'A kiosk that allows customers to create, or "invent", their own unique cake/s.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text('Built with Flutter and Firebase.',
                          textAlign: TextAlign.center),

                      const SizedBox(height: 28),

                      // Licenses & Agreement button (matching Contact Support style)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side:
                                BorderSide(color: AppColors.pink700, width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            backgroundColor: Colors.white,
                          ),
                          onPressed: () {
                            showLicensePage(
                              context: context,
                              applicationName: appName,
                              applicationVersion: displayVersion,
                            );
                          },
                          child: const Text(
                            'Licenses & Agreement',
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Contact Support button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side:
                                BorderSide(color: AppColors.pink700, width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Contact Support'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Email: $supportEmail'),
                                    const SizedBox(height: 8),
                                    const Text(
                                        'For urgent help, call your support line.'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Clipboard.setData(const ClipboardData(
                                          text: supportEmail));
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Email copied to clipboard')),
                                      );
                                    },
                                    child: const Text('Copy Email'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text(
                            'Contact Support',
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                      ),

                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(
                              top: 70.0,
                              bottom: 2.0), // <-- vertical spacing here
                          child: InkWell(
                            onTap: () async {
                              final uri = Uri.parse(repoUrl);
                              final opened = await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                              if (!opened) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Could not open repository URL')),
                                );
                              }
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(
                                      6.0), // small padding around icon
                                  child: SvgPicture.asset(
                                    'assets/icons/github.svg',
                                    width: 40,
                                    height: 40,
                                    placeholderBuilder: (context) =>
                                        const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                    height: 4), // space between icon and label
                                const Text('Docs',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show about dialog with app info
  void _showAboutDialog() {
    // Values taken from pubspec.yaml
    const appName = 'In Bento Kiosk';
    const appVersion = '5.5.0+1';

    showAboutDialog(
      context: context,
      applicationName: appName,
      applicationVersion: appVersion,
      applicationLegalese: '© ${DateTime.now().year} In Bento',
      children: [
        const SizedBox(height: 8),
        const Text(
          'A kiosk that allows customers to create, or "invent", their own unique cake/s.',
        ),
        const SizedBox(height: 8),
        const Text('Built with Flutter and Firebase.'),
        const SizedBox(height: 8),
        const Text('Repository: https://github.com/Ndkorr/in-bento-cake-kiosk'),
      ],
    );
  }

  // Fetch counts of toppings by period (days/months/year) and prepare line chart data.
  Future<void> _fetchToppingsData() async {
    setState(() => _loadingToppings = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .orderBy('date')
        .get();
    // map: label -> topping -> count
    final Map<String, Map<String, int>> counts = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateStr = data['date'];
      final items = await _loadOrderItems(doc.id, data);

      DateTime? date;
      if (dateStr is String) {
        try {
          date = DateTime.parse(dateStr);
        } catch (_) {
          try {
            date = DateFormat('MM/dd/yyyy').parse(dateStr);
          } catch (_) {}
        }
      } else if (dateStr is Timestamp) {
        date = dateStr.toDate();
      }
      if (date == null) continue;

      String label;
      switch (_salesFilter) {
        case 'months':
          label = DateFormat('yyyy-MM').format(date);
          break;
        case 'year':
          label = DateFormat('yyyy').format(date);
          break;
        case 'days':
        default:
          label = DateFormat('yyyy-MM-dd').format(date);
      }

      counts.putIfAbsent(label, () => {});

      // Helpers to robustly extract topping counts from various shapes
      int _parseInt(dynamic v) {
        if (v == null) return 0;
        if (v is int) return v;
        if (v is num) return v.toInt();
        if (v is String) {
          final n = int.tryParse(v);
          if (n != null) return n;
          // try to extract number from patterns like "(x3)" or "x3"
          final m = RegExp(r'(\d+)').firstMatch(v);
          if (m != null) return int.tryParse(m.group(1)!) ?? 0;
        }
        return 0;
      }

      Map<String, int> _parseToppingsField(dynamic v) {
        final out = <String, int>{};
        if (v == null) return out;

        if (v is String) {
          // Accept formats like "Pretzels(x1), Cherries(x2)" or "Pretzels, Cherries"
          final parts = v.split(',');
          for (var p in parts) {
            final s = p.trim();
            if (s.isEmpty) continue;
            final m = RegExp(r'^(.+?)\s*\(?x?(\d+)\)?\s*$').firstMatch(s);
            if (m != null) {
              final name = m.group(1)!.trim();
              final cnt = _parseInt(m.group(2));
              out[name] = (out[name] ?? 0) + (cnt > 0 ? cnt : 1);
            } else {
              out[s] = (out[s] ?? 0) + 1;
            }
          }
          return out;
        }

        if (v is Map) {
          final name = (v['name'] ?? v['title'] ?? v['label'] ?? v['topping'])
              ?.toString();
          if (name != null && name.trim().isNotEmpty) {
            // possible count keys
            final cnt = _parseInt(v['count'] ??
                v['qty'] ??
                v['quantity'] ??
                v['amount'] ??
                v['x']);
            out[name.trim()] = (out[name.trim()] ?? 0) + (cnt > 0 ? cnt : 1);
          } else {
            // maybe it's a map of name->count already
            v.forEach((k, val) {
              if (k is String) {
                final key = k.trim();
                if (key.isEmpty) return;
                final cnt = _parseInt(val);
                if (cnt > 0) out[key] = (out[key] ?? 0) + cnt;
              }
            });
          }
          return out;
        }

        if (v is List) {
          for (var e in v) {
            final sub = _parseToppingsField(e);
            sub.forEach((k, val) => out[k] = (out[k] ?? 0) + val);
          }
          return out;
        }

        return out;
      }

      // iterate items and add counts, respecting item quantity and explicit toppingsCounts
      for (var item in items) {
        final itemQty = (item['quantity'] is int)
            ? item['quantity'] as int
            : (item['quantity'] is num)
                ? (item['quantity'] as num).toInt()
                : (item['qty'] is int)
                    ? item['qty'] as int
                    : (item['qty'] is num)
                        ? (item['qty'] as num).toInt()
                        : 1;

        // If a prepared map of toppingsCounts exists, use it directly
        if (item['toppingsCounts'] is Map) {
          final tc = Map<String, dynamic>.from(item['toppingsCounts'] as Map);
          tc.forEach((k, v) {
            final name = k.toString().trim();
            if (name.isEmpty) return;
            final cnt = _parseInt(v);
            if (cnt <= 0) return;
            counts[label]![name] = (counts[label]![name] ?? 0) + cnt * itemQty;
          });
          continue;
        }

        // Otherwise inspect candidate fields and parse counts
        final candidates = <dynamic>[
          item['toppings'],
          item['selectedToppings'],
          item['extras'],
          item['topping'],
          item['toppingsSelected'],
          item['toppingsSummary']
        ];

        final perItemCounts = <String, int>{};
        for (var c in candidates) {
          final parsed = _parseToppingsField(c);
          parsed.forEach(
              (k, v) => perItemCounts[k] = (perItemCounts[k] ?? 0) + v);
        }

        // merge perItemCounts into daily counts, multiplied by item quantity
        perItemCounts.forEach((k, v) {
          if (k.trim().isEmpty) return;
          counts[label]![k] =
              (counts[label]![k] ?? 0) + v * (itemQty > 0 ? itemQty : 1);
        });
      }
    }

    // determine sorted labels (periods)
    final labels = counts.keys.toList()..sort((a, b) => a.compareTo(b));

    // compute totals per topping to pick top 5
    final Map<String, int> totals = {};
    for (var label in labels) {
      counts[label]!.forEach((k, v) {
        totals[k] = (totals[k] ?? 0) + v;
      });
    }

    final top = totals.keys.toList()
      ..sort((a, b) => totals[b]!.compareTo(totals[a]!));
    final top5 = top.take(5).toList();

    // build spots per topping (indexed by label order)
    final Map<String, List<FlSpot>> spots = {};
    for (var t in top5) spots[t] = [];
    for (int i = 0; i < labels.length; i++) {
      final label = labels[i];
      for (var t in top5) {
        final value = counts[label] != null ? (counts[label]![t] ?? 0) : 0;
        spots[t]!.add(FlSpot(i.toDouble(), value.toDouble()));
      }
    }

    setState(() {
      _toppingsLabels = labels;
      _topToppings = top5;
      _toppingSpots = spots;
      _visibleToppings = Set.from(top5);
      _toppingsTotals = Map.fromEntries(
          totals.entries.map((e) => MapEntry(e.key, e.value.toDouble())));
      _loadingToppings = false;
    });
  }

  Widget _shimmerPieCard(
      {double height = 260, double width = double.infinity}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 6,
        child: SizedBox(
          width: width,
          height: height,
          child: Center(
            child: Container(
              height: 180,
              width: (width == double.infinity) ? 160 : width * 0.67,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _shimmerChartArea(
      {double height = 220, double width = double.infinity}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 2,
        child: SizedBox(
          height: height,
          width: width,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 12, color: Colors.white),
                const SizedBox(height: 8),
                Container(height: 12, width: 200, color: Colors.white),
                const SizedBox(height: 12),
                Expanded(child: Container(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String value, String label) {
    final isSelected = _salesFilter == value;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.pink700 : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppColors.pink700,
        side: BorderSide(color: AppColors.pink700),
      ),
      onPressed: () async {
        if (_salesFilter != value) {
          setState(() {
            _salesFilter = value;
          });
          await _fetchSalesData();
          await _fetchTargetSale();
        }
      },
      child: Text(label),
    );
  }

  // small helper for toppings period filter (updates toppings chart)
  Widget _buildToppingsFilterButton(String value, String label) {
    final isSelected = _salesFilter == value;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.pink700 : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppColors.pink700,
        side: BorderSide(color: AppColors.pink700),
      ),
      onPressed: () async {
        if (_salesFilter != value) {
          setState(() => _salesFilter = value);
          await _fetchToppingsData();
        }
      },
      child: Text(label),
    );
  }

  @override
  void initState() {
    super.initState();
    _allCakeNames = [];
    _selectedCakeNames = [];
    // Load defaultDaily first so fetches can fallback to it when needed.
    _loadDefaultDailyTarget().then((_) {
      _fetchAllCakeNames();
      _fetchTargetSale();
      _fetchTodaySalesAndTarget();
      _fetchToppingsData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSalesDetails) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Total Sales'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _showSalesDetails = false),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = constraints.maxWidth < 600
                ? constraints.maxWidth * 0.98
                : constraints.maxWidth * 0.6;
            final double cardWidth = maxWidth.clamp(320, 900);

            return Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: cardWidth,
                    minWidth: 280,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total sales',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_loadingTargetSale)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              _targetSale != null
                                  ? 'Target sale for $_currentTargetDate: ₱${_targetSale!.toStringAsFixed(2)}'
                                  : 'Target sale for $_currentTargetDate: Not set',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal,
                              ),
                            ),
                          ),

                        if (_selectedCakeNames.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              _selectedCakeNames.length == _allCakeNames.length
                                  ? 'All cakes'
                                  : _selectedCakeNames.join(', '),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        // Filter buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildFilterButton('days', 'Days'),
                            const SizedBox(width: 8),
                            _buildFilterButton('months', 'Months'),
                            const SizedBox(width: 8),
                            _buildFilterButton('year', 'Year'),
                          ],
                        ),

                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          width: double.infinity,
                          child: _loadingSales
                              ? _shimmerChartArea(height: 220)
                              : _salesSpots.isEmpty
                                  ? const Center(child: Text('No sales data'))
                                  : Builder(
                                      builder: (context) {
                                        // Calculate minY and maxY outside the widget tree
                                        final allYValues = [
                                          ..._salesSpots.map((e) => e.y),
                                          ..._targetSaleSpots.map((e) => e.y),
                                        ];
                                        final minY = allYValues.isNotEmpty
                                            ? allYValues
                                                .reduce((a, b) => a < b ? a : b)
                                            : 0.0;
                                        final maxY = allYValues.isNotEmpty
                                            ? allYValues
                                                .reduce((a, b) => a > b ? a : b)
                                            : 30.0;

                                        return LineChart(
                                          LineChartData(
                                            lineTouchData: LineTouchData(
                                              touchCallback:
                                                  (FlTouchEvent event,
                                                      LineTouchResponse?
                                                          touchResponse) async {
                                                if (touchResponse != null &&
                                                    touchResponse
                                                            .lineBarSpots !=
                                                        null &&
                                                    touchResponse.lineBarSpots!
                                                        .isNotEmpty) {
                                                  final idx = touchResponse
                                                      .lineBarSpots!.first.x
                                                      .toInt();
                                                  setState(() {
                                                    _selectedSalesIndex = idx;
                                                  });
                                                  await _fetchTargetSale(
                                                      forIndex: idx);
                                                }
                                              },
                                            ),
                                            gridData: FlGridData(show: true),
                                            titlesData: FlTitlesData(
                                              leftTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 48,
                                                  getTitlesWidget:
                                                      (value, meta) {
                                                    if (_salesSpots.isEmpty)
                                                      return const SizedBox
                                                          .shrink();

                                                    final minYLocal =
                                                        _salesSpots
                                                            .map((e) => e.y)
                                                            .reduce((a, b) =>
                                                                a < b ? a : b);
                                                    final maxYLocal =
                                                        _salesSpots
                                                            .map((e) => e.y)
                                                            .reduce((a, b) =>
                                                                a > b ? a : b);

                                                    // If min and max are the same, just show that value
                                                    if ((maxYLocal - minYLocal)
                                                            .abs() <
                                                        1e-2) {
                                                      if ((value - minYLocal)
                                                              .abs() <
                                                          1e-2) {
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 8.0),
                                                          child: Text(
                                                            value
                                                                .toInt()
                                                                .toString(),
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12),
                                                            textAlign:
                                                                TextAlign.right,
                                                          ),
                                                        );
                                                      }
                                                      return const SizedBox
                                                          .shrink();
                                                    }

                                                    // Always show 5 evenly spaced ticks for all filters
                                                    final step = (maxYLocal -
                                                            minYLocal) /
                                                        4;
                                                    final ticks = List.generate(
                                                        5,
                                                        (i) =>
                                                            minYLocal +
                                                            step * i);

                                                    // Show only if value is close to a tick (avoid floating point issues)
                                                    for (final tick in ticks) {
                                                      if ((value - tick).abs() <
                                                          step / 2) {
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 8.0),
                                                          child: Text(
                                                            tick
                                                                .round()
                                                                .toString(),
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12),
                                                            textAlign:
                                                                TextAlign.right,
                                                          ),
                                                        );
                                                      }
                                                    }
                                                    return const SizedBox
                                                        .shrink();
                                                  },
                                                ),
                                              ),
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 48,
                                                  interval:
                                                      (_salesLabels.length / 2)
                                                          .ceilToDouble()
                                                          .clamp(1, 999),
                                                  getTitlesWidget:
                                                      (value, meta) {
                                                    int idx = value.toInt();
                                                    // Only show first, last, and every Nth label
                                                    if (_salesLabels.isEmpty)
                                                      return const SizedBox
                                                          .shrink();
                                                    if (idx == 0 ||
                                                        idx ==
                                                            _salesLabels
                                                                    .length -
                                                                1 ||
                                                        idx %
                                                                ((_salesLabels
                                                                            .length /
                                                                        4)
                                                                    .ceil()) ==
                                                            0) {
                                                      final date =
                                                          DateTime.tryParse(
                                                              _salesLabels[
                                                                  idx]);
                                                      return Text(
                                                        date != null
                                                            ? DateFormat(
                                                                    'd MMM')
                                                                .format(date)
                                                            : _salesLabels[idx],
                                                        style: const TextStyle(
                                                            fontSize: 11),
                                                      );
                                                    }
                                                    return const SizedBox
                                                        .shrink();
                                                  },
                                                ),
                                              ),
                                              rightTitles: const AxisTitles(
                                                  sideTitles: SideTitles(
                                                      showTitles: false)),
                                              topTitles: const AxisTitles(
                                                  sideTitles: SideTitles(
                                                      showTitles: false)),
                                            ),
                                            borderData:
                                                FlBorderData(show: false),
                                            minX: 0,
                                            maxX: _salesSpots.isNotEmpty
                                                ? (_salesSpots.length - 1)
                                                    .toDouble()
                                                : 4,
                                            minY: minY > 0 ? minY - 10 : 0,
                                            maxY: maxY + 10,
                                            lineBarsData: [
                                              LineChartBarData(
                                                spots: _salesSpots,
                                                isCurved: true,
                                                color: AppColors.pink700,
                                                barWidth: 3,
                                                dotData:
                                                    const FlDotData(show: true),
                                              ),
                                              if (_targetSaleSpots.isNotEmpty)
                                                LineChartBarData(
                                                  spots: _targetSaleSpots,
                                                  isCurved: false,
                                                  color: Colors.teal,
                                                  barWidth: 2,
                                                  dotData: const FlDotData(
                                                      show: false),
                                                  dashArray: [8, 4],
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                        ),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, btnConstraints) {
                            if (btnConstraints.maxWidth < 500) {
                              return Column(
                                children: [
                                  AnimatedHoverButton(
                                    label: 'Filter',
                                    icon: Icons.filter_alt,
                                    onTap: _showCakeFilterDialog,
                                  ),
                                  const SizedBox(height: 12),
                                  AnimatedHoverButton(
                                    label: 'Edit target sale',
                                    icon: Icons.edit,
                                    onTap: _editTargetSaleDialog,
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: AnimatedHoverButton(
                                    label: 'Filter',
                                    icon: Icons.filter_alt,
                                    onTap: _showCakeFilterDialog,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AnimatedHoverButton(
                                    label: 'Edit target sale',
                                    icon: Icons.edit,
                                    onTap: _editTargetSaleDialog,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () =>
                              setState(() => _showSalesDetails = false),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    if (_showToppingsDetails) {
      // simple multi-line chart for the top 5 toppings
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ingredients usage'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _showToppingsDetails = false),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Favorite toppings placed',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    // Date display similar to sales
                    if (_selectedToppingIndex != null &&
                        _toppingsLabels.isNotEmpty &&
                        _selectedToppingIndex! < _toppingsLabels.length)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Favorite toppings on: ${_toppingsLabels[_selectedToppingIndex!]}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal,
                          ),
                        ),
                      )
                    else if (_toppingsLabels.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Favorite toppings on: ${_toppingsLabels.first}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    // period filter for toppings chart
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildToppingsFilterButton('days', 'Days'),
                        const SizedBox(width: 8),
                        _buildToppingsFilterButton('months', 'Months'),
                        const SizedBox(width: 8),
                        _buildToppingsFilterButton('year', 'Year'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_loadingToppings)
                      SizedBox(
                        width: double.infinity,
                        child: _shimmerChartArea(height: 300),
                      )
                    else if (_toppingSpots.isEmpty || _topToppings.isEmpty)
                      const Center(child: Text('No toppings data'))
                    else
                      SizedBox(
                        height: 300,
                        child: Builder(
                          builder: (context) {
                            // collect all Y values across toppings to compute min/max
                            final allY = <double>[];
                            for (final spots in _toppingSpots.values) {
                              for (final s in spots) allY.add(s.y);
                            }
                            final minY = allY.isNotEmpty
                                ? allY.reduce((a, b) => a < b ? a : b)
                                : 0.0;
                            final maxY = allY.isNotEmpty
                                ? allY.reduce((a, b) => a > b ? a : b)
                                : 30.0;

                            return LineChart(
                              LineChartData(
                                lineTouchData: LineTouchData(
                                  touchCallback: (FlTouchEvent event,
                                      LineTouchResponse? touchResponse) {
                                    if (touchResponse != null &&
                                        touchResponse.lineBarSpots != null &&
                                        touchResponse
                                            .lineBarSpots!.isNotEmpty) {
                                      final idx = touchResponse
                                          .lineBarSpots!.first.x
                                          .toInt();
                                      setState(() {
                                        _selectedToppingIndex = idx;
                                      });
                                    }
                                  },
                                ),
                                gridData: FlGridData(show: true),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 48,
                                      getTitlesWidget: (value, meta) {
                                        if (_toppingSpots.isEmpty)
                                          return const SizedBox.shrink();
                                        final minYLocal = minY;
                                        final maxYLocal = maxY;
                                        if ((maxYLocal - minYLocal).abs() <
                                            1e-2) {
                                          if ((value - minYLocal).abs() <
                                              1e-2) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: Text(
                                                  value.toInt().toString(),
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                  textAlign: TextAlign.right),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        }
                                        final step =
                                            (maxYLocal - minYLocal) / 4;
                                        final ticks = List.generate(
                                            5, (i) => minYLocal + step * i);
                                        for (final tick in ticks) {
                                          if ((value - tick).abs() < step / 2) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: Text(
                                                  tick.round().toString(),
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                  textAlign: TextAlign.right),
                                            );
                                          }
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 48,
                                      interval: (_toppingsLabels.length / 2)
                                          .ceilToDouble()
                                          .clamp(1, 999),
                                      getTitlesWidget: (value, meta) {
                                        final idx = value.toInt();
                                        if (_toppingsLabels.isEmpty)
                                          return const SizedBox.shrink();
                                        if (idx < 0 ||
                                            idx >= _toppingsLabels.length)
                                          return const SizedBox.shrink();
                                        if (idx == 0 ||
                                            idx == _toppingsLabels.length - 1 ||
                                            idx %
                                                    ((_toppingsLabels.length /
                                                            4)
                                                        .ceil()) ==
                                                0) {
                                          final label = _toppingsLabels[idx];
                                          if (_salesFilter == 'days') {
                                            final d = DateTime.tryParse(label);
                                            if (d != null)
                                              return Text(
                                                  DateFormat('d MMM').format(d),
                                                  style: const TextStyle(
                                                      fontSize: 11));
                                          }
                                          return Text(label,
                                              style: const TextStyle(
                                                  fontSize: 11));
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                minX: 0,
                                maxX: _toppingsLabels.isNotEmpty
                                    ? (_toppingsLabels.length - 1).toDouble()
                                    : 4,
                                minY: 0, 
                                maxY: maxY + 1,
                                lineBarsData:
                                    List.generate(_topToppings.length, (i) {
                                  final name = _topToppings[i];
                                  // if user toggled this topping off, skip rendering it
                                  if (!_visibleToppings.contains(name))
                                    return LineChartBarData(
                                        spots: [],
                                        isCurved: true,
                                        color: Colors.transparent,
                                        barWidth: 0);
                                  final spots = _toppingSpots[name] ?? [];
                                  final color =
                                      _toppingColors[i % _toppingColors.length];
                                  return LineChartBarData(
                                    spots: spots,
                                    isCurved: true,
                                    color: color,
                                    barWidth: 3,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter:
                                          (spot, percent, barData, index) {
                                        return FlDotCirclePainter(
                                          radius: 4,
                                          color: color,
                                          strokeWidth: 2,
                                          strokeColor: Colors.white,
                                        );
                                      },
                                    ),
                                  );
                                }),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    // legend
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: List.generate(_topToppings.length, (i) {
                        final name = _topToppings[i];
                        final color = _toppingColors[i % _toppingColors.length];
                        final visible = _visibleToppings.contains(name);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (visible) {
                                _visibleToppings.remove(name);
                              } else {
                                _visibleToppings.add(name);
                              }
                            });
                          },
                          child: Chip(
                            backgroundColor: visible
                                ? color.withOpacity(0.12)
                                : Colors.grey.shade200,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  color: visible
                                      ? color.withOpacity(0.35)
                                      : Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            avatar: CircleAvatar(
                              radius: 8,
                              backgroundColor:
                                  visible ? color : Colors.grey.shade400,
                            ),
                            label: Text(
                              name,
                              style: TextStyle(
                                color:
                                    visible ? Colors.black87 : Colors.black45,
                                fontWeight: visible
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          setState(() => _showToppingsDetails = false),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (_showOrdersManager) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _hideManageOrders,
          ),
        ),
        body: Stack(
          children: [
            const TiledIcons(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .orderBy('orderNumber', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(child: Text('No orders found.'));
                    }
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final orderId = docs[index].id;
                        final orderNumber = data['orderNumber'] ?? 0;
                        final orderType = data['orderType'] ?? 'Unknown';
                        final total = data['total'];
                        final date = data['date'] ?? '';

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedOrderIndex = index;
                              _selectedUserName = data['user']?.toString();
                              _selectedUserDocId = docs[index].id;
                            });
                          },
                          onDoubleTap: () async {
                            final items = await _loadOrderItems(orderId, data);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReceiptScreen(
                                  cartItems: items,
                                  orderType: orderType,
                                  orderNumber: orderNumber,
                                  showDoneButton: false,
                                  fromStaff: true,
                                ),
                              ),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.ease,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: _selectedOrderIndex == index
                                  ? Colors.pink[50]
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: _selectedOrderIndex == index
                                  ? Border.all(
                                      color: AppColors.pink700, width: 2)
                                  : null,
                            ),
                            child: ListTile(
                              title: Text(
                                  'Order #${orderNumber.toString().padLeft(5, '0')}'),
                              subtitle: Text('Type: $orderType\nDate: $date'),
                              trailing: Text(
                                total != null
                                    ? '₱${(total is int ? total.toDouble() : total as double).toStringAsFixed(2)}'
                                    : '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_showUserManager) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Users'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _hideManageUsers,
          ),
        ),
        body: Stack(
          children: [
            const TiledIcons(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final docs = snapshot.data!.docs;
                          return ListView.separated(
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final data =
                                  docs[index].data() as Map<String, dynamic>;
                              final selected = _selectedUserIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedUserIndex = index;
                                    _selectedUserDocId = docs[index].id;
                                    _selectedUserName =
                                        (data['user'] ?? '').toString();
                                  });
                                },
                                onDoubleTap: () async {
                                  final selName = (data['user'] ?? '')
                                      .toString()
                                      .toLowerCase();
                                  if (selName == _protectedUser) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'This account cannot be edited.')),
                                    );
                                    return;
                                  }
                                  final emailController = TextEditingController(
                                      text: data['user'] ?? '');
                                  final passwordController =
                                      TextEditingController(
                                          text: data['password'] ?? '');
                                  final result =
                                      await showDialog<Map<String, String>>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Edit User'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: emailController,
                                            decoration: const InputDecoration(
                                              labelText: 'Email',
                                              hintText: 'user@inbento.com',
                                            ),
                                          ),
                                          TextField(
                                            controller: passwordController,
                                            decoration: const InputDecoration(
                                              labelText: 'Password',
                                              hintText: 'password',
                                            ),
                                            obscureText: true,
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final email =
                                                emailController.text.trim();
                                            final password =
                                                passwordController.text.trim();
                                            if (email.isNotEmpty &&
                                                password.isNotEmpty) {
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: const Text(
                                                      'Save Changes'),
                                                  content: const Text(
                                                      'Are you sure you want to save these changes?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child:
                                                          const Text('Cancel'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            AppColors.pink700,
                                                      ),
                                                      child: const Text('Save'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                Navigator.pop(context, {
                                                  'user': email,
                                                  'password': password
                                                });
                                              }
                                            }
                                          },
                                          child: const Text('Save'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (result != null) {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(docs[index].id)
                                        .update(result);
                                    setState(() {
                                      _selectedUserName =
                                          result['user']?.toString();
                                    });
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.ease,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: selected
                                        ? Border.all(
                                            color: AppColors.pink700,
                                            width: 2,
                                          )
                                        : null,
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.pink700
                                                  .withOpacity(0.15),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      data['user'] ?? '',
                                      style: TextStyle(
                                        fontWeight: selected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: selected
                                            ? AppColors.pink700
                                            : Colors.black,
                                      ),
                                    ),
                                    selected: selected,
                                    trailing: selected
                                        ? const Icon(Icons.check_circle,
                                            color: AppColors.pink700)
                                        : null,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedHoverButton(
                            label: 'Add',
                            icon: Icons.person_add,
                            onTap: _addUser,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AnimatedHoverButton(
                            label: 'Delete',
                            icon: Icons.delete,
                            onTap: (_selectedUserDocId != null &&
                                    (_selectedUserName?.toLowerCase() !=
                                        _protectedUser))
                                ? _deleteUser
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_showEditKiosk && !_showMenuManager) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.cream200,
          elevation: 0,
          title:
              const Text('Edit Kiosk', style: TextStyle(color: Colors.black)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _hideEditKioskOptions,
          ),
        ),
        backgroundColor: AppColors.cream200,
        body: Stack(
          children: [
            const TiledIcons(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedHoverButton(
                    label: 'Menu',
                    icon: Icons.restaurant_menu,
                    onTap: _showMenuManagerScreen,
                  ),
                  const SizedBox(height: 16),
                  AnimatedHoverButton(
                    label: 'Reset order count',
                    icon: Icons.refresh,
                    onTap: _resetOrderCount,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_showMenuManager) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.cream200,
          elevation: 0,
          title:
              const Text('Menu Manager', style: TextStyle(color: Colors.black)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _hideMenuManagerScreen,
          ),
        ),
        backgroundColor: AppColors.cream200,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_selectedComboIndex != null)
                    ElevatedButton.icon(
                      onPressed: _updateMenuCombo,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pink700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _menuCombos.isEmpty
                    ? const Center(
                        child: Text(
                          'No combos available.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _menuCombos.length,
                        itemBuilder: (context, index) {
                          final combo = _menuCombos[index];
                          final isSelected = _selectedComboIndex == index;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedComboIndex = index;
                                _selectedComboDocId = combo['id'];
                              });
                            },
                            onDoubleTap: _updateMenuCombo,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.pink700
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.cream200,
                                          AppColors.peach300.withAlpha(77),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.cake,
                                      color: AppColors.salmon400,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          combo['name'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            fontStyle: FontStyle.italic,
                                            color: AppColors.pink700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          combo['description'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.pink500,
                                          AppColors.salmon400,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '₱${combo['price'].toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream200,
      appBar: AppBar(
        backgroundColor: AppColors.cream200,
        elevation: 0,
        title: const Text('Staff Panel', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          const TiledIcons(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildTodaySalesPieLive(),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildToppingsUsedPieLive(),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                AnimatedHoverButton(
                  label: 'Orders',
                  icon: Icons.receipt_long,
                  onTap: _showManageOrders,
                ),
                const SizedBox(height: 16),
                AnimatedHoverButton(
                    label: 'Edit kiosk',
                    icon: Icons.edit,
                    onTap: _showEditKioskOptions),
                const SizedBox(height: 16),
                AnimatedHoverButton(
                  label: 'Manage users',
                  icon: Icons.people,
                  onTap: _showManageUsers,
                ),
                const SizedBox(height: 16),
                AnimatedHoverButton(
                    label: 'About',
                    icon: Icons.info_outline,
                    onTap: _showAboutScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySalesPieLive() {
  final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('orders')
        .where('date', isGreaterThanOrEqualTo: todayStr)
        .snapshots(),
    builder: (context, orderSnapshot) {
      if (!orderSnapshot.hasData) {
        return _shimmerPieCard();
      }

      final computeFuture = _computeSalesFromDocs(orderSnapshot.data!.docs);

      return FutureBuilder<double>(
        future: computeFuture,
        builder: (context, salesSnapshot) {
          if (!salesSnapshot.hasData) {
            return _shimmerPieCard();
          }
          final sales = salesSnapshot.data ?? 0.0;

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('settings')
                .doc('targetSales')
                .collection('periods')
                .doc(todayStr)
                .snapshots(),
            builder: (context, targetSnapshot) {
              // Prefer an explicit period document value; otherwise fall back to the cached defaultDaily value
              double target = 0.0;
              if (targetSnapshot.hasData &&
                  targetSnapshot.data!.exists &&
                  targetSnapshot.data!.data() != null) {
                final data = targetSnapshot.data!.data() as Map<String, dynamic>;
                target = (data['value'] as num?)?.toDouble() ?? (_defaultDailyTarget ?? 0.0);
              } else {
                // No per-day doc: use the in-memory default if available
                target = _defaultDailyTarget ?? 0.0;
              }
              
              // Don't clamp values - allow sales to exceed target
              final achieved = target > 0 ? sales : 0.0;
              final remaining = target > 0 ? (target - sales).clamp(0, double.infinity) : 0.0;
              final percent = target > 0 ? (sales / target * 100) : 0.0;

              final List<PieChartSectionData> sections;
              String info;
              if (target <= 0 && sales <= 0) {
                sections = [
                  PieChartSectionData(
                    color: Colors.grey.shade300,
                    value: 1.0,
                    title: '',
                    radius: 48,
                  ),
                ];
                info = 'No sales yet for today';
              } else if (sales >= target && target > 0) {
                // Sales exceeded target - show 100% (or more) in achieved section
                sections = [
                  PieChartSectionData(
                    color: AppColors.pink500,
                    value: 1.0,
                    title: '${percent.toStringAsFixed(0)}%',
                    radius: 48,
                    titleStyle: const TextStyle(
                        fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ];
                info = 'Today\'s sales: ₱${sales.toStringAsFixed(2)}\n'
                    'Target: ₱${target.toStringAsFixed(2)}\n'
                    'Achieved: ${percent.toStringAsFixed(1)}%';
              } else {
                sections = [
                  PieChartSectionData(
                    color: AppColors.pink500,
                    value: achieved.toDouble(),
                    title: '${percent.toStringAsFixed(0)}%',
                    radius: 48,
                    titleStyle: const TextStyle(
                        fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    color: AppColors.salmon400,
                    value: remaining.toDouble(),
                    title: '',
                    radius: 48,
                  ),
                ];
                info = 'Today\'s sales: ₱${sales.toStringAsFixed(2)}\n'
                    'Target: ₱${target.toStringAsFixed(2)}\n'
                    'Achieved: ${percent.toStringAsFixed(1)}%';
              }

              return _HoverPieCard(
                title: 'Total Sales',
                pie: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 24,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
                onDoubleTap: _showSalesDetailsScreen,
                info: info,
              );
            },
          );
        },
      );
    },
  );
}

  Widget _buildToppingsUsedPieLive() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('date')
          .snapshots(),
      builder: (context, orderSnapshot) {
        if (!orderSnapshot.hasData) {
          return _shimmerPieCard();
        }

        final computeFuture =
            _computeToppingsTotalsFromDocs(orderSnapshot.data!.docs);

        return FutureBuilder<Map<String, dynamic>>(
          future: computeFuture,
          builder: (context, toppingsSnapshot) {
            if (!toppingsSnapshot.hasData) {
              return _shimmerPieCard();
            }

            final data = toppingsSnapshot.data!;
            final totals = data['totals'] as Map<String, double>;
            final topList = data['top'] as List<String>;

            // Build pie sections for top 5 toppings
            final sections = <PieChartSectionData>[];
            final toppingsForPie = topList.take(5).toList();

            double total = 0.0;
            for (var name in toppingsForPie) {
              total += totals[name] ?? 0.0;
            }

            for (int i = 0; i < toppingsForPie.length; i++) {
              final name = toppingsForPie[i];
              final value = totals[name] ?? 0.0;
              final color = _toppingColors[i % _toppingColors.length];
              final percent = total > 0 ? value / total * 100.0 : 0.0;
              final title = percent >= 1.0 ? '${percent.round()}%' : '';

              sections.add(PieChartSectionData(
                color: color,
                value: value > 0 ? value : 0.0001,
                title: title,
                radius: 44,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ));
            }

            // Determine favorite topping
            String info = 'Customer\'s Favorite Topping: -';
            if (totals.isNotEmpty) {
              final best =
                  totals.entries.reduce((a, b) => a.value >= b.value ? a : b);
              info =
                  'Customer\'s Favorite Topping: ${best.key} (${best.value.toInt()})';
            }

            return _HoverPieCard(
              title: 'Toppings Used',
              pie: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 18,
                  sectionsSpace: 2,
                  borderData: FlBorderData(show: false),
                ),
              ),
              onDoubleTap: _showToppingsDetailsScreen,
              info: info,
            );
          },
        );
      },
    );
  }
}

class _HoverPieCard extends StatefulWidget {
  final String title;
  final Widget pie;
  final VoidCallback? onDoubleTap;
  final String? info;

  const _HoverPieCard({
    required this.title,
    required this.pie,
    this.onDoubleTap,
    this.info,
  });

  @override
  State<_HoverPieCard> createState() => _HoverPieCardState();
}

class _HoverPieCardState extends State<_HoverPieCard> {
  bool _hovering = false;

  void _showInfoDialog() {
    if (widget.info != null) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(widget.title),
                content: SingleChildScrollView(
                  child: Text(
                    widget.info!,
                    softWrap: true,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        const double cardHeight = 260;
        const double borderExtension = 30;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.ease,
              bottom: _hovering ? -borderExtension : -60,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _hovering ? 1.0 : 0.0,
                child: Container(
                  width: cardWidth + 10,
                  height: 275 + borderExtension,
                  decoration: BoxDecoration(
                    color: AppColors.pink700,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.pink700.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            MouseRegion(
              onEnter: (_) => setState(() => _hovering = true),
              onExit: (_) => setState(() => _hovering = false),
              child: GestureDetector(
                onDoubleTap: widget.onDoubleTap,
                onLongPressStart: (_) => setState(() => _hovering = true),
                onLongPressEnd: (_) {
                  if (mounted) setState(() => _hovering = false);
                },
                child: Tooltip(
                  message: widget.info ?? '',
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 6,
                    child: SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: Center(
                        child: SizedBox(
                          height: 180,
                          width: cardWidth * 0.67,
                          child: widget.pie,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PieCard extends StatelessWidget {
  final String title;
  final Widget pie;

  const _PieCard({required this.title, required this.pie});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 6,
      child: SizedBox(
        width: 240, // Increased width
        height: 260, // Increased height
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 180, // Increased pie chart size
              width: 160,
              child: pie,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20, // Larger title
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SamplePieChart extends StatelessWidget {
  final List<PieChartSectionData> sections;

  const _SamplePieChart({required this.sections});

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 24,
        sectionsSpace: 2,
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class AnimatedHoverButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const AnimatedHoverButton({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
  });

  @override
  State<AnimatedHoverButton> createState() => _AnimatedHoverButtonState();
}

class _AnimatedHoverButtonState extends State<AnimatedHoverButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Colors from your theme
    final redGradient = const LinearGradient(
      colors: [AppColors.pink500, AppColors.salmon400],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          if (widget.onTap != null) widget.onTap!();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.ease,
          decoration: BoxDecoration(
            gradient: _isPressed ? redGradient : null,
            color: _isPressed
                ? null
                : _isHovered
                    ? Colors.grey[100]
                    : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.pink700,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: _isPressed ? Colors.white : AppColors.pink700,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isPressed ? Colors.white : AppColors.pink700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
