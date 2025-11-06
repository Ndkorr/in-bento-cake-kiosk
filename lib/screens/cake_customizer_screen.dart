import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Your Cake'),
        backgroundColor: Colors.white,
      ),
      body: ModelViewer(
        backgroundColor: Colors.white,
        src: 'assets/cake_layers/${widget.cakeShape}_base.glb',
        alt: 'A 3D model of a cake',
        ar: true,
        autoRotate: true,
        cameraControls: true,
      ),
    );
  }
}
