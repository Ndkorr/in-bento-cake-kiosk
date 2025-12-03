// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';
import 'cake_details_screen.dart';
import 'payment_method_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.orderType});

  final String orderType; // 'Dine In' or 'Takeout'

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  int? _selectedCakeIndex;
  final Map<int, int> _cart = {}; // cakeIndex -> quantity
  List<Map<String, dynamic>> _customCakes = []; // Cart from customizer
  bool _loadingCakes = false;

  // Keys for animation
  final Map<int, GlobalKey> _cakeCardKeys = {};
  final GlobalKey _cartIconKey = GlobalKey();

  // Cakes loaded from Firestore
  List<Map<String, dynamic>> _cakes = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _loadCakesFromFirestore();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadCakesFromFirestore() async {
    setState(() => _loadingCakes = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('menuCombos')
          .orderBy('name', descending: true)
          .get();

      final items = snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'name': data['name'] ?? 'Unknown',
          'description': data['description'] ?? '',
          'price': (data['price'] as num?)?.toDouble() ?? 0.0,
          'image': data['image'] ?? 'assets/images/cake_1.png',
        };
      }).toList();

      setState(() {
        _cakes = items;
        _loadingCakes = false;
        _selectedCakeIndex = null;
      });
    } catch (e) {
      debugPrint('Error loading menuCombos: $e');
      setState(() => _loadingCakes = false);
    }
  }

  double get _totalPrice {
    double total = 0;
    _cart.forEach((cakeIndex, quantity) {
      total += _cakes[cakeIndex]['price'] * quantity;
    });
    // Add custom cakes price
    for (var cake in _customCakes) {
      final price = cake['cakePrice'] ?? 0.0;
      final quantity = cake['quantity'] ?? 1;
      total += price * quantity;
    }
    return total;
  }

  int get _totalItems {
    int presetCakes = _cart.values.fold(0, (sum, quantity) => sum + quantity);
    int customCakes = _customCakes.fold(
        0, (sum, cake) => sum + (cake['quantity'] ?? 1) as int);
    return presetCakes + customCakes;
  }

  void _addToCart() {
    if (_selectedCakeIndex != null) {
      // Run the animation
      _runAddToCartAnimation();
      // Update the cart state
      setState(() {
        _cart[_selectedCakeIndex!] = (_cart[_selectedCakeIndex!] ?? 0) + 1;
      });
    }
  }

  void _runAddToCartAnimation() async {
    if (_selectedCakeIndex == null) return;

    // Get the RenderBox of the cake card and the cart icon
    final cardKey = _cakeCardKeys[_selectedCakeIndex!];
    final cartKey = _cartIconKey;

    final cardRenderBox =
        cardKey?.currentContext?.findRenderObject() as RenderBox?;
    final cartRenderBox =
        cartKey.currentContext?.findRenderObject() as RenderBox?;

    if (cardRenderBox == null || cartRenderBox == null) return;

    // Get global positions
    final cardPosition = cardRenderBox.localToGlobal(Offset.zero);
    final cartPosition = cartRenderBox.localToGlobal(Offset.zero);

    // Create an overlay entry
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return _FlyingCakeAnimation(
          startPosition: cardPosition,
          endPosition: cartPosition,
          cakeImage: _cakes[_selectedCakeIndex!]['image'],
          cardSize: cardRenderBox.size,
          onCompleted: () {
            overlayEntry.remove();
          },
        );
      },
    );

    // Add the overlay entry to the overlay
    overlay.insert(overlayEntry);
  }

  void _updateQuantity(int cakeIndex, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _cart.remove(cakeIndex);
      } else {
        _cart[cakeIndex] = newQuantity;
      }
    });
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return _CartOverlay(
              cart: _cart,
              cakes: _cakes,
              customCakes: _customCakes,
              onUpdateQuantity: (cakeIndex, newQuantity) {
                // Update the main screen's state
                _updateQuantity(cakeIndex, newQuantity);
                // Also update the modal's state to reflect changes immediately
                setModalState(() {});
              },
              onRemoveCustomCake: (index) {
                setState(() {
                  _customCakes.removeAt(index);
                });
                setModalState(() {});
              },
              onUpdateCustomCakeQuantity: (index, change) {
                setState(() {
                  final currentQuantity = _customCakes[index]['quantity'] ?? 1;
                  final newQuantity = currentQuantity + change;
                  if (newQuantity > 0) {
                    _customCakes[index]['quantity'] = newQuantity;
                  }
                });
                setModalState(() {});
              },
              totalPrice: _totalPrice,
              orderType: widget.orderType,
              rootScaffoldMessengerContext: this.context,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with tiled icons
          const _TiledIcons(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Cake Grid
                Expanded(child: _buildCakeGrid()),
              ],
            ),
          ),

          // Bottom bar with Add to Cart & Cart Icon
          if (_selectedCakeIndex != null)
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: _BottomCartBar(
                selectedCake: _cakes[_selectedCakeIndex!],
                cartItemCount: _totalItems,
                totalPrice: _totalPrice,
                onAddToCart: _addToCart,
                onShowCart: _showCart,
                cartIconKey: _cartIconKey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
            onPressed: () => Navigator.pop(context),
            color: AppColors.pink700,
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Your Cake',
                  style: GoogleFonts.ubuntu(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.pink700,
                  ),
                ),
                Text(
                  'Order Type: ${widget.orderType}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          // Logo with pulsating background
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.pink500.withAlpha(
                        (255 * (0.1 + (_pulseController.value * 0.15))).round(),
                      ),
                      AppColors.peach300.withAlpha(
                        (255 * (0.1 + (_pulseController.value * 0.15))).round(),
                      ),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: child,
              );
            },
            child: Image.asset(
              'assets/icons/icon-original.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.cake, color: AppColors.pink500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCakeGrid() {
    if (_loadingCakes) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.pink700),
      );
    }
    if (_cakes.isEmpty) {
      return const Center(
        child: Text(
          'No cakes available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final crossAxisCount = isLandscape ? 3 : 2;
        final aspectRatio = isLandscape ? 1.2 : 0.75;

        return GridView.builder(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: _selectedCakeIndex != null
                ? 140
                : 24, // Extra padding for bottom bar
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          itemCount: _cakes.length,
          itemBuilder: (context, index) {
            // Ensure a key exists for each card
            _cakeCardKeys.putIfAbsent(index, () => GlobalKey());

            return Hero(
              tag: 'cake_card_$index',
              child: CakeCard(
                key: _cakeCardKeys[index],
                cake: _cakes[index],
                isSelected: _selectedCakeIndex == index,
                isLandscape: isLandscape,
                onTap: () {
                  setState(() {
                    _selectedCakeIndex = index;
                  });
                },
                onViewTap: () async {
                  final returnedCart =
                      await Navigator.push<List<Map<String, dynamic>>>(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 500),
                      pageBuilder: (_, __, ___) => CakeDetailsScreen(
                        cake: _cakes[index],
                        cakeIndex: index,
                        initialCartItems: _customCakes,
                      ),
                      transitionsBuilder: (_, animation, __, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
                  );

                  // Update custom cakes cart when returning
                  if (returnedCart != null && mounted) {
                    setState(() {
                      _customCakes = returnedCart.map((cake) {
                        final comboNames = ['Combo A', 'Combo B', 'Combo C'];
                        final selectedCakeName = _cakes[index]['name'];
                        // Ensure selectedToppings is always a List<String>
                        final selectedToppings =
                            (cake['selectedToppings'] as List?)
                                    ?.cast<String>() ??
                                [];

                        if ((cake['name'] == null || cake['name'] == '') &&
                            comboNames.contains(selectedCakeName)) {
                          return {
                            ...cake,
                            'name': selectedCakeName,
                            'description': _cakes[index]['description'] ?? '',
                            'isCustom': true,
                            'selectedToppings': selectedToppings,
                          };
                        }
                        if (cake['isCustom'] == null ||
                            cake['selectedToppings'] == null) {
                          return {
                            ...cake,
                            'isCustom': true,
                            'selectedToppings': selectedToppings,
                          };
                        }
                        return cake;
                      }).toList();
                    });
                  }
                },
                viewButtonText: 'View',
              ),
            );
          },
        );
      },
    );
  }
}

