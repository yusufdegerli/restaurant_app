import 'package:flutter/material.dart';

class AnimatedSheetContent extends StatefulWidget {
  final Widget child;
  final ScrollController scrollController;
  const AnimatedSheetContent({required this.child, required this.scrollController, Key? key}) : super(key: key);

  @override
  State<AnimatedSheetContent> createState() => _AnimatedSheetContentState();
}

class _AnimatedSheetContentState extends State<AnimatedSheetContent> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 350));
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
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
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: SlideTransition(
          position: _slide,
          child: SingleChildScrollView(
            controller: widget.scrollController,
            child: widget.child,
          ),
        ),
      ),
      child: widget.child,
    );
  }
} 