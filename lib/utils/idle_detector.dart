import 'package:flutter/material.dart';
import 'dart:async';
import '../screens/screensaver_screen.dart';

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

      // When returning from screensaver, reset the welcome screen
      widget.onIdleReturn?.call();
      _resetTimer();
    }
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