/// Bottom bar with Add to Cart button and Cart icon
class _BottomCartBar extends StatelessWidget {
  const _BottomCartBar({
    required this.selectedCake,
    required this.cartItemCount,
    required this.totalPrice,
    required this.onAddToCart,
    required this.onShowCart,
    required this.cartIconKey,
  });

  final Map<String, dynamic> selectedCake;
  final int cartItemCount;
  final double totalPrice;
  final VoidCallback onAddToCart;
  final VoidCallback onShowCart;
  final GlobalKey cartIconKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(38),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Add to Cart Button
          Expanded(
            child: _MenuActionButton(
              onTap: onAddToCart,
              gradient: const LinearGradient(
                colors: [AppColors.pink500, AppColors.salmon400],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_shopping_cart, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Add to Cart',
                    style: TextStyle(
                      fontFamily: 'Ubuntu',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Cart Icon with badge and price
          _MenuActionButton(
            key: cartIconKey,
            onTap: onShowCart,
            gradient: const LinearGradient(
              colors: [AppColors.pink500, AppColors.salmon400],
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart, size: 24),
                    if (cartItemCount > 0)
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            '$cartItemCount',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ubuntu(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.pink700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (totalPrice > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '₱${totalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A styled button that mimics the OrderTypeButton from the welcome screen.
class _MenuActionButton extends StatefulWidget {
  const _MenuActionButton({
    super.key,
    required this.onTap,
    required this.gradient,
    required this.child,
    this.compact = false,
  });

  final VoidCallback onTap;
  final Gradient gradient;
  final Widget child;
  final bool compact;

  @override
  State<_MenuActionButton> createState() => _MenuActionButtonState();
}

class _MenuActionButtonState extends State<_MenuActionButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _isPressed || _isHovered;
    final gradientColors = (widget.gradient as LinearGradient).colors;
    final outerRadius = widget.compact ? 11.0 : 16.0;
    final midRadius = widget.compact ? 9.0 : 14.0;
    final innerRadius = widget.compact ? 7.0 : 12.0;
    final padV = widget.compact ? 5.0 : 12.0;
    final padH = widget.compact ? 6.0 : 12.0;
    final fontSize = widget.compact ? 12.0 : 14.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(outerRadius),
            gradient: !isActive ? widget.gradient : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(
                  (255 * (_isHovered ? 0.12 : 0.08)).round(),
                ),
                blurRadius: _isHovered ? 16 : 12,
                offset: Offset(0, _isHovered ? 6 : 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(midRadius),
              gradient: isActive ? widget.gradient : null,
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(innerRadius),
              ),
              padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: isActive ? gradientColors.first : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: fontSize,
                ),
                child: IconTheme(
                  data: IconThemeData(
                    color: isActive ? gradientColors.first : Colors.white,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An animation widget that shows a cake image flying from a start to an end point.
class _FlyingCakeAnimation extends StatefulWidget {
  const _FlyingCakeAnimation({
    required this.startPosition,
    required this.endPosition,
    required this.cakeImage,
    required this.cardSize,
    required this.onCompleted,
  });

  final Offset startPosition;
  final Offset endPosition;
  final String cakeImage;
  final Size cardSize;
  final VoidCallback onCompleted;

  @override
  State<_FlyingCakeAnimation> createState() => _FlyingCakeAnimationState();
}

class _FlyingCakeAnimationState extends State<_FlyingCakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the image size within the card (approx 55% of height)
    final imageSize = widget.cardSize.height * 0.55;
    final startRect = Rect.fromLTWH(
      widget.startPosition.dx,
      widget.startPosition.dy,
      widget.cardSize.width,
      imageSize,
    );
    final endRect = Rect.fromLTWH(
      widget.endPosition.dx + 20, // Center on cart icon
      widget.endPosition.dy + 10,
      0,
      0,
    );

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final rect = Rect.lerp(startRect, endRect, _animation.value)!;
        final angle =
            Tween<double>(begin: 0, end: 0.5).transform(_animation.value);

        return Positioned(
          top: rect.top,
          left: rect.left,
          width: rect.width,
          height: rect.height,
          child: Transform.rotate(
            angle: angle,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.cakeImage.startsWith('http')
                  ? Image.network(
                      widget.cakeImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.cake,
                        color: AppColors.salmon400,
                      ),
                    )
                  : Image.asset(
                      widget.cakeImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.cake,
                        color: AppColors.salmon400,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

/// Cart Overlay that slides up from bottom
class _CartOverlay extends StatefulWidget {
  const _CartOverlay({
    required this.cart,
    required this.cakes,
    required this.customCakes,
    required this.onUpdateQuantity,
    required this.onRemoveCustomCake,
    required this.onUpdateCustomCakeQuantity,
    required this.totalPrice,
    required this.orderType,
    required this.rootScaffoldMessengerContext,
  });

  final Map<int, int> cart;
  final List<Map<String, dynamic>> cakes;
  final List<Map<String, dynamic>> customCakes;
  final Function(int, int) onUpdateQuantity;
  final Function(int) onRemoveCustomCake;
  final Function(int, int) onUpdateCustomCakeQuantity;
  final double totalPrice;
  final String orderType;
  final BuildContext rootScaffoldMessengerContext;

  @override
  State<_CartOverlay> createState() => _CartOverlayState();
}

class _CartOverlayState extends State<_CartOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _slideController.forward();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _slideController.reverse();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _close,
      child: Container(
        color: Colors.black.withAlpha(0),
        child: GestureDetector(
          onTap: () {}, // Prevent closing when tapping overlay content
          child: SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Builder(
                builder: (context) {
                  final size = MediaQuery.of(context).size;
                  final isLandscape = size.width > size.height;
                  final sheetHeight =
                      isLandscape ? size.height * 0.9 : size.height * 0.75;
                  // Use a stable centered width to avoid odd wrapping on web in landscape
                  double targetWidth = isLandscape
                      ? size.width * 0.55
                      : math.min(size.width, 1100);
                  // Clamp so it's never too small or too wide
                  targetWidth = (targetWidth.clamp(520.0, 1100.0));

                  // Keep the sheet anchored to the bottom; Align above handles vertical placement.
                  return SizedBox(
                    width: targetWidth,
                    height: sheetHeight,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: Column(
                        children: [
                          // Handle bar
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          // Header
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                Text(
                                  'Your Cart',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.pink700,
                                  ),
                                ),
                                const Spacer(),
                                // Logo with pulsating background
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.pink500.withAlpha(
                                              (255 *
                                                      (0.1 +
                                                          (_pulseController
                                                                  .value *
                                                              0.15)))
                                                  .round(),
                                            ),
                                            AppColors.peach300.withAlpha(
                                              (255 *
                                                      (0.1 +
                                                          (_pulseController
                                                                  .value *
                                                              0.15)))
                                                  .round(),
                                            ),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: child,
                                    );
                                  },
                                  child: Image.asset(
                                    'assets/icons/icon-original.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.cake,
                                        color: AppColors.pink500),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 28),
                                  onPressed: _close,
                                  color: AppColors.pink700,
                                ),
                              ],
                            ),
                          ),
                          // Cart items
                          Expanded(
                            child: widget.cart.isEmpty &&
                                    widget.customCakes.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.shopping_cart_outlined,
                                          size: 80,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Your cart is empty',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    itemCount: widget.cart.length +
                                        widget.customCakes.length,
                                    itemBuilder: (context, index) {
                                      // Show preset cakes first, then custom cakes
                                      if (index < widget.cart.length) {
                                        // Preset cake
                                        final cakeIndex =
                                            widget.cart.keys.elementAt(index);
                                        final quantity =
                                            widget.cart[cakeIndex]!;
                                        final cake = widget.cakes[cakeIndex];

                                        return _CartItem(
                                          cake: cake,
                                          quantity: quantity,
                                          onIncrease: () =>
                                              widget.onUpdateQuantity(
                                            cakeIndex,
                                            quantity + 1,
                                          ),
                                          onDecrease: () =>
                                              widget.onUpdateQuantity(
                                            cakeIndex,
                                            quantity - 1,
                                          ),
                                          onDelete: () => widget
                                              .onUpdateQuantity(cakeIndex, 0),
                                        );
                                      } else {
                                        // Custom cake
                                        final customIndex =
                                            index - widget.cart.length;
                                        final customCake =
                                            widget.customCakes[customIndex];

                                        return _CustomCakeCartItem(
                                          customCake: customCake,
                                          onDelete: () => widget
                                              .onRemoveCustomCake(customIndex),
                                          onIncrease: () =>
                                              widget.onUpdateCustomCakeQuantity(
                                                  customIndex, 1),
                                          onDecrease: () =>
                                              widget.onUpdateCustomCakeQuantity(
                                                  customIndex, -1),
                                        );
                                      }
                                    },
                                  ),
                          ),
                          // Total and Checkout
                          Container(
                            color: AppColors.cream200,
                            child: Stack(
                              children: [
                                // Background with tiled icons
                                const Positioned.fill(
                                  child: _TiledIcons(),
                                ),
                                // Content
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(20),
                                        blurRadius: 12,
                                        offset: const Offset(0, -4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total',
                                            style: GoogleFonts.ubuntu(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.pink700,
                                            ),
                                          ),
                                          Text(
                                            '₱${widget.totalPrice.toStringAsFixed(2)}',
                                            style: GoogleFonts.ubuntu(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.pink700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _MenuActionButton(
                                        onTap: () async {
                                          // Combine preset and custom cakes into a single list
                                          final List<Map<String, dynamic>>
                                              cartItems = [
                                            // Convert preset cakes to cart item maps
                                            ...widget.cart.entries.map((entry) {
                                              final cake =
                                                  widget.cakes[entry.key];
                                              return {
                                                ...cake,
                                                'quantity': entry.value,
                                              };
                                            }),
                                            // Add custom cakes
                                            ...widget.customCakes,
                                          ];
                                          if (cartItems.isEmpty) {
                                            Navigator.of(context)
                                                .pop(); // Close the overlay first
                                            await Future.delayed(const Duration(
                                                milliseconds:
                                                    200)); // Wait for animation
                                            ScaffoldMessenger.of(
                                              widget
                                                  .rootScaffoldMessengerContext,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                    'Your cart is empty! Please add items before checkout.'),
                                                backgroundColor:
                                                    Colors.red[400],
                                              ),
                                            );
                                            return;
                                          }
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  PaymentMethodScreen(
                                                cartItems: cartItems,
                                                orderType: widget
                                                    .orderType, 
                                              ),
                                            ),
                                          );
                                        },
                                        gradient: const LinearGradient(
                                          colors: [
                                            AppColors.pink500,
                                            AppColors.salmon400
                                          ],
                                        ),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: Text(
                                            'Proceed to Checkout',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.ubuntu(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cart Item
class _CartItem extends StatelessWidget {
  const _CartItem({
    required this.cake,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
  });

  final Map<String, dynamic> cake;
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Cake image
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (cake['image'] is String && (cake['image'] as String).startsWith('http'))
                  ? Image.network(
                      cake['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.cake, color: AppColors.salmon400),
                    )
                  : Image.asset(
                      cake['image'] ?? 'assets/images/cake_1.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.cake, color: AppColors.salmon400),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Cake info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cake['name'],
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.pink700,
                  ),
                ),
                Text(
                  '₱${cake['price'].toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: AppColors.cream200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: onDecrease,
                  color: AppColors.pink700,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '$quantity',
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.pink700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: onIncrease,
                  color: AppColors.pink700,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
            color: Colors.red[400],
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }
}

/// Custom Cake Cart Item
class _CustomCakeCartItem extends StatelessWidget {
  const _CustomCakeCartItem({
    required this.customCake,
    required this.onDelete,
    required this.onIncrease,
    required this.onDecrease,
  });

  final Map<String, dynamic> customCake;
  final VoidCallback onDelete;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  String _formatCakeDetails() {
    final shape = customCake['shape'] ?? 'Unknown';
    final frosting = customCake['frosting'] ?? 'Unknown';
    final numLayers = (customCake['layers'] as List?)?.length ?? 0;

    return '${shape[0].toUpperCase()}${shape.substring(1)} • $numLayers layers • $frosting frosting';
  }

  @override
  Widget build(BuildContext context) {
    final quantity = customCake['quantity'] ?? 1;
    final cakeName = customCake['cakeName'] ?? 'Custom Cake';
    final cakeImage = customCake['cakeImage'];
    final cakePrice = customCake['cakePrice'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Cake image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: cakeImage == null
                  ? const LinearGradient(
                      colors: [
                        AppColors.pink500,
                        AppColors.salmon400,
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        AppColors.cream200,
                        AppColors.peach300.withAlpha(77),
                      ],
                    ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: cakeImage != null
                  ? (cakeImage is String && cakeImage.startsWith('http')
                      ? Image.network(
                          cakeImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.cake_rounded,
                            color: AppColors.salmon400,
                            size: 32,
                          ),
                        )
                      : Image.asset(
                          cakeImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.cake_rounded,
                            color: AppColors.salmon400,
                            size: 32,
                          ),
                        ))
                  : const Icon(
                      Icons.cake_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Cake info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cakeName,
                        style: GoogleFonts.ubuntu(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: AppColors.pink700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.pink500, AppColors.salmon400],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'CUSTOM',
                        style: GoogleFonts.ubuntu(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _formatCakeDetails(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '₱${cakePrice.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.pink700,
                  ),
                ),
              ],
            ),
          ),
          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: AppColors.cream200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: onDecrease,
                  color: AppColors.pink700,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '$quantity',
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.pink700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: onIncrease,
                  color: AppColors.pink700,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
            color: Colors.red[400],
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }
}

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
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 2500 + (widget.index * 350)),
      vsync: this,
    )..repeat(reverse: true);
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
        return Transform.translate(
          offset: Offset(
            math.sin(_controller.value * 2 * math.pi) * 12,
            math.cos(_controller.value * 2 * math.pi) * 18,
          ),
          child: Transform.rotate(
            angle: math.sin(_controller.value * 2 * math.pi) * 0.1,
            child: Opacity(
              opacity: widget.opacity +
                  (math.sin(_controller.value * math.pi) * 0.04),
              child: Icon(
                widget.icon,
                size: widget.size,
                color: AppColors.pink500,
              ),
            ),
          ),
        );
      },
    );
  }
}

class CakeCard extends StatefulWidget {
  const CakeCard({
    super.key,
    required this.cake,
    required this.onTap,
    required this.isSelected,
    required this.isLandscape,
    required this.onViewTap,
    this.viewButtonText,
  });

  final Map<String, dynamic> cake;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isLandscape;
  final VoidCallback onViewTap;
  final String? viewButtonText;

  @override
  State<CakeCard> createState() => CakeCardState();
}

class CakeCardState extends State<CakeCard> with TickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _scrollController;
  late Animation<Alignment> _scrollAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _scrollAnimation = Tween<Alignment>(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).animate(
      CurvedAnimation(parent: _scrollController, curve: Curves.easeInOut),
    );

    if (widget.isSelected) {
      _startSelectionAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant CakeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _startSelectionAnimation();
      } else {
        _scrollController.stop();
        _scrollController.reset();
      }
    }
  }

  void _startSelectionAnimation() {
    // Animate from center to bottom first for a smooth start
    _scrollAnimation = Tween<Alignment>(
      begin: Alignment.center,
      end: Alignment.bottomCenter,
    ).animate(
      CurvedAnimation(parent: _scrollController, curve: Curves.easeInOut),
    );

    _scrollController.forward(from: 0.0);

    // When the initial animation is done, switch to the repeating one
    _scrollController.addStatusListener(_onAnimationStatusChange);
  }

  void _onAnimationStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Re-define the animation for a continuous up-and-down loop
      _scrollAnimation = Tween<Alignment>(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).animate(
        CurvedAnimation(parent: _scrollController, curve: Curves.easeInOut),
      );
      _scrollController.repeat(reverse: true);
      // Remove the listener to avoid re-adding it on every loop
      _scrollController.removeStatusListener(_onAnimationStatusChange);
    }
  }

