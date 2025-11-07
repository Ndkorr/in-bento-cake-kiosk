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
  });

  final Map<String, dynamic> cake;
  final int cakeIndex;

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
  int _numberOfLayers = 2;
  int _numberOfFillings = 1;
  List<String?> _selectedLayers = [];
  List<String?> _selectedFillings = [];
  String? _selectedFrosting;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _showLayerSelectionScreen(int layers) {
    setState(() {
      _numberOfLayers = layers;
      _selectedLayers = List.filled(layers, null);
      _showLayerSelection = true;
      _showFillingSelection = false;
      _showFrostingSelection = false;
    });
    _slideController.forward();
  }

  void _showFillingSelectionScreen(int fillings) {
    setState(() {
      _numberOfFillings = fillings;
      _selectedFillings = List.filled(fillings, null);
      _showFillingSelection = true;
      _showLayerSelection = false;
      _showFrostingSelection = false;
    });
    _slideController.forward();
  }

  void _showFrostingSelectionScreen() {
    setState(() {
      _showFrostingSelection = true;
      _showLayerSelection = false;
      _showFillingSelection = false;
    });
    _slideController.forward();
  }

  void _hideSelection() {
    _slideController.reverse().then((_) {
      setState(() {
        _showLayerSelection = false;
        _showFillingSelection = false;
        _showFrostingSelection = false;
      });
    });
  }

  List<Map<String, String>> _getOptionsForCake() {
    final cakeName = widget.cake['name'] as String;

    if (cakeName == 'Classic Vanilla') {
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
          'subtitle': 'OF YOUR CHOICE',
          'clickable': 'true'
        },
        {
          'title': 'DEDICATION',
          'subtitle': 'PERSONALIZED',
          'clickable': 'false'
        },
      ];
    } else if (cakeName == 'Chocolate Dream') {
      return [
        {
          'title': '3 LAYERS',
          'subtitle': 'OF YOUR CHOSEN VARIATION',
          'clickable': 'true',
          'type': 'layers',
          'count': '3'
        },
        {
          'title': '2 FILLINGS',
          'subtitle': 'OF YOUR CHOICE',
          'clickable': 'true',
          'type': 'fillings',
          'count': '2'
        },
        {
          'title': 'FROSTING',
          'subtitle': 'OF YOUR CHOICE',
          'clickable': 'true',
          'type': 'frosting'
        },
        {
          'title': '5 TOPPINGS',
          'subtitle': 'OF YOUR CHOICE',
          'clickable': 'true'
        },
        {
          'title': 'DEDICATION',
          'subtitle': 'PERSONALIZED',
          'clickable': 'false'
        },
      ];
    } else if (cakeName == 'Strawberry Delight') {
      return [
        {
          'title': '2 LAYERS',
          'subtitle': 'OF YOUR CHOSEN VARIATION',
          'clickable': 'true',
          'type': 'layers',
          'count': '2'
        },
        {
          'title': '1 FILLING',
          'subtitle': 'OF YOUR CHOICE',
          'clickable': 'true',
          'type': 'fillings',
          'count': '1'
        },
        {
          'title': 'FROSTING',
          'subtitle': 'OF YOUR CHOICE',
          'clickable': 'true',
          'type': 'frosting'
        },
        {
          'title': '3 TOPPINGS',
          'subtitle': 'OF YOUR CHOICE',
          'clickable': 'true'
        },
        {
          'title': 'DEDICATION',
          'subtitle': 'PERSONALIZED',
          'clickable': 'false'
        },
      ];
    }

    // Default fallback
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
        'subtitle': 'OF YOUR CHOICE',
        'clickable': 'true'
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
          // Pulsating background icons
          const Positioned.fill(
            child: _TiledIcons(),
          ),
          // Main content
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
                        // The card that grows
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CakeCustomizerScreen(
                                      cakeShape: 'round',
                                    ),
                                  ),
                                );
                              },
                              viewButtonText: 'Customize',
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Customization options
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final isClickable =
                                  options[index]['clickable'] == 'true';
                              return _OptionButton(
                                title: options[index]['title']!,
                                subtitle: options[index]['subtitle']!,
                                isClickable: isClickable,
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
                                        } else {
                                          // TODO: Navigate to other selection screens
                                          debugPrint(
                                              'Tapped: ${options[index]['title']}');
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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Layer selection overlay
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
                onBack: _hideSelection,
              ),
            ),
          // Filling selection overlay
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
                onBack: _hideSelection,
              ),
            ),
          // Frosting selection overlay
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
                onBack: _hideSelection,
              ),
            ),
        ],
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
    this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isClickable;
  final VoidCallback? onTap;

  @override
  State<_OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<_OptionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
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
          child: widget.isClickable
              ? _CirculatingBorderWrapper(
                  child: _buildContent(),
                )
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
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
          _PulsatingIcon(
            icon: Icons.auto_awesome,
            size: 22,
            isPressed: _isPressed,
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
          // Show pulsating chevron icon if clickable
          if (widget.isClickable) ...[
            const SizedBox(width: 8),
            _PulsatingChevron(isPressed: _isPressed),
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
