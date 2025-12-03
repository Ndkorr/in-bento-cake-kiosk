import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';

enum CakeViewMode {
  fullView,
  toppingsView,
  separateView,
  stackedView,
}

enum DrawingColor {
  vanilla, // White
  chocolate, // Black
}

class CakeCustomizerScreen extends StatefulWidget {
  final String cakeShape;
  final List<String?>? selectedLayers;
  final List<String?>? selectedFillings;
  final String? selectedFrosting;
  final List<String>? selectedToppings;
  final bool enableDrawing;

  const CakeCustomizerScreen({
    super.key,
    required this.cakeShape,
    this.selectedLayers,
    this.selectedFillings,
    this.selectedFrosting,
    this.selectedToppings,
    this.enableDrawing = false,
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
  Timer? _instructionTimer;
  bool _showInstruction = false;
  final GlobalKey _toppingsBoundaryKey = GlobalKey();

  DrawingColor _selectedDrawingColor = DrawingColor.vanilla;
  List<DrawingPoint> _drawingPoints = [];
  bool _showDrawingMode = false;

  Future<Uint8List?> _captureToppingsImage() async {
    try {
      RenderRepaintBoundary? boundary = _toppingsBoundaryKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> _captureDrawing() async {
    try {
      // Capture from the toppings boundary which includes the drawing
      RenderRepaintBoundary? boundary = _toppingsBoundaryKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

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
        final frostingName =
            widget.selectedFrosting?.toLowerCase() ?? 'vanilla';
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
    final bool eraserSelected = _selectedToppingToPlace == '__eraser__';

    return Column(
      children: [
        // Topping selection buttons + Eraser tool + Drawing toggle + Drawing colors
        if (widget.selectedToppings != null &&
            widget.selectedToppings!.isNotEmpty)
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Drawing toggle button (only show if enableDrawing is true)
                if (widget.enableDrawing)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showDrawingMode = !_showDrawingMode;
                        if (_showDrawingMode) {
                          _selectedToppingToPlace = null;
                          _showInstruction = false;
                          _instructionTimer?.cancel();
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 70,
                      decoration: BoxDecoration(
                        gradient: _showDrawingMode
                            ? const LinearGradient(
                                colors: [AppColors.pink500, AppColors.salmon400],
                              )
                            : null,
                        color: _showDrawingMode ? null : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _showDrawingMode ? Colors.transparent : AppColors.pink700,
                          width: 2,
                        ),
                        boxShadow: _showDrawingMode
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
                          Icon(
                            Icons.edit,
                            color: _showDrawingMode ? Colors.white : AppColors.pink700,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Draw',
                            style: GoogleFonts.ubuntu(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _showDrawingMode ? Colors.white : AppColors.pink700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Drawing color buttons (when drawing mode is active)
                if (_showDrawingMode) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDrawingColor = DrawingColor.vanilla;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 70,
                        decoration: BoxDecoration(
                          color: _selectedDrawingColor == DrawingColor.vanilla
                              ? AppColors.pink700
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.pink700,
                            width: 2,
                          ),
                          boxShadow: _selectedDrawingColor == DrawingColor.vanilla
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
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey, width: 2),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Vanilla',
                              style: GoogleFonts.ubuntu(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _selectedDrawingColor == DrawingColor.vanilla
                                    ? Colors.white
                                    : AppColors.pink700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDrawingColor = DrawingColor.chocolate;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 70,
                        decoration: BoxDecoration(
                          color: _selectedDrawingColor == DrawingColor.chocolate
                              ? AppColors.pink700
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.pink700,
                            width: 2,
                          ),
                          boxShadow: _selectedDrawingColor == DrawingColor.chocolate
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
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey, width: 2),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Chocolate',
                              style: GoogleFonts.ubuntu(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _selectedDrawingColor == DrawingColor.chocolate
                                    ? Colors.white
                                    : AppColors.pink700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Clear drawing button
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _drawingPoints.clear();
                        });
                      },
                      child: Container(
                        width: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.clear, color: Colors.red, size: 32),
                            const SizedBox(height: 4),
                            Text(
                              'Clear',
                              style: GoogleFonts.ubuntu(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                // Eraser tool button (only when not in drawing mode)
                if (!_showDrawingMode)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedToppingToPlace =
                            eraserSelected ? null : '__eraser__';
                        _showInstruction = false; // Hide instruction for eraser
                        _instructionTimer?.cancel();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 70,
                      decoration: BoxDecoration(
                        color: eraserSelected ? Colors.red[300] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red,
                          width: 2,
                        ),
                        boxShadow: eraserSelected
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
                          Icon(Icons.auto_fix_normal,
                              color: eraserSelected ? Colors.white : Colors.red,
                              size: 32),
                          const SizedBox(height: 4),
                          Text(
                            'Eraser',
                            style: GoogleFonts.ubuntu(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: eraserSelected ? Colors.white : Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Topping buttons (only when not in drawing mode)
                if (!_showDrawingMode)
                ...widget.selectedToppings!.map((topping) {
                  final isSelected = _selectedToppingToPlace == topping;
                  final toppingAssetName =
                      _toppingAssetNames[topping] ?? topping.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedToppingToPlace = isSelected ? null : topping;
                          _showInstruction =
                              !isSelected; // Show instruction when a topping is selected
                          if (_showInstruction) {
                            _instructionTimer?.cancel();
                          }
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
                              _getImageAssetPath(
                                  'toppings/toppings/$toppingAssetName.png'),
                              width: 32,
                              height: 32,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.cake,
                                size: 32,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.pink700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              topping,
                              style: GoogleFonts.ubuntu(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.pink700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        // Cake with toppings and drawing
        Expanded(
          child: GestureDetector(
            onPanStart: _showDrawingMode ? (details) {
              final RenderBox? cakeBox = _cakeImageKey.currentContext
                  ?.findRenderObject() as RenderBox?;
              if (cakeBox == null) return;
              final localPosition = cakeBox.globalToLocal(details.globalPosition);
              setState(() {
                _drawingPoints.add(DrawingPoint(
                  point: localPosition,
                  color: _selectedDrawingColor == DrawingColor.vanilla
                      ? Colors.white
                      : Colors.black,
                ));
              });
            } : null,
            onPanUpdate: _showDrawingMode ? (details) {
              final RenderBox? cakeBox = _cakeImageKey.currentContext
                  ?.findRenderObject() as RenderBox?;
              if (cakeBox == null) return;
              final localPosition = cakeBox.globalToLocal(details.globalPosition);
              setState(() {
                _drawingPoints.add(DrawingPoint(
                  point: localPosition,
                  color: _selectedDrawingColor == DrawingColor.vanilla
                      ? Colors.white
                      : Colors.black,
                ));
              });
            } : null,
            onPanEnd: _showDrawingMode ? (details) {
              setState(() {
                _drawingPoints.add(DrawingPoint(
                  point: Offset.zero,
                  color: Colors.transparent,
                ));
              });
            } : null,
            onTapDown: !_showDrawingMode ? (details) {
              if (_selectedToppingToPlace == null) {
                return;
              }

              final RenderBox? cakeBox = _cakeImageKey.currentContext
                  ?.findRenderObject() as RenderBox?;
              if (cakeBox == null) return;

              final localPosition =
                  cakeBox.globalToLocal(details.globalPosition);
              final cakeSize = cakeBox.size;

              if (localPosition.dx < 0 ||
                  localPosition.dx > cakeSize.width ||
                  localPosition.dy < 0 ||
                  localPosition.dy > cakeSize.height) {
                return;
              }

              final centerX = cakeSize.width / 2;
              final centerY = cakeSize.height / 2;
              final distanceFromCenter = ((localPosition.dx - centerX) *
                      (localPosition.dx - centerX) +
                  (localPosition.dy - centerY) * (localPosition.dy - centerY));
              final maxRadius = (cakeSize.width * 0.4) * (cakeSize.width * 0.4);
              if (distanceFromCenter > maxRadius) {
                return;
              }

              setState(() {
                if (_selectedToppingToPlace == '__eraser__') {
                  final toRemove = _placedToppings.indexWhere((topping) {
                    final dx = topping.position.dx - localPosition.dx;
                    final dy = topping.position.dy - localPosition.dy;
                    return (dx * dx + dy * dy) <
                        (topping.size / 2) * (topping.size / 2);
                  });
                  if (toRemove != -1) {
                    _placedToppings.removeAt(toRemove);
                  }
                } else {
                  _placedToppings.add(
                    ToppingPlacement(
                      toppingName: _selectedToppingToPlace!,
                      position: localPosition,
                    ),
                  );
                  // Hide the instruction after 2 seconds
                  if (_showInstruction) {
                    _instructionTimer?.cancel();
                    _instructionTimer = Timer(const Duration(seconds: 2), () {
                      if (mounted) {
                        setState(() {
                          _showInstruction = false;
                        });
                      }
                    });
                  }
                }
              });
            } : null,
            child: RepaintBoundary(
              key: _toppingsBoundaryKey,
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
                            child:
                                Icon(Icons.cake, size: 100, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    // Drawing layer (on top of cake, under toppings)
                    if (_showDrawingMode || _drawingPoints.isNotEmpty)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: DrawingPainter(points: _drawingPoints),
                        ),
                      ),
                    // Placed toppings (no tap-to-remove)
                    ...(_placedToppings.map((topping) {
                      final toppingAssetName =
                          _toppingAssetNames[topping.toppingName] ??
                              topping.toppingName.toLowerCase();
                      final toppingImagePath = _getImageAssetPath(
                          'toppings/toppings/$toppingAssetName.png');
                      return Positioned(
                        left: topping.position.dx - (topping.size / 2),
                        top: topping.position.dy - (topping.size / 2),
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
                      );
                    }).toList()),
                    // Instruction text
                    if (_selectedToppingToPlace != null &&
                        !eraserSelected &&
                        _showInstruction)
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Tap on cake to place $_selectedToppingToPlace',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ubuntu(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (_selectedToppingToPlace != null &&
                        !eraserSelected &&
                        _showInstruction)
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Tap on cake to place $_selectedToppingToPlace',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ubuntu(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (eraserSelected)
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Tap a topping to erase it',
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
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
        ),
      ],
    );
  }

  void _addToCart() async {
  Uint8List? toppingsImage;
  Uint8List? dedicationImage;
  
  if (_currentView == CakeViewMode.toppingsView) {
    await Future.delayed(const Duration(milliseconds: 100));
    toppingsImage = await _captureToppingsImage();
  }
  
  if (_showDrawingMode && _drawingPoints.isNotEmpty) {
    dedicationImage = await _captureDrawing();
  }

  // Count placed toppings
  final Map<String, int> toppingCounts = {};
  for (final t in _placedToppings) {
    toppingCounts[t.toppingName] = (toppingCounts[t.toppingName] ?? 0) + 1;
  }

  final toppingsSummary =
      toppingCounts.entries.map((e) => '${e.key}(x${e.value})').join(', ');

  final selectedToppings =
      _placedToppings.map((t) => t.toppingName).toSet().toList();

  final cartItem = {
    'shape': widget.cakeShape,
    'layers': widget.selectedLayers,
    'fillings': widget.selectedFillings,
    'frosting': widget.selectedFrosting,
    'timestamp': DateTime.now(),
    'toppingsImage': toppingsImage,
    'selectedToppings': selectedToppings,
    'toppingsCounts': toppingCounts,
    'toppingsSummary': toppingsSummary,
    'quantity': 1,
    if (dedicationImage != null) 'dedicationDrawing': dedicationImage,
    if (dedicationImage != null) 'dedicationMode': 'drawing',
  };

  Navigator.pop(context, cartItem);
}

  @override
  void dispose() {
    _instructionTimer?.cancel();
    super.dispose();
  }

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
        body: Stack(
          children: [
            // Cake area (fixed height)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.fromLTRB(
                    16, 90, 16, 16), // <-- Increased top margin
                height: screenHeight * 0.55,
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
            // View mode buttons (keep at top)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
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
                    if (widget.selectedLayers != null &&
                        widget.selectedLayers!.length == 2) ...[
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
            ),
            // Draggable summary bar (overlay at bottom)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
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
                                  colors: [
                                    AppColors.pink500,
                                    AppColors.salmon400
                                  ],
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
            ),

          ],
        ));
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

class DrawingPoint {
  final Offset point;
  final Color color;
  final double strokeWidth;

  DrawingPoint({
    required this.point,
    required this.color,
    this.strokeWidth = 3.0,
  });
}

// Add drawing canvas painter
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].point != Offset.zero &&
          points[i + 1].point != Offset.zero) {
        final paint = Paint()
          ..color = points[i].color
          ..strokeWidth = points[i].strokeWidth
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(points[i].point, points[i + 1].point, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}



class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pink700 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.pink700,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 1),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.ubuntu(
                fontSize: 16,
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