  @override
  void dispose() {
    _scrollController.removeStatusListener(_onAnimationStatusChange);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: widget.isSelected
              ? const LinearGradient(
                  colors: [AppColors.pink500, AppColors.salmon400],
                )
              : null,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.isSelected
                  ? AppColors.pink500.withAlpha(77)
                  : Colors.black.withAlpha(
                      (255 * (_isPressed ? 0.15 : 0.08)).round(),
                    ),
              blurRadius: _isPressed || widget.isSelected ? 20 : 12,
              offset: Offset(0, _isPressed ? 8 : 4),
            ),
          ],
        ),
        padding: widget.isSelected ? const EdgeInsets.all(3) : null,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(widget.isSelected ? 21 : 24),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageHeight = widget.isLandscape
                  ? constraints.maxHeight * 0.65
                  : constraints.maxHeight * 0.55;

              return Material(
                type: MaterialType.transparency,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: imageHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(widget.isSelected ? 21 : 24),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.cream200,
                                AppColors.peach300.withAlpha(77),
                              ],
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(widget.isSelected ? 21 : 24),
                            ),
                            child: AnimatedBuilder(
                              animation: _scrollAnimation,
                              builder: (context, child) {
                                final img = widget.cake['image'] as String?;
                                final alignment = widget.isSelected
                                    ? _scrollAnimation.value
                                    : Alignment.center;
                                if (img != null && img.startsWith('http')) {
                                  return Image.network(
                                    img,
                                    fit: BoxFit.cover,
                                    alignment: alignment,
                                    filterQuality: FilterQuality.high,
                                    width: double.infinity,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: const CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.cake,
                                      size: widget.isLandscape ? 60 : 80,
                                      color: AppColors.salmon400,
                                    ),
                                  );
                                } else {
                                  return Image.asset(
                                    img ?? 'assets/images/cake_1.png',
                                    fit: BoxFit.cover,
                                    alignment: alignment,
                                    filterQuality: FilterQuality.high,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.cake,
                                      size: widget.isLandscape ? 60 : 80,
                                      color: AppColors.salmon400,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                        if (widget.isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.pink500,
                                    AppColors.salmon400,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(77),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(widget.isLandscape ? 10 : 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.cake['name'],
                                    style: GoogleFonts.ubuntu(
                                      fontSize: widget.isLandscape ? 14 : 16,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.pink700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.cake['description'],
                                    style: GoogleFonts.poppins(
                                      fontSize: widget.isLandscape ? 10 : 11,
                                      color: Colors.black54,
                                    ),
                                    maxLines: widget.isLandscape ? 1 : 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: widget.isLandscape ? 8 : 10,
                                    vertical: widget.isLandscape ? 4 : 5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: widget.isSelected
                                          ? [
                                              AppColors.pink500,
                                              AppColors.salmon400
                                            ]
                                          : [
                                              AppColors.pink500.withAlpha(
                                                (255 * 0.8).round(),
                                              ),
                                              AppColors.salmon400.withAlpha(
                                                (255 * 0.8).round(),
                                              ),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '₱${widget.cake['price'].toStringAsFixed(2)}',
                                    style: GoogleFonts.ubuntu(
                                      fontSize: widget.isLandscape ? 12 : 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (widget.isSelected)
                                  _MenuActionButton(
                                    onTap: widget.onViewTap,
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.pink500,
                                        AppColors.salmon400
                                      ],
                                    ),
                                    compact: true,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.visibility,
                                          size: 13,
                                        ),
                                        if (widget.viewButtonText != null) ...[
                                          const SizedBox(width: 3, height: 3),
                                          Text(
                                            widget.viewButtonText!,
                                            style: GoogleFonts.ubuntu(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
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
            },
          ),
        ),
      ),
    );
  }
}
