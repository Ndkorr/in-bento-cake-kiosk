import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../theme/app_colors.dart';
// Use CakeCard from menu_screen
import 'menu_screen.dart';
import 'cake_customizer_screen.dart';

class CakeDetailsScreen extends StatefulWidget {
  const CakeDetailsScreen({
    super.key,
    required this.cake,
    required this.cakeIndex,
    this.initialCartItems, // Add this parameter
  });

  final Map<String, dynamic> cake;
  final int cakeIndex;
  final List<Map<String, dynamic>>? initialCartItems; // Add this

  @override
  State<CakeDetailsScreen> createState() => _CakeDetailsScreenState();
}

class _CakeDetailsScreenState extends State<CakeDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _showLayerSelection = false;
  bool _showFillingSelection = false;
  bool _showFrostingSelection = false;
  bool _showToppingSelection = false;
  bool _showShapeSelection = false;
  bool _showFlavorSelection = false;
  bool _showToppingDetailPopup = false;
  bool _showErrorPopup = false;
  String _errorMessage = '';
  int _numberOfLayers = 2;
  int _numberOfFillings = 1;
  int _maxToppings = 2;
  List<String?> _selectedLayers = [];
  List<String?> _selectedFillings = [];
  String? _selectedFrosting;
  String? _selectedShape;
  String? _selectedFlavor;
  List<String> _selectedToppings = [];
  bool _toppingsReadOnly = false;

  // Track completion status
  bool _layersCompleted = false;
  bool _fillingsCompleted = false;
  bool _frostingCompleted = false;
  bool _toppingsCompleted = false;

  bool _showFlavorAfterShape = false;

  List<Map<String, dynamic>> _cartItems = [];

  @override
  void initState() {
    super.initState();
    // Initialize cart from passed items or empty list
    _cartItems = widget.initialCartItems != null
        ? List.from(widget.initialCartItems!)
        : [];

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _resetAllSelections() {
    setState(() {
      _selectedLayers = [];
      _selectedFillings = [];
      _selectedFrosting = null;
      _selectedShape = null;
      _selectedFlavor = null; // NEW
      _selectedToppings = [];
      _layersCompleted = false;
      _fillingsCompleted = false;
      _frostingCompleted = false;
      _toppingsCompleted = false;
    });
  }

  void _showFlavorSelectionScreen() {
    setState(() {
      _showFlavorSelection = true;
      _showLayerSelection = false;
      _showFillingSelection = false;
      _showFrostingSelection = false;
      _showToppingSelection = false;
      _showShapeSelection = false;
    });
    _slideController.forward();
  }

  void _handleFlavorSelection(String flavor) {
    setState(() {
      _selectedFlavor = flavor;
    });
  }

  void _handleFlavorExit() {
    if (_selectedFlavor == null) {
      _showError('Please select a flavor for your cake.');
    } else {
      // Apply the selected flavor to all components
      setState(() {
        _selectedLayers = [_selectedFlavor, _selectedFlavor];
        _selectedFillings = [_selectedFlavor];
        _selectedFrosting = _selectedFlavor;
        _layersCompleted = true;
        _fillingsCompleted = true;
        _frostingCompleted = true;
      });
      _hideFlavorSelection();
      // Show shape selection next
      _showShapeSelectionScreen();
    }
  }

  void _hideFlavorSelection() {
    _slideController.reverse().then((_) {
      setState(() {
        _showFlavorSelection = false;
      });
    });
  }

  void _showShapeSelectionScreen() {
    setState(() {
      _showShapeSelection = true;
      _showLayerSelection = false;
      _showFillingSelection = false;
      _showFrostingSelection = false;
      _showToppingSelection = false;
      _showFlavorSelection = false;
    });
    _slideController.forward();
  }

  void _handleShapeSelection(String shape) {
    setState(() {
      _selectedShape = shape;
    });
  }

  void _handleShapeExit() {
    if (_selectedShape == null) {
      _showError('Please select a cake shape.');
    } else {
      _hideShapeSelection();
      // If Combo A and custom, show flavor selection after shape
      if (widget.cake['name'] == 'Combo A') {
        setState(() {
          _showFlavorAfterShape = true;
        });
        _slideController.forward();
      } else {
        _showLoadingScreen();
      }
    }
  }

  void _showLoadingScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => _CakeLoadingOverlay(
        onComplete: () async {
          Navigator.pop(context); // Close loading overlay
          // Navigate to customizer and await result
          final cartItem = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder: (context) => CakeCustomizerScreen(
                cakeShape: _selectedShape!.toLowerCase(),
                selectedLayers:
                    _selectedLayers.isEmpty ? null : _selectedLayers,
                selectedFillings:
                    _selectedFillings.isEmpty ? null : _selectedFillings,
                selectedFrosting: _selectedFrosting,
                selectedToppings:
                    _selectedToppings.isEmpty ? null : _selectedToppings,
              ),
            ),
          );

          // If cart item was returned, add it to cart
          if (cartItem != null && mounted) {
            // Add cake information to cart item
            cartItem['cakeName'] = widget.cake['name'];
            cartItem['cakeImage'] = widget.cake['image'];
            cartItem['cakePrice'] = widget.cake['price'];
            cartItem['quantity'] = 1; // Initialize quantity

            setState(() {
              _cartItems.add(cartItem);
            });
            _showCartSuccessPopup();
          }
        },
      ),
    );
  }

  void _showCartSuccessPopup() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => _CartSuccessPopup(
        cartCount: _cartItems.length,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  void _hideShapeSelection() {
    _slideController.reverse().then((_) {
      setState(() {
        _showShapeSelection = false;
      });
    });
  }

  void _showLayerSelectionScreen(int layers) {
    setState(() {
      _numberOfLayers = layers;
      if (_selectedLayers.isEmpty) {
        _selectedLayers = List.filled(layers, null);
      }
      _showLayerSelection = true;
      _showFillingSelection = false;
      _showFrostingSelection = false;
      _showToppingSelection = false;
      _showShapeSelection = false;
    });
    _slideController.forward();
  }

  void _showFillingSelectionScreen(int fillings) {
    setState(() {
      _numberOfFillings = fillings;
      if (_selectedFillings.isEmpty) {
        _selectedFillings = List.filled(fillings, null);
      }
      _showFillingSelection = true;
      _showLayerSelection = false;
      _showFrostingSelection = false;
      _showToppingSelection = false;
      _showShapeSelection = false;
    });
    _slideController.forward();
  }

  void _showFrostingSelectionScreen() {
    setState(() {
      _showFrostingSelection = true;
      _showLayerSelection = false;
      _showFillingSelection = false;
      _showToppingSelection = false;
      _showShapeSelection = false;
    });
    _slideController.forward();
  }

  void _showToppingSelectionScreen(int maxToppings, bool readOnly) {
    setState(() {
      _maxToppings = maxToppings;
      _toppingsReadOnly = readOnly;
      if (_selectedToppings.isEmpty) {
        if (readOnly) {
          _selectedToppings = [
            'Pretzels',
            'Cherries',
            'Sprinkles',
            'Mango',
            'Chocolate'
          ];
        }
      }
      _showToppingSelection = true;
      _showLayerSelection = false;
      _showFillingSelection = false;
      _showFrostingSelection = false;
      _showShapeSelection = false;
    });
    _slideController.forward();
  }

  void _hideSelection() {
    _slideController.reverse().then((_) {
      setState(() {
        _showLayerSelection = false;
        _showFillingSelection = false;
        _showFrostingSelection = false;
        _showToppingSelection = false;
        _showShapeSelection = false;
        _showFlavorSelection = false;
      });
    });
  }

  void _hideToppingSelectionWithValidation() {
    if (_toppingsReadOnly) {
      _slideController.reverse().then((_) {
        setState(() {
          _showToppingSelection = false;
          _toppingsCompleted = true;
          _showToppingDetailPopup = true;
        });
      });
      return;
    }

    if (_selectedToppings.isEmpty) {
      _showError('Please select at least one topping.');
    } else {
      _slideController.reverse().then((_) {
        setState(() {
          _showToppingSelection = false;
          _toppingsCompleted = true;
          _showToppingDetailPopup = true;
        });
      });
    }
  }

  void _hideDetailPopup() {
    setState(() {
      _showToppingDetailPopup = false;
    });
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _showErrorPopup = true;
    });
  }

  void _hideErrorPopup() {
    setState(() {
      _showErrorPopup = false;
    });
  }

  void _handleLayerExit() {
    if (_selectedLayers.any((layer) => layer == null)) {
      _showError('Please select a flavor for each layer.');
    } else {
      setState(() {
        _layersCompleted = true;
      });
      _hideSelection();
    }
  }

  void _handleFillingExit() {
    if (_selectedFillings.any((filling) => filling == null)) {
      _showError('Please select a flavor for each filling.');
    } else {
      setState(() {
        _fillingsCompleted = true;
      });
      _hideSelection();
    }
  }

  void _handleFrostingExit() {
    if (_selectedFrosting == null) {
      _showError('Please select a frosting flavor.');
    } else {
      setState(() {
        _frostingCompleted = true;
      });
      _hideSelection();
    }
  }

  void _handleFlavorAfterShapeSelection(String flavor) {
    setState(() {
      _selectedFlavor = flavor;
    });
  }

  void _handleFlavorAfterShapeExit() {
    if (_selectedFlavor == null) {
      _showError('Please select a flavor for your cake.');
    } else {
      // Set all components to the selected flavor
      setState(() {
        _selectedLayers = [_selectedFlavor, _selectedFlavor];
        _selectedFillings = [_selectedFlavor];
        _selectedFrosting = _selectedFlavor;
        _layersCompleted = true;
        _fillingsCompleted = true;
        _frostingCompleted = true;
        _showFlavorAfterShape = false;
      });
      _slideController.reverse().then((_) {
        _showLoadingScreen();
      });
    }
  }

  String _getLayersSubtitle() {
    if (!_layersCompleted) return 'OF YOUR CHOSEN VARIATION';
    return _selectedLayers.join(', ');
  }

  String _getFillingsSubtitle() {
    if (!_fillingsCompleted) return 'OF YOUR CHOICE';
    return _selectedFillings.join(', ');
  }

  String _getFrostingSubtitle() {
    if (!_frostingCompleted) return 'OF YOUR CHOICE';
    return _selectedFrosting ?? 'OF YOUR CHOICE';
  }

  String _getToppingsSubtitle(bool readOnly) {
    if (!_toppingsCompleted) {
      return readOnly ? 'ALL SELECTED' : 'OF YOUR CHOICE';
    }
    return _selectedToppings.join(', ');
  }

  List<Map<String, String>> _getOptionsForCake() {
    final cakeName = widget.cake['name'] as String;

    if (cakeName == 'Combo A') {
      return [
        {
          'title': '2 LAYERS',
          'subtitle': _layersCompleted
              ? _selectedFlavor ?? 'SAME FLAVOR FOR BOTH LAYERS'
              : 'SAME FLAVOR FOR BOTH LAYERS',
          'clickable': 'false'
        },
        {
          'title': '1 FILLING',
          'subtitle': _fillingsCompleted
              ? _selectedFlavor ?? 'SAME FLAVOR AS CAKE LAYER'
              : 'SAME FLAVOR AS CAKE LAYER',
          'clickable': 'false'
        },
        {
          'title': 'FROSTING',
          'subtitle': _frostingCompleted
              ? _selectedFlavor ?? 'SAME FLAVOR AS CAKE LAYER'
              : 'SAME FLAVOR AS CAKE LAYER',
          'clickable': 'false'
        },
        {
          'title': '2 TOPPINGS',
          'subtitle': _getToppingsSubtitle(false),
          'clickable': 'true',
          'type': 'toppings',
          'count': '2',
          'readonly': 'false',
          'completed': _toppingsCompleted.toString()
        },
        {
          'title': 'DEDICATION',
          'subtitle': 'PERSONALIZED',
          'clickable': 'false'
        },
      ];
    } else if (cakeName == 'Combo C') {
      return [
        {
          'title': '3 LAYERS',
          'subtitle': _getLayersSubtitle(),
          'clickable': 'true',
          'type': 'layers',
          'count': '3',
          'completed': _layersCompleted.toString()
        },
        {
          'title': '2 FILLINGS',
          'subtitle': _getFillingsSubtitle(),
          'clickable': 'true',
          'type': 'fillings',
          'count': '2',
          'completed': _fillingsCompleted.toString()
        },
        {
          'title': 'FROSTING',
          'subtitle': _getFrostingSubtitle(),
          'clickable': 'true',
          'type': 'frosting',
          'completed': _frostingCompleted.toString()
        },
        {
          'title': '5 TOPPINGS',
          'subtitle': _getToppingsSubtitle(true),
          'clickable': 'true',
          'type': 'toppings',
          'count': '5',
          'readonly': 'true',
          'completed': _toppingsCompleted.toString()
        },
        {
          'title': 'DEDICATION',
          'subtitle': 'PERSONALIZED',
          'clickable': 'false'
        },
      ];
    } else if (cakeName == 'Combo B') {
      return [
        {
          'title': '2 LAYERS',
          'subtitle': _getLayersSubtitle(),
          'clickable': 'true',
          'type': 'layers',
          'count': '2',
          'completed': _layersCompleted.toString()
        },
        {
          'title': '1 FILLING',
          'subtitle': _getFillingsSubtitle(),
          'clickable': 'true',
          'type': 'fillings',
          'count': '1',
          'completed': _fillingsCompleted.toString()
        },
        {
          'title': 'FROSTING',
          'subtitle': _getFrostingSubtitle(),
          'clickable': 'true',
          'type': 'frosting',
          'completed': _frostingCompleted.toString()
        },
        {
          'title': '3 TOPPINGS',
          'subtitle': _getToppingsSubtitle(false),
          'clickable': 'true',
          'type': 'toppings',
          'count': '3',
          'readonly': 'false',
          'completed': _toppingsCompleted.toString()
        },
        {
          'title': 'DEDICATION',
          'subtitle': 'PERSONALIZED',
          'clickable': 'false'
        },
      ];
    }

    return [
      {
        'title': '2 LAYERS',
        'subtitle': 'SAME FLAVOR FOR BOTH LAYERS',
        'clickable': 'false'
      },
      {
        'title': '1 FILLING',
        'subtitle': 'SAME FLAVOR AS CAKE LAYER',
        'clickable': 'false'
      },
      {
        'title': 'FROSTING',
        'subtitle': 'SAME FLAVOR AS CAKE LAYER',
        'clickable': 'false'
      },
      {
        'title': '2 TOPPINGS',
        'subtitle': _getToppingsSubtitle(false),
        'clickable': 'true',
        'type': 'toppings',
        'count': '2',
        'readonly': 'false',
        'completed': _toppingsCompleted.toString()
      },
      {'title': 'DEDICATION', 'subtitle': 'PERSONALIZED', 'clickable': 'false'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final options = _getOptionsForCake();

    return Scaffold(
      backgroundColor: AppColors.cream200,
      body: Stack(
        children: [
          const Positioned.fill(
            child: _TiledIcons(),
          ),
          SafeArea(
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
                        SizedBox(
                          height: screenHeight * 0.4,
                          child: Hero(
                            tag: 'cake_card_${widget.cakeIndex}',
                            child: CakeCard(
                              cake: widget.cake,
                              isSelected: true,
                              isLandscape: false,
                              onTap: () {},
                              onViewTap: () {
                                // Check if it's Classic Vanilla
                                final cakeName = widget.cake['name'] as String;
                                if (cakeName == 'Classic Vanilla') {
                                  _showFlavorSelectionScreen();
                                } else {
                                  _showShapeSelectionScreen();
                                }
                              },
                              viewButtonText: 'Customize',
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final isClickable =
                                  options[index]['clickable'] == 'true';
                              final isCompleted =
                                  options[index]['completed'] == 'true';
                              return _OptionButton(
                                title: options[index]['title']!,
                                subtitle: options[index]['subtitle']!,
                                isClickable: isClickable,
                                isCompleted: isCompleted,
                                onTap: isClickable
                                    ? () {
                                        final type = options[index]['type'];
                                        if (type == 'layers') {
                                          final layerCount = int.parse(
                                              options[index]['count'] ?? '2');
                                          _showLayerSelectionScreen(layerCount);
                                        } else if (type == 'fillings') {
                                          final fillingCount = int.parse(
                                              options[index]['count'] ?? '1');
                                          _showFillingSelectionScreen(
                                              fillingCount);
                                        } else if (type == 'frosting') {
                                          _showFrostingSelectionScreen();
                                        } else if (type == 'toppings') {
                                          final maxToppings = int.parse(
                                              options[index]['count'] ?? '2');
                                          final readOnly = options[index]
                                                  ['readonly'] ==
                                              'true';
                                          _showToppingSelectionScreen(
                                              maxToppings, readOnly);
                                        }
                                      }
                                    : null,
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
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.pink700, size: 28),
                        onPressed: () {
                          _resetAllSelections();
                          Navigator.pop(context, _cartItems);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Flavor selection overlay (NEW - for Classic Vanilla)
          if (_showFlavorSelection)
            SlideTransition(
              position: _slideAnimation,
              child: _FlavorSelectionOverlay(
                selectedFlavor: _selectedFlavor,
                onFlavorSelected: _handleFlavorSelection,
                onBack: _handleFlavorExit,
              ),
            ),
          // Shape selection overlay
          if (_showShapeSelection)
            SlideTransition(
              position: _slideAnimation,
              child: _ShapeSelectionOverlay(
                selectedShape: _selectedShape,
                onShapeSelected: _handleShapeSelection,
                onBack: _handleShapeExit,
              ),
            ),
          // ...existing overlays...
          if (_showLayerSelection)
            SlideTransition(
              position: _slideAnimation,
              child: _LayerSelectionOverlay(
                numberOfLayers: _numberOfLayers,
                selectedLayers: _selectedLayers,
                onLayerSelected: (layerIndex, flavor) {
                  setState(() {
                    _selectedLayers[layerIndex] = flavor;
                  });
                },
                onBack: _handleLayerExit,
              ),
            ),
          if (_showFillingSelection)
            SlideTransition(
              position: _slideAnimation,
              child: _FillingSelectionOverlay(
                numberOfFillings: _numberOfFillings,
                selectedFillings: _selectedFillings,
                onFillingSelected: (fillingIndex, flavor) {
                  setState(() {
                    _selectedFillings[fillingIndex] = flavor;
                  });
                },
                onBack: _handleFillingExit,
              ),
            ),
          if (_showFrostingSelection)
            SlideTransition(
              position: _slideAnimation,
              child: _FrostingSelectionOverlay(
                selectedFrosting: _selectedFrosting,
                onFrostingSelected: (flavor) {
                  setState(() {
                    _selectedFrosting = flavor;
                  });
                },
                onBack: _handleFrostingExit,
              ),
            ),
          if (_showToppingSelection)
            SlideTransition(
              position: _slideAnimation,
              child: _ToppingSelectionOverlay(
                maxToppings: _maxToppings,
                selectedToppings: _selectedToppings,
                readOnly: _toppingsReadOnly,
                onToppingToggled: (topping) {
                  if (_toppingsReadOnly) return;
                  setState(() {
                    if (_selectedToppings.contains(topping)) {
                      _selectedToppings.remove(topping);
                    } else {
                      if (_selectedToppings.length < _maxToppings) {
                        _selectedToppings.add(topping);
                      }
                    }
                  });
                },
                onBack: _hideToppingSelectionWithValidation,
              ),
            ),
          if (_showToppingDetailPopup)
            _ToppingDetailPopup(onDismiss: _hideDetailPopup),
          if (_showFlavorAfterShape)
  SlideTransition(
    position: _slideAnimation,
    child: _FlavorSelectionOverlay(
      selectedFlavor: _selectedFlavor,
      onFlavorSelected: _handleFlavorAfterShapeSelection,
      onBack: _handleFlavorAfterShapeExit,
    ),
  ),
if (_showFlavorAfterShape && _showErrorPopup)
  _ErrorPopup(
    message: _errorMessage,
    onDismiss: _hideErrorPopup,
  ),
if (!_showFlavorAfterShape && _showErrorPopup)
  _ErrorPopup(
    message: _errorMessage,
    onDismiss: _hideErrorPopup,
  ),
        ],
      ),
    );
  }
}

/// Loading overlay specifically for cake preparation
class _CakeLoadingOverlay extends StatefulWidget {
  const _CakeLoadingOverlay({required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<_CakeLoadingOverlay> createState() => _CakeLoadingOverlayState();
}

class _CakeLoadingOverlayState extends State<_CakeLoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<IconData> _cakeIcons = [
    Icons.cake,
    Icons.emoji_food_beverage,
    Icons.cookie,
    Icons.bakery_dining_outlined,
    Icons.local_cafe,
    Icons.celebration_outlined,
    Icons.favorite_border,
    Icons.card_giftcard_outlined,
  ];

  final List<Color> _iconColors = [
    AppColors.pink700,
    AppColors.pink500,
    AppColors.salmon400,
    AppColors.peach300,
    AppColors.cream200,
    Colors.white,
  ];

  final List<int> _iconIndices = [-1, -1, -1]; // -1 means still a circle
  final List<Color> _currentColors = [Colors.white, Colors.white, Colors.white];

  bool _shouldStop = false;
  late final int _randomEndPoint;

  @override
  void initState() {
    super.initState();
    _randomEndPoint = math.Random().nextInt(7); // 0-6 for different end points
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _startAnimation();
  }

  void _startAnimation() async {
    while (mounted && !_shouldStop) {
      // Phase 1: Dots to Icons (left to right)
      await Future.delayed(const Duration(milliseconds: 200));

      for (int i = 0; i < 3; i++) {
        // Check if we should stop at 1, 2, or 3 icons showing
        if (_randomEndPoint == i) {
          _shouldStop = true;
          _finishAnimation();
          return;
        }

        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          setState(() {
            _iconIndices[i] = math.Random().nextInt(_cakeIcons.length);
            _currentColors[i] =
                _iconColors[math.Random().nextInt(_iconColors.length)];
          });
          _controller.forward(from: 0);
        }
      }

      // Check if we should stop with all 3 icons visible
      if (_randomEndPoint == 3) {
        _shouldStop = true;
        _finishAnimation();
        return;
      }

      // Wait a bit with all icons visible
      await Future.delayed(const Duration(milliseconds: 500));

      // Phase 2: Icons back to Dots (randomly)
      List<int> randomOrder = [0, 1, 2]..shuffle();

      for (int i = 0; i < randomOrder.length; i++) {
        int index = randomOrder[i];

        // Check if we should stop at 2, 1, or 0 dots (after converting some icons)
        if (_randomEndPoint == 4 && i == 1) {
          _shouldStop = true;
          _finishAnimation();
          return;
        }
        if (_randomEndPoint == 5 && i == 2) {
          _shouldStop = true;
          _finishAnimation();
          return;
        }

        await Future.delayed(const Duration(milliseconds: 250));
        if (mounted) {
          setState(() {
            _iconIndices[index] = -1;
            _currentColors[index] =
                _iconColors[math.Random().nextInt(_iconColors.length)];
          });
          _controller.forward(from: 0);
        }
      }

      // Check if we should stop with all 3 dots (longest cycle)
      if (_randomEndPoint == 6) {
        _shouldStop = true;
        _finishAnimation();
        return;
      }

      // Wait before restarting
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  void _finishAnimation() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title text with gradient color
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.cream200, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Building your cake',
                style: GoogleFonts.ubuntu(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Animated icons/circles
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _AnimatedIconCircle(
                    isRevealed: _iconIndices[index] != -1,
                    icon: _iconIndices[index] != -1
                        ? _cakeIcons[_iconIndices[index]]
                        : null,
                    color: _currentColors[index],
                    animation: _controller,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedIconCircle extends StatelessWidget {
  const _AnimatedIconCircle({
    required this.isRevealed,
    required this.icon,
    required this.color,
    required this.animation,
  });

  final bool isRevealed;
  final IconData? icon;
  final Color color;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    if (!isRevealed) {
      // Show empty circle outline
      return SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.8), width: 3),
            ),
          ),
        ),
      );
    }

    // Show animated icon
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (animation.value * 0.3),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: color, size: 32),
          ),
        );
      },
    );
  }
}

