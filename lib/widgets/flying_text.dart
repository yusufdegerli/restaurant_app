import 'package:flutter/material.dart';

class FlyingText extends StatefulWidget {
  final String text;
  final Offset start;
  final Offset end;
  final Size startSize;
  final Size endSize;
  final VoidCallback onEnd;
  final TextStyle? style;
  const FlyingText({required this.text, required this.start, required this.end, required this.startSize, required this.endSize, required this.onEnd, this.style, Key? key}) : super(key: key);

  @override
  State<FlyingText> createState() => _FlyingTextState();
}

class _FlyingTextState extends State<FlyingText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;
  late Animation<double> _width;
  late Animation<double> _height;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _position = Tween<Offset>(begin: widget.start, end: widget.end).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _width = Tween<double>(begin: widget.startSize.width, end: widget.endSize.width).animate(_controller);
    _height = Tween<double>(begin: widget.startSize.height, end: widget.endSize.height).animate(_controller);
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onEnd();
      }
    });
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
        return Positioned(
          left: _position.value.dx,
          top: _position.value.dy,
          child: SizedBox(
            width: _width.value,
            height: _height.value,
            child: Center(
              child: Text(widget.text, style: widget.style),
            ),
          ),
        );
      },
    );
  }
} 