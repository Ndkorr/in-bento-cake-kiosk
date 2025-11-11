import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum CakeViewMode {
  fullView,
  toppingsView,
  separateView,
  stackedView,
}

class CakeCustomizerScreen extends StatefulWidget {
  final String cakeShape;
  final List<String?>? selectedLayers;
  final List<String?>? selectedFillings;
  final String? selectedFrosting;
  final List<String>? selectedToppings;

  const CakeCustomizerScreen({
    super.key,
    required this.cakeShape,
    this.selectedLayers,
    this.selectedFillings,
    this.selectedFrosting,
    this.selectedToppings,
  });

  @override
  State<CakeCustomizerScreen> createState() => _CakeCustomizerScreenState();
}

class _CakeCustomizerScreenState extends State<CakeCustomizerScreen> {
  CakeViewMode _currentView = CakeViewMode.fullView;
  double _summaryHeight = 0.25;
  List<ToppingPlacement> _placedToppings = [];
  String? _selectedToppingToPlace;
  GlobalKey _cakeImageKey = GlobalKey();

  final Map<String, String> _flavorAbbreviations = {
    'Vanilla': 'V',
    'Chocolate': 'C',
    'Ube': 'U',
  };

  // Map incorrect names to correct asset filenames
  final Map<String, String> _toppingAssetNames = {
    'Cherry': 'cherries',
    'Pretzel': 'pretzels',
    'Chocolate': 'chocolate',
    'Mango': 'mango',
    'Sprinkles': 'sprinkles',
  };

  String _getAssetPath(String fileName) {
    if (kIsWeb) {
      return '/in-bento-cake-kiosk/assets/assets/cake_layers/$fileName';
    }
    return 'assets/cake_layers/$fileName';
  }

  String _getImageAssetPath(String fileName) {
    // For Image.asset widget, don't add the web prefix
    return 'assets/cake_layers/$fileName';
  }

  String _buildModelFileName() {
    if (_currentView == CakeViewMode.fullView) {
      if (widget.selectedFrosting != null) {
        return '${widget.selectedFrosting!.toLowerCase()}.glb';
      }
      return 'vanilla.glb';
    }

    if (widget.selectedLayers == null ||
        widget.selectedLayers!.isEmpty ||
        widget.selectedFillings == null ||
        widget.selectedFillings!.isEmpty) {
      return 'VVV.glb';
    }

    final parts = <String>[];
    final layer1 = widget.selectedLayers![0];
    parts.add(_flavorAbbreviations[layer1] ?? 'V');

    final filling = widget.selectedFillings![0];
    parts.add(_flavorAbbreviations[filling] ?? 'V');

    if (widget.selectedLayers!.length >= 2) {
      final layer2 = widget.selectedLayers![1];
      parts.add(_flavorAbbreviations[layer2] ?? 'V');
    } else {
      parts.add('V');
    }

    return '${parts.join('')}.glb';
  }

  String _getModelPath() {
    final fileName = _buildModelFileName();
    final numLayers = widget.selectedLayers?.length ?? 2;
    final shape = widget.cakeShape == 'round' ? 'roundshaped' : 'heartshaped';

    String path;
    switch (_currentView) {
      case CakeViewMode.fullView:
        path = 'full_view/$shape/${numLayers}layers/$fileName';
        break;
      case CakeViewMode.toppingsView:
        // Return the top view image path for toppings (for Image.asset)
        final frostingName = widget.selectedFrosting?.toLowerCase() ?? 'vanilla';
        return _getImageAssetPath('toppings/$shape/${frostingName}top.png');
      case CakeViewMode.separateView:
        path = 'layer_view/$shape/${numLayers}layers/seperate/$fileName';
        break;
      case CakeViewMode.stackedView:
        path = 'layer_view/$shape/${numLayers}layers/stacked/$fileName';
        break;
    }

    return _getAssetPath(path);
  }

