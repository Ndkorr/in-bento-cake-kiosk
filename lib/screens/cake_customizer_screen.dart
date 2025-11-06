import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:model_viewer_plus/model_viewer_plus.dart';

class CakeCustomizerScreen extends StatefulWidget {
  final String cakeShape;

  const CakeCustomizerScreen({super.key, required this.cakeShape});

  @override
  State<CakeCustomizerScreen> createState() => _CakeCustomizerScreenState();
}

class _CakeCustomizerScreenState extends State<CakeCustomizerScreen> {
  @override
  Widget build(BuildContext context) {
    final String modelPath = kIsWeb
        ? 'assets/assets/cake_layers/${widget.cakeShape}_base.glb'
        : 'assets/cake_layers/${widget.cakeShape}_base.glb';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Your Cake'),
        backgroundColor: Colors.white,
      ),
      body: ModelViewer(
        backgroundColor: Colors.white,
        // Flutter Web serves assets under build/web/assets/assets/**
        // so we use a double 'assets' path on web builds.
        src: modelPath,
        alt: 'A 3D model of a cake',
        ar: true,
        autoRotate: true,
        cameraControls: true,
      ),
    );
  }
}
