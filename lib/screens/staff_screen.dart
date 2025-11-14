import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import 'welcome_screen.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  // Dummy user list for demonstration
  int? _selectedUserIndex;
  bool _showUserManager = false;
  String? _selectedUserDocId;

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

  Future<void> _addUser() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add User'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'user@inbento.com',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final email = controller.text.trim();
              if (email.isNotEmpty) {
                Navigator.pop(context, email);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').add({
        'user': result,
        // Optionally add a password or other fields here
      });
    }
  }

  Future<void> _deleteUser() async {
    if (_selectedUserDocId != null) {
      await FirebaseFirestore.instance.collection('users').doc(_selectedUserDocId).delete();
      setState(() {
        _selectedUserIndex = null;
        _selectedUserDocId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showUserManager) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Users'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _hideManageUsers,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final selected = _selectedUserIndex == index;
                        return ListTile(
                          title: Text(data['user'] ?? ''),
                          selected: selected,
                          onTap: () {
                            setState(() {
                              _selectedUserIndex = index;
                              _selectedUserDocId = docs[index].id;
                            });
                          },
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
                      onTap: _selectedUserDocId != null ? _deleteUser : null,
                    ),
                  ),
                ],
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
          const TiledIcons(), // Moving icons background
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Pie charts row with hover
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _HoverPieCard(
                        title: 'Total Sales',
                        pie: _SamplePieChart(
                          sections: [
                            PieChartSectionData(
                              color: AppColors.pink500,
                              value: 60,
                              title: 'Cakes',
                              radius: 48,
                              titleStyle: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                            ),
                            PieChartSectionData(
                              color: AppColors.salmon400,
                              value: 40,
                              title: 'Drinks',
                              radius: 48,
                              titleStyle: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _HoverPieCard(
                        title: 'Ingredients Used',
                        pie: _SamplePieChart(
                          sections: [
                            PieChartSectionData(
                              color: AppColors.peach300,
                              value: 50,
                              title: 'Flour',
                              radius: 48,
                              titleStyle: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                            ),
                            PieChartSectionData(
                              color: AppColors.pink700,
                              value: 30,
                              title: 'Eggs',
                              radius: 48,
                              titleStyle: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                            ),
                            PieChartSectionData(
                              color: AppColors.salmon400,
                              value: 20,
                              title: 'Sugar',
                              radius: 48,
                              titleStyle: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                AnimatedHoverButton(
                    label: 'Orders', icon: Icons.receipt_long, onTap: () {}),
                const SizedBox(height: 16),
                AnimatedHoverButton(
                    label: 'Edit kiosk', icon: Icons.edit, onTap: () {}),
                const SizedBox(height: 16),
                AnimatedHoverButton(
                  label: 'Manage users',
                  icon: Icons.people,
                  onTap: _showManageUsers,
                ),
                const SizedBox(height: 16),
                AnimatedHoverButton(
                    label: 'About', icon: Icons.info_outline, onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverPieCard extends StatefulWidget {
  final String title;
  final Widget pie;

  const _HoverPieCard({required this.title, required this.pie});

  @override
  State<_HoverPieCard> createState() => _HoverPieCardState();
}

class _HoverPieCardState extends State<_HoverPieCard> {
  bool _hovering = false;

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
            // Animated label background
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
                    borderRadius: BorderRadius.vertical(
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
            // The card with the pie chart (on top)
            MouseRegion(
              onEnter: (_) => setState(() => _hovering = true),
              onExit: (_) => setState(() => _hovering = false),
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
                      width: cardWidth * 0.67, // scale pie chart with card
                      child: widget.pie,
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