  String _buildSummaryText() {
    if (widget.selectedLayers == null || widget.selectedLayers!.isEmpty) {
      return 'Base cake - no customizations';
    }

    final summary = StringBuffer();

    if (widget.selectedLayers != null && widget.selectedLayers!.isNotEmpty) {
      summary.write('Layers: ');
      for (int i = 0; i < widget.selectedLayers!.length; i++) {
        if (i > 0) summary.write(', ');
        summary.write(widget.selectedLayers![i]);
      }
      summary.writeln();
    }

    if (widget.selectedFillings != null &&
        widget.selectedFillings!.isNotEmpty) {
      summary.write('Fillings: ');
      for (int i = 0; i < widget.selectedFillings!.length; i++) {
        if (i > 0) summary.write(', ');
        summary.write(widget.selectedFillings![i]);
      }
      summary.writeln();
    }

    if (widget.selectedFrosting != null) {
      summary.write('Frosting: ${widget.selectedFrosting}');
    }

    return summary.toString().trim();
  }

  String _getViewModeLabel() {
    switch (_currentView) {
      case CakeViewMode.fullView:
        return 'Full View';
      case CakeViewMode.toppingsView:
        return 'Add Toppings';
      case CakeViewMode.separateView:
        return 'Separate Layers';
      case CakeViewMode.stackedView:
        return 'Stacked Layers';
    }
  }

