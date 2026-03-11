import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A widget that adds a glowing effect to any child widget
class GlowingContainer extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double glowBlurRadius;
  final bool animate;

  const GlowingContainer({
    Key? key,
    required this.child,
    this.glowColor = Colors.white,
    this.glowBlurRadius = 12,
    this.animate = true,
  }) : super(key: key);

  @override
  State<GlowingContainer> createState() => _GlowingContainerState();
}

class _GlowingContainerState extends State<GlowingContainer>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _glowController = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      )..repeat(reverse: true);

      _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    if (widget.animate) {
      _glowController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(
                  alpha: 0.3 * _glowAnimation.value,
                ),
                blurRadius: widget.glowBlurRadius * _glowAnimation.value,
                spreadRadius: 2 * _glowAnimation.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A button with ripple and scale animation feedback
class AnimatedRippleButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color rippleColor;
  final BorderRadius borderRadius;

  const AnimatedRippleButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.rippleColor = Colors.white,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  }) : super(key: key);

  @override
  State<AnimatedRippleButton> createState() => _AnimatedRippleButtonState();
}

class _AnimatedRippleButtonState extends State<AnimatedRippleButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
      widget.onPressed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: widget.borderRadius,
          splashColor: widget.rippleColor.withValues(alpha: 0.3),
          highlightColor: widget.rippleColor.withValues(alpha: 0.1),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Floating animation that moves widgets up and down smoothly
class FloatingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;

  const FloatingWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 3000),
    this.offset = 10.0,
  }) : super(key: key);

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0.0, end: widget.offset).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_floatAnimation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Confetti particle effect
class ConfettiPainter extends CustomPainter {
  final List<Offset> particles;
  final Color color;

  ConfettiPainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      canvas.drawCircle(particle, 3, paint);
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}

/// Celebratory confetti effect
class CelebrationEffect extends StatefulWidget {
  final VoidCallback onComplete;
  final Duration duration;
  final List<Color> colors;

  const CelebrationEffect({
    Key? key,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 1500),
    this.colors = const [
      Color(0xFFC67C4E),
      Color(0xFFFFDAB9),
      Color(0xFFF7EFDD),
      Color(0xFF8B6B5F),
    ],
  }) : super(key: key);

  @override
  State<CelebrationEffect> createState() => _CelebrationEffectState();
}

class _CelebrationEffectState extends State<CelebrationEffect>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late List<Offset> _particles;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _particles = List.generate(20, (i) {
      return Offset.zero;
    });

    _celebrationController.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        final progress = _celebrationController.value;
        List<Offset> animatedParticles = List.generate(_particles.length, (i) {
          final angle = (i / _particles.length) * 2 * 3.14159;
          final velocity = 200.0;
          final x = math.cos(angle) * velocity * progress;
          final y = -math.sin(angle) * velocity * progress + (9.8 * progress * progress * 50);
          return Offset(x, y);
        });

        return CustomPaint(
          painter: ConfettiPainter(
            particles: animatedParticles,
            color: widget.colors[_celebrationController.value.toInt() % widget.colors.length],
          ),
        );
      },
    );
  }
}
