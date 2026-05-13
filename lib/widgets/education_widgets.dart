import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/education_content.dart';

class ConfettiParticle {
  late double x;
  late double y;
  late double velocity;
  late Color color;
  late double size;
  late double rotation;
  late double rotationSpeed;
  late BoxShape shape;

  ConfettiParticle() {
    final random = Random();
    x = random.nextDouble() * 600 - 300;
    y = -50 - random.nextDouble() * 100;
    velocity = 1 + random.nextDouble() * 2;
    color = AppColors.speakerPalette[random.nextInt(AppColors.speakerPalette.length)];
    size = 3 + random.nextDouble() * 6;
    rotation = random.nextDouble() * 2 * pi;
    rotationSpeed = (random.nextDouble() - 0.5) * 0.15;
    shape = random.nextBool() ? BoxShape.circle : BoxShape.rectangle;
  }

  void update() {
    y += velocity;
    rotation += rotationSpeed;
  }

  bool isOffScreen(double screenHeight) {
    return y > screenHeight + 100;
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.richBrown,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class DividerLine extends StatelessWidget {
  const DividerLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(color: Colors.black.withValues(alpha: 0.1), thickness: 1, height: 28);
  }
}

class TriviaWidget extends StatefulWidget {
  const TriviaWidget({super.key});

  @override
  State<TriviaWidget> createState() => _TriviaWidgetState();
}

class _TriviaWidgetState extends State<TriviaWidget> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _score = 0;
  bool _showResult = false;
  int? _selectedAnswer;
  int? _correctAnswer;

  late final AnimationController _resultController;
  late final AnimationController _confettiController;
  final List<ConfettiParticle> _particles = <ConfettiParticle>[];

  @override
  void initState() {
    super.initState();
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(seconds: 9),
      vsync: this,
    )..addListener(() {
      setState(() {
        for (final particle in _particles) {
          particle.update();
        }
        _particles.removeWhere(
          (particle) => particle.isOffScreen(MediaQuery.of(context).size.height),
        );
      });
    });
  }

  @override
  void dispose() {
    _resultController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _answer(int index) {
    _correctAnswer = triviaQuestions[_currentIndex].correctIndex;
    _selectedAnswer = index;

    if (index == _correctAnswer) {
      HapticFeedback.mediumImpact();
      _score++;
    } else {
      HapticFeedback.heavyImpact();
    }

    setState(() {});
    _resultController.forward();

    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_currentIndex < triviaQuestions.length - 1) {
          _currentIndex++;
          _selectedAnswer = null;
          _correctAnswer = null;
          _resultController.reset();
        } else {
          _showResult = true;
          for (int i = 0; i < 50; i++) {
            _particles.add(ConfettiParticle());
          }
          _confettiController.forward(from: 0);
        }
      });
    });
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _showResult = false;
      _selectedAnswer = null;
      _correctAnswer = null;
      _resultController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      final percent = ((_score / triviaQuestions.length) * 100).toInt();
      return Stack(
        children: <Widget>[
          ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1).animate(
              CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    blurRadius: 20,
                    color: AppColors.richBrown.withValues(alpha: 0.4),
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  const Text(
                    'Quiz finished!',
                    style: TextStyle(
                      color: AppColors.richBrown,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.5, end: 1).animate(
                      CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
                    ),
                    child: Text(
                      '$percent%',
                      style: const TextStyle(
                        color: AppColors.richBrown,
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: _restart,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      backgroundColor: AppColors.richBrown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Restart quiz',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ..._particles.map((particle) {
            final centerX = MediaQuery.of(context).size.width / 2;
            return Positioned(
              left: centerX + particle.x,
              top: particle.y,
              child: Transform.rotate(
                angle: particle.rotation,
                child: Container(
                  width: particle.size,
                  height: particle.size,
                  decoration: BoxDecoration(
                    color: particle.color,
                    shape: particle.shape,
                    borderRadius:
                        particle.shape == BoxShape.rectangle ? BorderRadius.circular(2) : null,
                  ),
                ),
              ),
            );
          }),
        ],
      );
    }

    final question = triviaQuestions[_currentIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.richBrown,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Question ${_currentIndex + 1} of ${triviaQuestions.length}',
                style: const TextStyle(
                  color: Color(0xFFE7D3AE),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Score: $_score/${triviaQuestions.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          ...List<Widget>.generate(
            question.answers.length,
            (index) => _TriviaOptionAnimated(
              text: question.answers[index],
              onTap: () => _answer(index),
              isSelected: _selectedAnswer == index,
              isCorrect: _selectedAnswer == index && index == _correctAnswer,
              resultAnimation: _resultController,
              showFeedback: _selectedAnswer != null,
            ),
          ),
        ],
      ),
    );
  }
}

