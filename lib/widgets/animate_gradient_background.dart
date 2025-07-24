import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // ThemeProvider için
import 'animated_particles.dart'; // AnimatedParticles için

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final bool includeParticles; // Partikül animasyonunu isteğe bağlı yapar

  const AnimatedGradientBackground({
    Key? key,
    required this.child,
    this.includeParticles = false,
  }) : super(key: key);

  @override
  _AnimatedGradientBackgroundState createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _gradientController;
  late Animation<Alignment> _beginAnimation;
  late Animation<Alignment> _endAnimation;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _beginAnimation = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(_gradientController);

    _endAnimation = Tween<Alignment>(
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
    ).animate(_gradientController);
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    final gradientColors = isDarkMode
        ? [const Color(0xFF000000), const Color(0xFF000B58)]
        : [const Color(0xFFFEFFC4), const Color(0xFFF5D667)];

    return Stack(
      children: [
        if (widget.includeParticles)
          AnimatedParticles(isDarkMode: isDarkMode), // Partikül animasyonu
        AnimatedBuilder(
          animation: _gradientController,
          builder: (context, _) {
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: _beginAnimation.value,
                  end: _endAnimation.value,
                ),
              ),
              child: widget.child,
            );
          },
        ),
      ],
    );
  }
}