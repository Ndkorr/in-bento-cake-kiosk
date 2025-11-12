import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import 'welcome_screen.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    _HoverPieCard(
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
                    _HoverPieCard(
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
                  ],
                ),
                const SizedBox(height: 32),
                // Buttons
                _StaffButton(
                    label: 'Orders', icon: Icons.receipt_long, onTap: () {}),
                const SizedBox(height: 16),
                _StaffButton(
                    label: 'Edit kiosk', icon: Icons.edit, onTap: () {}),
                const SizedBox(height: 16),
                _StaffButton(
                    label: 'Manage users', icon: Icons.people, onTap: () {}),
                const SizedBox(height: 16),
                _StaffButton(
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
    return Column(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: Card(
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 6,
            child: SizedBox(
              width: 240,
              height: 260,
              child: Center(
                child: SizedBox(
                  height: 180,
                  width: 160,
                  child: widget.pie,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2), // Closer to the card
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _hovering
              ? Container(
                  key: const ValueKey('title'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.pink700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                )
              : const SizedBox(
                  key: ValueKey('empty'),
                  height: 20, // Smaller reserved space
                ),
        ),
      ],
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

class _StaffButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _StaffButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: AppColors.pink700),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(label, style: const TextStyle(fontSize: 18)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.pink700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppColors.pink700, width: 2),
          ),
          elevation: 2,
        ),
        onPressed: onTap,
      ),
    );
  }
}