class _TriviaOptionAnimated extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isCorrect;
  final AnimationController resultAnimation;
  final bool showFeedback;

  const _TriviaOptionAnimated({
    required this.text,
    required this.onTap,
    required this.isSelected,
    required this.isCorrect,
    required this.resultAnimation,
    required this.showFeedback,
  });

  @override
  State<_TriviaOptionAnimated> createState() => _TriviaOptionAnimatedState();
}

class _TriviaOptionAnimatedState extends State<_TriviaOptionAnimated>
    with TickerProviderStateMixin {
  late final AnimationController _tapController;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _tapScale = Tween<double>(begin: 1, end: 0.92).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _tapController.forward().then((_) => _tapController.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    const gentleGreen = AppColors.mutedSage;
    const gentleRed = AppColors.deepMaroon;

    final backgroundColor = widget.isSelected && widget.showFeedback
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.transparent;

    final borderColor = widget.isSelected && widget.showFeedback
        ? (widget.isCorrect ? gentleGreen : gentleRed)
        : Colors.white.withValues(alpha: 0.35);

    final glowColor = widget.isSelected && widget.showFeedback
        ? (widget.isCorrect ? gentleGreen : gentleRed)
        : Colors.transparent;

    if (widget.isSelected && widget.showFeedback) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AnimatedBuilder(
          animation: widget.resultAnimation,
          builder: (context, child) {
            final shakeOffset = widget.isCorrect ? 0.0 : sin(widget.resultAnimation.value * 8 * pi) * 4;
            return Transform.translate(
              offset: Offset(shakeOffset, 0),
              child: _optionContainer(backgroundColor, borderColor, glowColor),
            );
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ScaleTransition(
        scale: _tapScale,
        child: _optionContainer(backgroundColor, borderColor, glowColor),
      ),
    );
  }

  Widget _optionContainer(Color backgroundColor, Color borderColor, Color glowColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor,
        border: Border.all(color: borderColor, width: widget.isSelected ? 2.5 : 1.5),
      ),
      child: OutlinedButton(
        onPressed: widget.isSelected ? null : _handleTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          foregroundColor: Colors.white,
          side: BorderSide(color: borderColor, width: widget.isSelected ? 2.5 : 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (widget.isSelected)
              ScaleTransition(
                scale: widget.resultAnimation,
                child: Icon(
                  widget.isCorrect ? Icons.check_circle : Icons.cancel,
                  color: glowColor,
                  size: 32,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class InteractivePopulationVisual extends StatefulWidget {
  const InteractivePopulationVisual({super.key});

  @override
  State<InteractivePopulationVisual> createState() => _InteractivePopulationVisualState();
}

class _InteractivePopulationVisualState extends State<InteractivePopulationVisual>
    with TickerProviderStateMixin {
  bool isRevealed = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: InkWell(
            onTap: () {
              _pulseController.forward().then((_) => _pulseController.reverse());
              setState(() {
                isRevealed = !isRevealed;
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.softSurface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    blurRadius: 12,
                    color: Colors.black26,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: isRevealed
                      ? Column(
                          key: const ValueKey('ratio'),
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List<Widget>.generate(
                                10,
                                (index) => Icon(
                                  Icons.person,
                                  color: index == 0 ? AppColors.accent : const Color(0xFFDDB5A0),
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Global Ratio',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              '430+ million people',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'require rehabilitation for disabling hearing loss.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        )
                      : const Column(
                          key: ValueKey('tap'),
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                Icon(Icons.person, color: Color(0xFFDDB5A0), size: 20),
                                Icon(Icons.person, color: Color(0xFFDDB5A0), size: 20),
                                Icon(Icons.person, color: Color(0xFFDDB5A0), size: 20),
                                Icon(Icons.person, color: Color(0xFFDDB5A0), size: 20),
                                Icon(Icons.person, color: Color(0xFFDDB5A0), size: 20),
                                Icon(Icons.person, color: Color(0xFFDDB5A0), size: 20),
                                Icon(Icons.person, color: Color(0xFFDDB5A0), size: 20),
                                Icon(Icons.person, color: Color(0xFFDDB5A0), size: 20),
                                Icon(Icons.person, color: Color(0xFFDDB5A0), size: 20),
                                Icon(Icons.person, color: Color(0xFFDDB5A0), size: 20),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  'Tap to reveal the global ratio',
                                  style: TextStyle(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.chevron_right, color: AppColors.accent, size: 20),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class HistoryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const HistoryItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.richBrown,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            blurRadius: 14,
            color: Colors.black26,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AllyTipCard extends StatelessWidget {
  final String text;

  const AllyTipCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.richBrown,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            blurRadius: 14,
            color: Colors.black26,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class SupportButtonTile extends StatelessWidget {
  final String title;
  final String url;
  final VoidCallback onPressed;

  const SupportButtonTile({
    super.key,
    required this.title,
    required this.url,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.richBrown,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.open_in_new, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(url, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BodyTextBlock extends StatelessWidget {
  final String text;

  const BodyTextBlock(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Color.fromARGB(255, 20, 35, 28),
          fontSize: 15,
          height: 1.6,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
