import 'package:flutter/material.dart';
import 'dart:math';

class Particle {
  Offset position;
  double speed;
  double radius;

  Particle({
    required this.position,
    required this.speed,
    required this.radius,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final bool isDarkMode;

  ParticlePainter(this.particles, this.isDarkMode);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode
          ? Colors.white.withOpacity(0.9)
          : Colors.black.withOpacity(0.7);
    canvas.drawCircle(Offset(100, 100), 10, paint); // Sabit test partikülü
    for (var p in particles) {
      canvas.drawCircle(p.position, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return particles != oldDelegate.particles;
  }
}

class AnimatedParticles extends StatefulWidget {
  final bool isDarkMode;
  const AnimatedParticles({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  State<AnimatedParticles> createState() => _AnimatedParticlesState();
}

class _AnimatedParticlesState extends State<AnimatedParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Particle> _particles = [];
  final int count = 150;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_updateParticles);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initParticles(MediaQuery.of(context).size);
    });

    _controller.repeat();
  }

  void _initParticles(Size size) {
    _particles.clear();
    for (int i = 0; i < count; i++) {
      _particles.add(
        Particle(
          position:
          Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
          speed: random.nextDouble() * 0.7 + 0.3,
          radius: random.nextDouble() * 3 + 1.0,
        ),
      );
    }
  }

  void _updateParticles() {
    final size = MediaQuery.of(context).size;
    for (var p in _particles) {
      var y = p.position.dy + p.speed;
      if (y > size.height) y = 0;
      p.position = Offset(p.position.dx, y);
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return IgnorePointer(
          child: SizedBox.expand(
            child: CustomPaint(
              painter: ParticlePainter(_particles, widget.isDarkMode),
              child: Container(),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}