/// Flavor selection overlay (for Classic Vanilla)
class _FlavorSelectionOverlay extends StatelessWidget {
  const _FlavorSelectionOverlay({
    required this.selectedFlavor,
    required this.onFlavorSelected,
    required this.onBack,
    this.errorMessage,
    this.onDismissError,
  });

  final String? selectedFlavor;
  final Function(String flavor) onFlavorSelected;
  final VoidCallback onBack;
  final String? errorMessage;
  final VoidCallback? onDismissError;

  @override
  Widget build(BuildContext context) {
    const flavors = ['Vanilla', 'Chocolate', 'Ube'];

    return Container(
      color: AppColors.cream200,
      child: Stack(
        children: [
          const Positioned.fill(
            child: _TiledIcons(),
          ),
          if (errorMessage != null && onDismissError != null)
            _ErrorPopup(
              message: errorMessage!,
              onDismiss: onDismissError!,
            ),
          SafeArea(
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
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: AppColors.pink700, size: 28),
                            onPressed: onBack,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Cake Flavor',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.pink700,
                                  ),
                                ),
                                Text(
                                  'Same flavor for layers, filling & frosting',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.pink500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: flavors.map((flavor) {
                            final isSelected = selectedFlavor == flavor;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _FlavorOptionButton(
                                flavor: flavor,
                                isSelected: isSelected,
                                onTap: () => onFlavorSelected(flavor),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _MenuActionButton(
                        onTap: onBack,
                        gradient: const LinearGradient(
                          colors: [AppColors.pink500, AppColors.salmon400],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Continue',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ubuntu(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shape selection overlay
class _ShapeSelectionOverlay extends StatelessWidget {
  const _ShapeSelectionOverlay({
    required this.selectedShape,
    required this.onShapeSelected,
    required this.onBack,
  });

  final String? selectedShape;
  final Function(String shape) onShapeSelected;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream200,
      child: Stack(
        children: [
          const Positioned.fill(
            child: _TiledIcons(),
          ),
          SafeArea(
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
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: AppColors.pink700, size: 28),
                            onPressed: onBack,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Select Cake Shape',
                            style: GoogleFonts.ubuntu(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: AppColors.pink700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ShapeOptionButton(
                              shape: 'Round',
                              icon: Icons.circle_outlined,
                              isSelected: selectedShape == 'Round',
                              onTap: () => onShapeSelected('Round'),
                            ),
                            const SizedBox(height: 16),
                            _ShapeOptionButton(
                              shape: 'Heart',
                              icon: Icons.favorite_border,
                              isSelected: selectedShape == 'Heart',
                              onTap: () => onShapeSelected('Heart'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _MenuActionButton(
                        onTap: onBack,
                        gradient: const LinearGradient(
                          colors: [AppColors.pink500, AppColors.salmon400],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Continue',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ubuntu(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shape option button
class _ShapeOptionButton extends StatefulWidget {
  const _ShapeOptionButton({
    required this.shape,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String shape;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ShapeOptionButton> createState() => _ShapeOptionButtonState();
}

class _ShapeOptionButtonState extends State<_ShapeOptionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isPressed = true),
      onExit: (_) => setState(() => _isPressed = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) setState(() => _isPressed = false);
          });
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            gradient: _isPressed
                ? const LinearGradient(
                    colors: [Colors.white, Colors.white],
                  )
                : widget.isSelected
                    ? const LinearGradient(
                        colors: [AppColors.pink500, AppColors.salmon400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
            color: widget.isSelected || _isPressed ? null : AppColors.cream200,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected || _isPressed
                  ? Colors.transparent
                  : AppColors.pink700,
              width: 2,
            ),
            boxShadow: widget.isSelected || _isPressed
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: _isPressed
                    ? AppColors.pink700
                    : widget.isSelected
                        ? Colors.white
                        : AppColors.pink700,
                size: 32,
              ),
              const SizedBox(width: 16),
              Text(
                widget.shape,
                style: GoogleFonts.ubuntu(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _isPressed
                      ? AppColors.pink700
                      : widget.isSelected
                          ? Colors.white
                          : AppColors.pink700,
                ),
              ),
              const Spacer(),
              if (widget.isSelected)
                Icon(
                  Icons.check_circle,
                  color: _isPressed ? AppColors.pink700 : Colors.white,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Generic error popup
class _ErrorPopup extends StatefulWidget {
  const _ErrorPopup({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  State<_ErrorPopup> createState() => _ErrorPopupState();
}

class _ErrorPopupState extends State<_ErrorPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismiss,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent dismiss when tapping the popup itself
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 60),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.pink500, AppColors.salmon400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(80),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.error_outline,
                              color: AppColors.pink700,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Message
                          Text(
                            widget.message,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ubuntu(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // OK Button
                          _MenuActionButton(
                            onTap: _dismiss,
                            gradient: const LinearGradient(
                              colors: [Colors.white, Colors.white],
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'OK',
                                style: GoogleFonts.ubuntu(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.pink700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Topping detail popup that appears after selecting toppings
class _ToppingDetailPopup extends StatefulWidget {
  const _ToppingDetailPopup({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  State<_ToppingDetailPopup> createState() => _ToppingDetailPopupState();
}

class _ToppingDetailPopupState extends State<_ToppingDetailPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismiss,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent dismiss when tapping the popup itself
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 60),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.pink500, AppColors.salmon400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(80),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: AppColors.pink700,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Message
                          Text(
                            'Edit your chosen toppings on the customize screen - Add as many as you want!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ubuntu(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // OK Button
                          _MenuActionButton(
                            onTap: _dismiss,
                            gradient: const LinearGradient(
                              colors: [Colors.white, Colors.white],
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Got it!',
                                style: GoogleFonts.ubuntu(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.pink700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Layer selection overlay that slides in
class _LayerSelectionOverlay extends StatelessWidget {
  const _LayerSelectionOverlay({
    required this.numberOfLayers,
    required this.selectedLayers,
    required this.onLayerSelected,
    required this.onBack,
  });

  final int numberOfLayers;
  final List<String?> selectedLayers;
  final Function(int layerIndex, String flavor) onLayerSelected;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const flavors = ['Vanilla', 'Chocolate', 'Ube'];

    return Container(
      color: AppColors.cream200,
      child: Stack(
        children: [
          // Background icons
          const Positioned.fill(
            child: _TiledIcons(),
          ),
          // Content
          SafeArea(
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
                child: Column(
                  children: [
                    // Header with back button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: AppColors.pink700, size: 28),
                            onPressed: onBack,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Select Layer Flavors',
                            style: GoogleFonts.ubuntu(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: AppColors.pink700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Layer selections
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: numberOfLayers,
                        itemBuilder: (context, layerIndex) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 8, bottom: 12),
                                child: Text(
                                  'Layer ${layerIndex + 1}',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.pink700,
                                  ),
                                ),
                              ),
                              ...flavors.map((flavor) {
                                final isSelected =
                                    selectedLayers[layerIndex] == flavor;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _FlavorOptionButton(
                                    flavor: flavor,
                                    isSelected: isSelected,
                                    onTap: () =>
                                        onLayerSelected(layerIndex, flavor),
                                  ),
                                );
                              }),
                              if (layerIndex < numberOfLayers - 1)
                                const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                    ),
                    // Done button
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _MenuActionButton(
                        onTap: onBack,
                        gradient: const LinearGradient(
                          colors: [AppColors.pink500, AppColors.salmon400],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Done',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ubuntu(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filling selection overlay that slides in
class _FillingSelectionOverlay extends StatelessWidget {
  const _FillingSelectionOverlay({
    required this.numberOfFillings,
    required this.selectedFillings,
    required this.onFillingSelected,
    required this.onBack,
  });

  final int numberOfFillings;
  final List<String?> selectedFillings;
  final Function(int fillingIndex, String flavor) onFillingSelected;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const flavors = ['Vanilla', 'Chocolate', 'Ube'];

    return Container(
      color: AppColors.cream200,
      child: Stack(
        children: [
          // Background icons
          const Positioned.fill(
            child: _TiledIcons(),
          ),
          // Content
          SafeArea(
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
                child: Column(
                  children: [
                    // Header with back button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: AppColors.pink700, size: 28),
                            onPressed: onBack,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Select Filling Flavors',
                            style: GoogleFonts.ubuntu(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: AppColors.pink700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Filling selections
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: numberOfFillings,
                        itemBuilder: (context, fillingIndex) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 8, bottom: 12),
                                child: Text(
                                  numberOfFillings > 1
                                      ? 'Filling ${fillingIndex + 1}'
                                      : 'Filling',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.pink700,
                                  ),
                                ),
                              ),
                              ...flavors.map((flavor) {
                                final isSelected =
                                    selectedFillings[fillingIndex] == flavor;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _FlavorOptionButton(
                                    flavor: flavor,
                                    isSelected: isSelected,
                                    onTap: () =>
                                        onFillingSelected(fillingIndex, flavor),
                                  ),
                                );
                              }),
                              if (fillingIndex < numberOfFillings - 1)
                                const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                    ),
                    // Done button
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _MenuActionButton(
                        onTap: onBack,
                        gradient: const LinearGradient(
                          colors: [AppColors.pink500, AppColors.salmon400],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Done',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ubuntu(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosting selection overlay that slides in
class _FrostingSelectionOverlay extends StatelessWidget {
  const _FrostingSelectionOverlay({
    required this.selectedFrosting,
    required this.onFrostingSelected,
    required this.onBack,
  });

  final String? selectedFrosting;
  final Function(String flavor) onFrostingSelected;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const flavors = ['Vanilla', 'Chocolate', 'Ube'];

    return Container(
      color: AppColors.cream200,
      child: Stack(
        children: [
          // Background icons
          const Positioned.fill(
            child: _TiledIcons(),
          ),
          // Content
          SafeArea(
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
                child: Column(
                  children: [
                    // Header with back button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: AppColors.pink700, size: 28),
                            onPressed: onBack,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Select Frosting Flavor',
                            style: GoogleFonts.ubuntu(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: AppColors.pink700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Frosting selections
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: flavors.map((flavor) {
                          final isSelected = selectedFrosting == flavor;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _FlavorOptionButton(
                              flavor: flavor,
                              isSelected: isSelected,
                              onTap: () => onFrostingSelected(flavor),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Done button
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _MenuActionButton(
                        onTap: onBack,
                        gradient: const LinearGradient(
                          colors: [AppColors.pink500, AppColors.salmon400],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Done',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ubuntu(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Topping selection overlay that slides in
class _ToppingSelectionOverlay extends StatelessWidget {
  const _ToppingSelectionOverlay({
    required this.maxToppings,
    required this.selectedToppings,
    required this.readOnly,
    required this.onToppingToggled,
    required this.onBack,
  });

  final int maxToppings;
  final List<String> selectedToppings;
  final bool readOnly;
  final Function(String topping) onToppingToggled;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const toppings = [
      'Pretzels',
      'Cherries',
      'Sprinkles',
      'Mango',
      'Chocolate'
    ];

    return Container(
      color: AppColors.cream200,
      child: Stack(
        children: [
          // Background icons
          const Positioned.fill(
            child: _TiledIcons(),
          ),
          // Content
          SafeArea(
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
                child: Column(
                  children: [
                    // Header with back button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: AppColors.pink700, size: 28),
                            onPressed: onBack,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Toppings',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.pink700,
                                  ),
                                ),
                                if (!readOnly)
                                  Text(
                                    '${selectedToppings.length} of $maxToppings selected',
                                    style: GoogleFonts.ubuntu(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.pink500,
                                    ),
                                  )
                                else
                                  Text(
                                    'All toppings included',
                                    style: GoogleFonts.ubuntu(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.pink500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Topping selections
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: toppings.map((topping) {
                          final isSelected = selectedToppings.contains(topping);
                          final canSelect = !readOnly &&
                              (isSelected ||
                                  selectedToppings.length < maxToppings);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ToppingOptionButton(
                              topping: topping,
                              isSelected: isSelected,
                              enabled: canSelect,
                              onTap: canSelect
                                  ? () => onToppingToggled(topping)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Done button
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _MenuActionButton(
                        onTap: onBack,
                        gradient: const LinearGradient(
                          colors: [AppColors.pink500, AppColors.salmon400],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Done',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ubuntu(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Topping option button (multiselect)
class _ToppingOptionButton extends StatefulWidget {
  const _ToppingOptionButton({
    required this.topping,
    required this.isSelected,
    required this.enabled,
    this.onTap,
  });

  final String topping;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<_ToppingOptionButton> createState() => _ToppingOptionButtonState();
}

class _ToppingOptionButtonState extends State<_ToppingOptionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
      onExit: widget.enabled ? (_) => setState(() => _isPressed = false) : null,
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.enabled
            ? (_) {
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (mounted) setState(() => _isPressed = false);
                });
                widget.onTap?.call();
              }
            : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: _isPressed
                ? const LinearGradient(
                    colors: [Colors.white, Colors.white],
                  )
                : widget.isSelected
                    ? const LinearGradient(
                        colors: [AppColors.pink500, AppColors.salmon400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
            color: widget.isSelected || _isPressed
                ? null
                : widget.enabled
                    ? AppColors.cream200
                    : AppColors.cream200.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected || _isPressed
                  ? Colors.transparent
                  : widget.enabled
                      ? AppColors.pink700
                      : AppColors.pink700,
              width: 2,
            ),
            boxShadow: widget.isSelected || _isPressed
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              if (widget.isSelected)
                Icon(
                  Icons.check_circle,
                  color: _isPressed ? AppColors.pink700 : Colors.white,
                  size: 24,
                )
              else
                Icon(
                  Icons.circle_outlined,
                  color: _isPressed
                      ? AppColors.pink700
                      : widget.enabled
                          ? AppColors.pink700
                          : AppColors.pink700,
                  size: 24,
                ),
              const SizedBox(width: 12),
              Text(
                widget.topping,
                style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _isPressed
                      ? AppColors.pink700
                      : widget.isSelected
                          ? Colors.white
                          : widget.enabled
                              ? AppColors.pink700
                              : AppColors.pink700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flavor option button
class _FlavorOptionButton extends StatefulWidget {
  const _FlavorOptionButton({
    required this.flavor,
    required this.isSelected,
    required this.onTap,
  });

  final String flavor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_FlavorOptionButton> createState() => _FlavorOptionButtonState();
}

class _FlavorOptionButtonState extends State<_FlavorOptionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isPressed = true),
      onExit: (_) => setState(() => _isPressed = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) setState(() => _isPressed = false);
          });
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: _isPressed
                ? const LinearGradient(
                    colors: [Colors.white, Colors.white],
                  )
                : widget.isSelected
                    ? const LinearGradient(
                        colors: [AppColors.pink500, AppColors.salmon400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
            color: widget.isSelected || _isPressed ? null : AppColors.cream200,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected || _isPressed
                  ? Colors.transparent
                  : AppColors.pink700,
              width: 2,
            ),
            boxShadow: widget.isSelected || _isPressed
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              if (widget.isSelected)
                Icon(
                  Icons.check_circle,
                  color: _isPressed ? AppColors.pink700 : Colors.white,
                  size: 24,
                )
              else
                Icon(
                  Icons.circle_outlined,
                  color: _isPressed ? AppColors.pink700 : AppColors.pink700,
                  size: 24,
                ),
              const SizedBox(width: 12),
              Text(
                widget.flavor,
                style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _isPressed
                      ? AppColors.pink700
                      : widget.isSelected
                          ? Colors.white
                          : AppColors.pink700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A styled button (reused from menu_screen)
class _MenuActionButton extends StatefulWidget {
  const _MenuActionButton({
    required this.onTap,
    required this.gradient,
    required this.child,
  });

  final VoidCallback onTap;
  final Gradient gradient;
  final Widget child;

  @override
  State<_MenuActionButton> createState() => _MenuActionButtonState();
}

class _MenuActionButtonState extends State<_MenuActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isPressed = true),
      onExit: (_) => setState(() => _isPressed = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) setState(() => _isPressed = false);
          });
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            gradient: _isPressed
                ? const LinearGradient(
                    colors: [Colors.white, Colors.white],
                  )
                : widget.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: GoogleFonts.ubuntu(
              color: _isPressed ? AppColors.pink700 : Colors.white,
              fontWeight: FontWeight.w800,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatefulWidget {
  const _OptionButton({
    required this.title,
    required this.subtitle,
    required this.isClickable,
    required this.isCompleted,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isClickable;
  final bool isCompleted;
  final VoidCallback? onTap;

  @override
  State<_OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<_OptionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Only show animations if not completed and is clickable
    final showAnimations = widget.isClickable && !widget.isCompleted;

    return MouseRegion(
      cursor: widget.isClickable
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter:
          widget.isClickable ? (_) => setState(() => _isPressed = true) : null,
      onExit:
          widget.isClickable ? (_) => setState(() => _isPressed = false) : null,
      child: GestureDetector(
        onTapDown: widget.isClickable
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.isClickable
            ? (_) {
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (mounted) setState(() => _isPressed = false);
                });
                widget.onTap?.call();
              }
            : null,
        onTapCancel: widget.isClickable
            ? () => setState(() => _isPressed = false)
            : null,
        onTap: widget.isClickable ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          child: showAnimations
              ? _CirculatingBorderWrapper(
                  child: _buildContent(),
                )
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Only show animations if not completed and is clickable
    final showAnimations = widget.isClickable && !widget.isCompleted;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: _isPressed
            ? const LinearGradient(
                colors: [Colors.white, Colors.white],
              )
            : const LinearGradient(
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
          // Show pulsating icon only if animations are enabled
          if (showAnimations)
            _PulsatingIcon(
              icon: Icons.auto_awesome,
              size: 22,
              isPressed: _isPressed,
            )
          else
            Container(
              width: 22 + 12,
              height: 22 + 12,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isPressed
                    ? const LinearGradient(
                        colors: [Colors.white, Colors.white],
                      )
                    : const LinearGradient(
                        colors: [AppColors.pink500, AppColors.salmon400],
                      ),
              ),
              child: Icon(
                Icons.check,
                color: _isPressed ? AppColors.pink700 : Colors.white,
                size: 22,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.ubuntu(
                    color: _isPressed ? AppColors.pink700 : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.ubuntu(
                    color: _isPressed ? AppColors.pink500 : AppColors.cream200,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Show chevron only if clickable and animations enabled
          if (widget.isClickable) ...[
            const SizedBox(width: 8),
            if (showAnimations)
              _PulsatingChevron(isPressed: _isPressed)
            else
              Icon(
                Icons.chevron_right_rounded,
                color: _isPressed ? AppColors.pink700 : Colors.white,
                size: 28,
              ),
          ],
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// Pulsating chevron icon
class _PulsatingChevron extends StatefulWidget {
  const _PulsatingChevron({this.isPressed = false});

  final bool isPressed;

  @override
  State<_PulsatingChevron> createState() => _PulsatingChevronState();
}

class _PulsatingChevronState extends State<_PulsatingChevron>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.1).animate(
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
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.chevron_right_rounded,
            color: widget.isPressed ? AppColors.pink700 : Colors.white,
            size: 28,
          ),
        );
      },
    );
  }
}

/// Wrapper that creates a circulating light border animation
class _CirculatingBorderWrapper extends StatefulWidget {
  const _CirculatingBorderWrapper({required this.child});

  final Widget child;

  @override
  State<_CirculatingBorderWrapper> createState() =>
      _CirculatingBorderWrapperState();
}

class _CirculatingBorderWrapperState extends State<_CirculatingBorderWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 7500),
      vsync: this,
    )..repeat();
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
        return Stack(
          children: [
            // The actual content
            child!,
            // The circulating border on top
            Positioned.fill(
              child: CustomPaint(
                painter: _CirculatingBorderPainter(
                  animation: _controller,
                ),
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

/// Custom painter for the circulating border effect
class _CirculatingBorderPainter extends CustomPainter {
  _CirculatingBorderPainter({required this.animation})
      : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics().first;
    final totalLength = pathMetrics.length;

    final progress = animation.value;

    // Draw multiple light segments traveling around the border
    for (int i = 0; i < 2; i++) {
      // Offset each light segment
      final offset = i * 0.5;
      final segmentStart = ((progress + offset) % 1.0);
      const segmentLength = 0.2; // Length of each light segment

      // Calculate positions
      final startDistance = segmentStart * totalLength;
      final endDistance = ((segmentStart + segmentLength) % 1.0) * totalLength;

      // Handle wrap-around case
      if (endDistance < startDistance) {
        // Draw two segments: end of path and beginning of path
        _drawSegment(canvas, pathMetrics, startDistance, totalLength);
        _drawSegment(canvas, pathMetrics, 0, endDistance);
      } else {
        _drawSegment(canvas, pathMetrics, startDistance, endDistance);
      }
    }
  }

  void _drawSegment(
      Canvas canvas, ui.PathMetric pathMetrics, double start, double end) {
    // Extract the segment path
    final segmentPath = pathMetrics.extractPath(start, end);

    // Get positions for gradient
    final tangentStart = pathMetrics.getTangentForOffset(start);
    final tangentEnd = pathMetrics.getTangentForOffset(end);

    if (tangentStart != null && tangentEnd != null) {
      // Add outer glow effect first (larger, more blurred)
      final outerGlowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      outerGlowPaint.shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(
        Rect.fromPoints(tangentStart.position, tangentEnd.position),
      );

      canvas.drawPath(segmentPath, outerGlowPaint);

      // Inner glow effect
      final innerGlowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      innerGlowPaint.shader = LinearGradient(
        colors: [
          AppColors.cream200.withOpacity(0.0),
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(0.6),
          AppColors.cream200.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 0.7, 1.0],
      ).createShader(
        Rect.fromPoints(tangentStart.position, tangentEnd.position),
      );

      canvas.drawPath(segmentPath, innerGlowPaint);

      // Core bright line
      final corePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      corePaint.shader = LinearGradient(
        colors: [
          AppColors.cream200.withOpacity(0.0),
          Colors.white.withOpacity(1.0),
          Colors.white.withOpacity(1.0),
          AppColors.cream200.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 0.7, 1.0],
      ).createShader(
        Rect.fromPoints(tangentStart.position, tangentEnd.position),
      );

      canvas.drawPath(segmentPath, corePaint);
    }
  }

  @override
  bool shouldRepaint(_CirculatingBorderPainter oldDelegate) => true;
}

class _PulsatingIcon extends StatefulWidget {
  const _PulsatingIcon({
    required this.icon,
    this.size = 20,
    this.isPressed = false,
  });

  final IconData icon;
  final double size;
  final bool isPressed;

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
            boxShadow: widget.isPressed
                ? []
                : [
                    BoxShadow(
                      color: AppColors.salmon400.withOpacity(_glow.value),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
            gradient: widget.isPressed
                ? const LinearGradient(
                    colors: [Colors.white, Colors.white],
                  )
                : const LinearGradient(
                    colors: [AppColors.pink500, AppColors.salmon400],
                  ),
          ),
          child: Transform.scale(
            scale: _scale.value,
            child: Icon(
              widget.icon,
              color: widget.isPressed ? AppColors.pink700 : Colors.white,
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}

// Tiled Icons Widget
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
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500 + (widget.index % 500)),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
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
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            widget.icon,
            size: widget.size,
            color: AppColors.pink500.withOpacity(widget.opacity),
          ),
        );
      },
    );
  }
}

/// Cart success popup
class _CartSuccessPopup extends StatelessWidget {
  const _CartSuccessPopup({
    required this.cartCount,
    required this.onDismiss,
  });

  final int cartCount;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.pink500, AppColors.salmon400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Added to Cart!',
                style: GoogleFonts.ubuntu(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.pink700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Added to cart successfully!',
                textAlign: TextAlign.center,
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pink500,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.pink500, AppColors.salmon400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        'Continue',
                        style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
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
}
