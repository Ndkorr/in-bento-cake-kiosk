import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

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
  // Map flavor names to colors (hex format for model-viewer)
  final Map<String, String> _flavorColors = {
    'Vanilla': '#F5E6D3', // Cream/beige color
    'Chocolate': '#3D2817', // Dark brown
    'Ube': '#7B68A6', // Purple
  };

  String _getAssetPath(String fileName) {
    return kIsWeb
        ? 'assets/assets/cake_layers/$fileName'
        : 'assets/cake_layers/$fileName';
  }

  String _getModelPath() {
    // Load the base layer model
    final basePath =
        widget.cakeShape == 'round' ? 'round_base.glb' : 'square_base.glb';
    return _getAssetPath(basePath);
  }

  String _buildMaterialScript() {
    final scripts = <String>[];

    // Set colors for layers in round_base.glb
    if (widget.selectedLayers != null) {
      for (int i = 0; i < widget.selectedLayers!.length; i++) {
        final flavor = widget.selectedLayers![i];
        if (flavor != null && _flavorColors.containsKey(flavor)) {
          final materialName = 'layer${i + 1}';
          final color = _flavorColors[flavor];
          scripts.add('''
            const material_$materialName = viewer.model.materials.find(m => m.name === '$materialName');
            if (material_$materialName) {
              material_$materialName.pbrMetallicRoughness.setBaseColorFactor('$color');
            }
          ''');
        }
      }
    }

    return scripts.join('\n');
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

  @override
  Widget build(BuildContext context) {
    final modelPath = _getModelPath();
    final summaryText = _buildSummaryText();
    final materialScript = _buildMaterialScript();

    // Determine the number of layers to show correct frosting model
    final numLayers = widget.selectedLayers?.length ?? 2;
    final frostingModel = widget.cakeShape == 'round'
        ? 'round_frosting_${numLayers}layer.glb'
        : 'square_frosting_${numLayers}layer.glb';
    final fillingModel = widget.cakeShape == 'round'
        ? 'round_filling.glb'
        : 'square_filling.glb';

    // Get colors for filling and frosting
    final fillingColor = widget.selectedFillings != null &&
            widget.selectedFillings!.isNotEmpty &&
            widget.selectedFillings![0] != null
        ? _flavorColors[widget.selectedFillings![0]]
        : null;

    final frostingColor = widget.selectedFrosting != null
        ? _flavorColors[widget.selectedFrosting]
        : null;

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
          // 3D Model Viewer
          Expanded(
            flex: 3,
            child: Container(
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Base layers
                    ModelViewer(
                      backgroundColor: const Color(0xFFFFFFFF),
                      src: modelPath,
                      alt: 'A 3D model of cake layers',
                      ar: true,
                      autoRotate: true,
                      cameraControls: true,
                      loading: Loading.eager,
                      relatedCss: '''
                        model-viewer {
                          width: 100%;
                          height: 100%;
                        }
                      ''',
                      relatedJs: materialScript.isNotEmpty
                          ? '''
                            const viewer = document.querySelector('model-viewer');
                            viewer.addEventListener('load', () => {
                              $materialScript
                            });
                          '''
                          : null,
                    ),
                    // Filling layer (if selected)
                    if (fillingColor != null)
                      Positioned.fill(
                        child: ModelViewer(
                          backgroundColor: Colors.transparent,
                          src: _getAssetPath(fillingModel),
                          alt: 'Cake filling',
                          autoRotate: true,
                          cameraControls: true,
                          loading: Loading.eager,
                          relatedJs: '''
                            const viewer = document.querySelector('model-viewer');
                            viewer.addEventListener('load', () => {
                              const material = viewer.model.materials[0];
                              if (material) {
                                material.pbrMetallicRoughness.setBaseColorFactor('$fillingColor');
                              }
                            });
                          ''',
                        ),
                      ),
                    // Frosting layer (if selected)
                    if (frostingColor != null)
                      Positioned.fill(
                        child: ModelViewer(
                          backgroundColor: Colors.transparent,
                          src: _getAssetPath(frostingModel),
                          alt: 'Cake frosting',
                          autoRotate: true,
                          cameraControls: true,
                          loading: Loading.eager,
                          relatedJs: '''
                            const viewer = document.querySelector('model-viewer');
                            viewer.addEventListener('load', () => {
                              const material = viewer.model.materials[0];
                              if (material) {
                                material.pbrMetallicRoughness.setBaseColorFactor('$frostingColor');
                              }
                            });
                          ''',
                        ),
                      ),
                  ],
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
