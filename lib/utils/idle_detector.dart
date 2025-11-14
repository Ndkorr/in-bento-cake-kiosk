import 'package:flutter/material.dart';
import 'dart:async';
import '../screens/screensaver_screen.dart';
import '../screens/staff_screen.dart';

class IdleDetector extends StatefulWidget {
  const IdleDetector({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.idleDuration = const Duration(seconds: 30),
    this.onIdleReturn,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final Duration idleDuration;
  final VoidCallback? onIdleReturn;

  @override
  State<IdleDetector> createState() => _IdleDetectorState();
}

class _IdleDetectorState extends State<IdleDetector> {
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(widget.idleDuration, _onIdle);
  }

  void _onIdle() async {
    final navigator = widget.navigatorKey.currentState;
    if (navigator != null) {
      // Check if StaffScreen is visible
      final isStaffScreen = _isStaffScreenVisible(navigator.context);
      if (isStaffScreen) {
        _resetTimer();
        return;
      }

      await navigator.push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ScreensaverScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );

      widget.onIdleReturn?.call();
      _resetTimer();
    }
  }

// Helper function to check if StaffScreen is visible
  bool _isStaffScreenVisible(BuildContext context) {
    // Traverse the widget tree to see if StaffScreen is in the tree
    bool found = false;
    void visitor(Element element) {
      if (element.widget is StaffScreen) {
        found = true;
      } else {
        element.visitChildren(visitor);
      }
    }

    context.visitChildElements(visitor);
    return found;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _resetTimer,
      onPanDown: (_) => _resetTimer(),
      onScaleStart: (_) => _resetTimer(),
      child: Listener(
        onPointerDown: (_) => _resetTimer(),
        onPointerMove: (_) => _resetTimer(),
        child: widget.child,
      ),
    );
  }
}
