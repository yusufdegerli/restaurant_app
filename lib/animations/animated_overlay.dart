import 'package:flutter/material.dart';
import 'dart:ui';

class AnimatedOverlay extends StatefulWidget {
  final Offset initialPosition;
  final Size initialSize;
  final Color buttonColor;
  final VoidCallback onAnimationComplete;
  final bool reverse;

  const AnimatedOverlay({
    Key? key,
    required this.initialPosition,
    required this.initialSize,
    required this.buttonColor,
    required this.onAnimationComplete,
    this.reverse = false,
  }) : super(key: key);

  @override
  _AnimatedOverlayState createState() => _AnimatedOverlayState();
}

class _AnimatedOverlayState extends State<AnimatedOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.reverse) {
        _controller.value = 1.0;
        _controller.reverse();
      } else {
        _controller.forward();
      }
    });

    _controller.addStatusListener((status) {
      if ((widget.reverse && status == AnimationStatus.dismissed) ||
          (!widget.reverse && status == AnimationStatus.completed)) {
        widget.onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _calculateMaxRadius(Size screenSize, Offset center) {
    final distances = [
      (center - const Offset(0, 0)).distance,
      (center - Offset(screenSize.width, 0)).distance,
      (center - Offset(0, screenSize.height)).distance,
      (center - Offset(screenSize.width, screenSize.height)).distance,
    ];
    return distances.reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final buttonCenter = widget.initialPosition + Offset(
      widget.initialSize.width / 2,
      widget.initialSize.height / 2,
    );
    final maxRadius = _calculateMaxRadius(screenSize, buttonCenter);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final radius = lerpDouble(widget.initialSize.width / 2, maxRadius, _controller.value)!;
        return Positioned(
          left: buttonCenter.dx - radius,
          top: buttonCenter.dy - radius,
          child: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              color: widget.buttonColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}