  Widget _buildToppingsView() {
    final toppingAssetPath = _getModelPath();
    
    return Column(
      children: [
        // Topping selection buttons
        if (widget.selectedToppings != null && widget.selectedToppings!.isNotEmpty)
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.selectedToppings!.length,
              itemBuilder: (context, index) {
                final topping = widget.selectedToppings![index];
                final isSelected = _selectedToppingToPlace == topping;
                final toppingAssetName = _toppingAssetNames[topping] ?? topping.toLowerCase();
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedToppingToPlace = isSelected ? null : topping;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 70,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.pink700 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.pink700,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withAlpha(40),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            _getImageAssetPath('toppings/toppings/$toppingAssetName.png'),
                            width: 32,
                            height: 32,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.cake,
                              size: 32,
                              color: isSelected ? Colors.white : AppColors.pink700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            topping,
                            style: GoogleFonts.ubuntu(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.pink700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        // Cake with toppings
        Expanded(
          child: GestureDetector(
            onTapDown: (details) {
              // Only allow adding if a topping is selected
              if (_selectedToppingToPlace == null) {
                return;
              }

              // Get the render box of the cake image
              final RenderBox? cakeBox = _cakeImageKey.currentContext?.findRenderObject() as RenderBox?;
              if (cakeBox == null) return;

              // Get the tap position relative to the cake image
              final localPosition = cakeBox.globalToLocal(details.globalPosition);
              final cakeSize = cakeBox.size;

              // Check if tap is within the cake bounds
              if (localPosition.dx < 0 || localPosition.dx > cakeSize.width ||
                  localPosition.dy < 0 || localPosition.dy > cakeSize.height) {
                return;
              }

              // Calculate center point
              final centerX = cakeSize.width / 2;
              final centerY = cakeSize.height / 2;
              final distanceFromCenter = ((localPosition.dx - centerX) * (localPosition.dx - centerX) +
                  (localPosition.dy - centerY) * (localPosition.dy - centerY));
              
              // Only allow placement within a circular/heart area (adjust radius as needed)
              final maxRadius = (cakeSize.width * 0.4) * (cakeSize.width * 0.4);
              if (distanceFromCenter > maxRadius) {
                return;
              }

              setState(() {
                _placedToppings.add(
                  ToppingPlacement(
                    toppingName: _selectedToppingToPlace!,
                    position: localPosition,
                  ),
                );
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Stack(
                children: [
                  // Background cake top view
                  Positioned.fill(
                    child: Image.asset(
                      key: _cakeImageKey,
                      toppingAssetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.cake, size: 100, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  // Placed toppings
                  ...(_placedToppings.map((topping) {
                    final toppingAssetName = _toppingAssetNames[topping.toppingName] ?? topping.toppingName.toLowerCase();
                    final toppingImagePath = _getImageAssetPath('toppings/toppings/$toppingAssetName.png');
                    return Positioned(
                      left: topping.position.dx - (topping.size / 2),
                      top: topping.position.dy - (topping.size / 2),
                      child: GestureDetector(
                        onTap: () {
                          // Remove topping on tap
                          setState(() {
                            _placedToppings.remove(topping);
                          });
                        },
                        child: Image.asset(
                          toppingImagePath,
                          width: topping.size,
                          height: topping.size,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.error,
                            size: topping.size,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    );
                  }).toList()),
                  // Instruction text
                  if (_selectedToppingToPlace == null && widget.selectedToppings != null && widget.selectedToppings!.isNotEmpty)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Select a topping above to start placing',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ubuntu(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (_selectedToppingToPlace != null)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Tap on cake to place $_selectedToppingToPlace\nTap topping to remove',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ubuntu(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // Clear all button if toppings exist
                  if (_placedToppings.isNotEmpty)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _placedToppings.clear();
                          });
                        },
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: Text(
                          'Clear All',
                          style: GoogleFonts.ubuntu(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pink700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
    );
  }

  void _addToCart() {
    // Pass cart data back to previous screen
    final cartItem = {
      'shape': widget.cakeShape,
      'layers': widget.selectedLayers,
      'fillings': widget.selectedFillings,
      'frosting': widget.selectedFrosting,
      'timestamp': DateTime.now(),
    };

    Navigator.pop(context, cartItem);
  }

  @override
  Widget build(BuildContext context) {
    final modelPath = _getModelPath();
    final summaryText = _buildSummaryText();
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.cream200,
      appBar: AppBar(
        title: Text(
          'Customize Your Cake',
          style: GoogleFonts.ubuntu(
            fontWeight: FontWeight.w900,
            color: AppColors.pink700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.pink700),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _ViewModeButton(
                    label: 'Full View',
                    icon: Icons.cake,
                    isSelected: _currentView == CakeViewMode.fullView,
                    onTap: () {
                      setState(() {
                        _currentView = CakeViewMode.fullView;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ViewModeButton(
                    label: 'Toppings',
                    icon: Icons.cake_outlined,
                    isSelected: _currentView == CakeViewMode.toppingsView,
                    onTap: () {
                      setState(() {
                        _currentView = CakeViewMode.toppingsView;
                      });
                    },
                  ),
                ),
                // Only show Separate and Stacked for 2-layer cakes
                if (widget.selectedLayers != null && widget.selectedLayers!.length == 2) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ViewModeButton(
                      label: 'Separate',
                      icon: Icons.layers_outlined,
                      isSelected: _currentView == CakeViewMode.separateView,
                      onTap: () {
                        setState(() {
                          _currentView = CakeViewMode.separateView;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ViewModeButton(
                      label: 'Stacked',
                      icon: Icons.layers,
                      isSelected: _currentView == CakeViewMode.stackedView,
                      onTap: () {
                        setState(() {
                          _currentView = CakeViewMode.stackedView;
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _currentView == CakeViewMode.toppingsView
                    ? _buildToppingsView()
                    : ModelViewer(
                        key: ValueKey(modelPath),
                        backgroundColor: const Color(0xFFEEEEEE),
                        src: modelPath,
                        alt:
                            'A 3D model of a customized cake - ${_getViewModeLabel()}',
                        ar: false,
                        autoRotate: true,
                        cameraControls: true,
                        disableZoom: false,
                        loading: Loading.eager,
                      ),
              ),
            ),
          ),
          GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _summaryHeight -= details.delta.dy / screenHeight;
                _summaryHeight = _summaryHeight.clamp(0.15, 0.5);
              });
            },
            child: Container(
              height: screenHeight * _summaryHeight,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
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
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.pink700,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Your Customization',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.pink700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              summaryText,
                              style: GoogleFonts.ubuntu(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.pink700,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _addToCart,
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Add to Cart',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  const _ViewModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.pink500, AppColors.salmon400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.pink700,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.pink700,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.ubuntu(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.pink700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Class to store topping placement data
class ToppingPlacement {
  final String toppingName;
  final Offset position;
  final double size;

  ToppingPlacement({
    required this.toppingName,
    required this.position,
    this.size = 50,
  });
}
