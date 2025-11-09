import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum CakeViewMode {
  fullView,
  separateView,
  stackedView,
}

class CakeCustomizerScreen extends StatefulWidget {
  final String cakeShape;
  final List<String?>? selectedLayers;
  final List<String?>? selectedFillings;
  final String? selectedFrosting;

  const CakeCustomizerScreen({
    super.key,
    required this.cakeShape,
    this.selectedLayers,
    this.selectedFillings,
    this.selectedFrosting,
  });

  @override
  State<CakeCustomizerScreen> createState() => _CakeCustomizerScreenState();
}

class _CakeCustomizerScreenState extends State<CakeCustomizerScreen> {
  CakeViewMode _currentView = CakeViewMode.fullView;
  String _debugInfo = '';

  // Map flavor names to abbreviations
  final Map<String, String> _flavorAbbreviations = {
    'Vanilla': 'V',
    'Chocolate': 'C',
    'Ube': 'U',
  };

  String _getAssetPath(String fileName) {
    if (kIsWeb) {
      return 'assets/cake_layers/$fileName';
    } else {
      return 'assets/cake_layers/$fileName';
    }
  }
  

  String _buildModelFileName() {
    // For full view, use frosting name
    if (_currentView == CakeViewMode.fullView) {
      if (widget.selectedFrosting != null) {
        return '${widget.selectedFrosting!.toLowerCase()}.glb';
      }
      return 'vanilla.glb'; // Default
    }

    // For layer views (separate/stacked), use abbreviation format
    if (widget.selectedLayers == null ||
        widget.selectedLayers!.isEmpty ||
        widget.selectedFillings == null ||
        widget.selectedFillings!.isEmpty) {
      return 'VVV.glb'; // Default
    }

    final parts = <String>[];

    // First layer
    final layer1 = widget.selectedLayers![0];
    parts.add(_flavorAbbreviations[layer1] ?? 'V');

    // Filling
    final filling = widget.selectedFillings![0];
    parts.add(_flavorAbbreviations[filling] ?? 'V');

    // Second layer (if 2 layers) or more
    if (widget.selectedLayers!.length >= 2) {
      final layer2 = widget.selectedLayers![1];
      parts.add(_flavorAbbreviations[layer2] ?? 'V');
    } else {
      parts.add('V'); // Default
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
      case CakeViewMode.separateView:
        path = 'layer_view/$shape/${numLayers}layers/seperate/$fileName';
        break;
      case CakeViewMode.stackedView:
        path = 'layer_view/$shape/${numLayers}layers/stacked/$fileName';
        break;
    }

    final fullPath = _getAssetPath(path);

    // Update debug info
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _debugInfo =
              'File: $fileName\nPath: $fullPath\nLayers: ${widget.selectedLayers}\nFillings: ${widget.selectedFillings}\nFrosting: ${widget.selectedFrosting}';
        });
      }
    });

    return fullPath;
  }

  String _buildSummaryText() {
    if (widget.selectedLayers == null || widget.selectedLayers!.isEmpty) {
      return 'Base cake - no customizations';
    }

    final summary = StringBuffer();

    // Layers
    if (widget.selectedLayers != null && widget.selectedLayers!.isNotEmpty) {
      summary.writeln('Layers:');
      for (int i = 0; i < widget.selectedLayers!.length; i++) {
        summary.writeln('  Layer ${i + 1}: ${widget.selectedLayers![i]}');
      }
    }

    // Fillings
    if (widget.selectedFillings != null &&
        widget.selectedFillings!.isNotEmpty) {
      summary.writeln('\nFillings:');
      for (int i = 0; i < widget.selectedFillings!.length; i++) {
        summary.writeln('  Filling ${i + 1}: ${widget.selectedFillings![i]}');
      }
    }

    // Frosting
    if (widget.selectedFrosting != null) {
      summary.writeln('\nFrosting: ${widget.selectedFrosting}');
    }

    return summary.toString().trim();
  }

  String _getViewModeLabel() {
    switch (_currentView) {
      case CakeViewMode.fullView:
        return 'Full View';
      case CakeViewMode.separateView:
        return 'Separate Layers';
      case CakeViewMode.stackedView:
        return 'Stacked Layers';
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelPath = _getModelPath();
    final summaryText = _buildSummaryText();

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
          // View mode selector
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
            ),
          ),
          // 3D Model Viewer
          Expanded(
            flex: 3,
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
                child: ModelViewer(
                  key: ValueKey(modelPath), // Force rebuild when path changes
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
          // Customization Summary
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Customization',
                      style: GoogleFonts.ubuntu(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.pink700,
                      ),
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
                    const SizedBox(height: 16),
                    Text(
                      'Debug Info:\n$_debugInfo',
                      style: GoogleFonts.ubuntu(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: AppColors.pink500,
                        fontStyle: FontStyle.italic,
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

/// View mode button widget
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
