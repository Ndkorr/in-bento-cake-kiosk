import 'package:flutter/material.dart';
import 'dart:async';
import '../screens/screensaver_screen.dart';
import '../screens/staff_screen.dart';
import '../screens/payment_method_screen.dart';

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
  State<IdleDetector> createState() => IdleDetectorState();
}

class IdleDetectorState extends State<IdleDetector> {
  Timer? _idleTimer;
  bool _isPaused = false;

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

  void pauseTimer() {
    _idleTimer?.cancel();
    _isPaused = true;
  }

  void resumeTimer() {
    _isPaused = false;
    _resetTimer();
  }

  void _resetTimer() {
    if (_isPaused) return;
    _idleTimer?.cancel();
    
    // Use 2 minutes for QR payment screen, normal duration for others
    final navigator = widget.navigatorKey.currentState;
    Duration timeoutDuration = widget.idleDuration;
    
    if (navigator != null) {
      final isQrPaymentScreen = _isQrPaymentScreenVisible(navigator.context);
      if (isQrPaymentScreen) {
        timeoutDuration = const Duration(minutes: 2);
      }
    }
    
    _idleTimer = Timer(timeoutDuration, _onIdle);
  }

  void _onIdle() async {
    if (_isPaused) return;

    final navigator = widget.navigatorKey.currentState;
    if (navigator != null) {
      // Check if StaffScreen is visible (exempt from idle timeout)
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

  // Helper function to check if QrPaymentScreen is visible
  bool _isQrPaymentScreenVisible(BuildContext context) {
    bool found = false;
    void visitor(Element element) {
      if (element.widget is QrPaymentScreen) {
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