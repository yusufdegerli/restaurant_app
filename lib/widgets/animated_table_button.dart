import 'package:flutter/material.dart';

class AnimatedTableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isOccupied;
  final Key? buttonKey;
  final Color? buttonColor;
  const AnimatedTableButton({required this.child, required this.onTap, this.onLongPress, required this.isOccupied, this.buttonKey, this.buttonColor, Key? key}) : super(key: key);

  @override
  State<AnimatedTableButton> createState() => _AnimatedTableButtonState();
}

class _AnimatedTableButtonState extends State<AnimatedTableButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 120), lowerBound: 0.95, upperBound: 1.0);
    _scale = _controller.drive(Tween(begin: 1.0, end: 0.95));
    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.reverse();
  void _onTapUp(_) => _controller.forward();

  Color _getGlowColor(BuildContext context) {
    final base = widget.buttonColor ?? Theme.of(context).colorScheme.primary;
    final brightness = Theme.of(context).brightness;
    // Light mode için biraz daha açık, dark mode için biraz daha koyu bir renk
    if (brightness == Brightness.dark) {
      return base.withOpacity(0.5).withBlue((base.blue + 40).clamp(0, 255));
    } else {
      return base.withOpacity(0.5).withRed((base.red + 40).clamp(0, 255));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: widget.buttonKey,
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _controller.forward,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: Container(
            decoration: widget.isOccupied
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: widget.buttonColor, // Arka plan rengi eklendi
                    boxShadow: [
                      BoxShadow(
                        color: _getGlowColor(context),
                        blurRadius: 18 + 6 * (1 - _scale.value),
                        spreadRadius: 2 + 2 * (1 - _scale.value),
                      ),
                    ],
                  )
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: widget.buttonColor, // Arka plan rengi eklendi
                  ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                splashColor: (widget.buttonColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.2),
                highlightColor: (widget.buttonColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.1),
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 