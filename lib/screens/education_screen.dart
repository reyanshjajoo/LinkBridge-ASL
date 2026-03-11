import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
    x = random.nextDouble() * 600 - 300; // -300 to 300 (full screen width spread)
    y = -50 - random.nextDouble() * 100; // Start above screen
    velocity = 1 + random.nextDouble() * 2; // 1-3 pixels per frame (slower)
    color = [
      const Color(0xFFFFDAB9), // Peach
      const Color(0xFFC67C4E), // Brown
      const Color(0xFF81C784), // Green
      const Color(0xFFE57373), // Coral
      const Color(0xFFFFF3E0), // Light cream
    ][random.nextInt(5)];
    size = 3 + random.nextDouble() * 6; // 3-9 pixels (larger)
    rotation = random.nextDouble() * 2 * pi;
    rotationSpeed = (random.nextDouble() - 0.5) * 0.15; // Slower rotation
    shape = random.nextBool() ? BoxShape.circle : BoxShape.rectangle; // Mix of circles and squares
  }

  void update() {
    y += velocity;
    rotation += rotationSpeed;
  }

  bool isOffScreen(double screenHeight) {
    return y > screenHeight + 100; // Give extra buffer to ensure complete disappearance
  }
}
// import 'package:confetti/confetti.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  // Color constants accessible from the class
  static const Color mintGreen = Color(0xFFFFDAB9);
  static const Color cardGreen = Color(0xFF3C3C3C);
  static const Color deepGreen = Color(0xFF0707A);

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerFadeAnimation;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    ));

    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EducationScreen.mintGreen,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Animated Header card
              FadeTransition(
                opacity: _headerFadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: EducationScreen.cardGreen,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 18,
                        color: Colors.black26,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: const [
                      Text(
                        "DEAF AWARENESS & ASL",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Learn key facts, history, and ways to be an ally.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              _SectionTitle(title: "The Global Population"),
              const InteractivePopulationVisual(),

              const SizedBox(height: 4),

              const _BodyText(
                //"Globally, over 430 million people require rehabilitation to address disabling hearing loss.\n\n"
                "This community spans every age and country. While it is often associated with older adults, millions of children and young adults are also part of this community and may face challenges in education and social integration.",
              ),

              const SizedBox(height: 8),
              const _DividerLine(),

              _SectionTitle(title: "Test Your Knowledge"),
              const TriviaWidget(),

              const SizedBox(height: 8),
              const _DividerLine(),

              _SectionTitle(title: "History of Deafness"),
              const _HistoryItem(
                icon: Icons.gavel,
                title: "Legal hurdles",
                desc:
                    "In the 6th century, the Justinian Code often denied property and marriage rights to deaf individuals who could not speak, creating a long-standing legal stigma.",
              ),
              const _HistoryItem(
                icon: Icons.block,
                title: "The ban on signs",
                desc:
                    "At the 1880 Milan Conference, educators voted to ban sign language in schools, pushing oralism and weakening Deaf culture for decades.",
              ),
              const _HistoryItem(
                icon: Icons.groups_2_outlined,
                title: "Martha’s Vineyard",
                desc:
                    "In the 1700s, hereditary deafness was common enough that many hearing residents used sign language, creating a highly accessible community.",
              ),

              const SizedBox(height: 8),
              const _DividerLine(),

              _SectionTitle(title: "How to Be an Ally"),
              const AllyTip(text: "Get attention with a gentle tap or wave."),
              const AllyTip(
                text: "Face the person so they can see your expressions.",
              ),
              const AllyTip(
                text: "If asked to repeat, do not say “nevermind.”",
              ),

              const SizedBox(height: 8),
              const _DividerLine(),

              _SectionTitle(title: "Ways to Support"),
              _SupportButton(
                title: "Hearing Health Foundation",
                url: "hearinghealthfoundation.org",
                onPressed: () =>
                    _launchURL("https://hearinghealthfoundation.org"),
              ),
              _SupportButton(
                title: "Global Deaf Research",
                url: "globaldeafresearch.org",
                onPressed: () => _launchURL("https://globaldeafresearch.org/"),
              ),
              _SupportButton(
                title: "Global Deaf Research Institute",
                url: "deaforganizationsfund.org",
                onPressed: () => _launchURL(
                  "https://deaforganizationsfund.org/npo/global-deaf-research-institute/",
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFC67C4E),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Colors.black.withOpacity(0.10),
      thickness: 1,
      height: 28,
    );
  }
}

// ---------------- TRIVIA ----------------

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
  late AnimationController _pulseController;
  late AnimationController _resultController;
  late Animation<double> _resultScaleAnimation;
  late AnimationController _confettiController;
  final List<ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _resultController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _resultScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _resultController,
      curve: Curves.elasticOut,
    ));

    _confettiController = AnimationController(
      duration: const Duration(seconds: 9),  // Much longer for complete fall and disappearance
      vsync: this,
    )..addListener(() {
      setState(() {
        for (final particle in _particles) {
          particle.update();
        }
        // Remove particles that are completely off screen
        _particles.removeWhere((particle) => particle.isOffScreen(MediaQuery.of(context).size.height));
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _resultController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _questions = [
    {
      "q": "What percent of Deaf children have hearing parents?",
      "a": ["20%", "50%", "90%", "75%"],
      "correct": 2,
    },
    {
      "q": "Where was the first US Deaf school founded?",
      "a": ["New York City", "Hartford", "Washington D.C.", "Boston"],
      "correct": 1,
    },
    {
      "q": "Who signed the Gallaudet charter?",
      "a": [
        "Abraham Lincoln",
        "George Washington",
        "Thomas Jefferson",
        "Andrew Jackson",
      ],
      "correct": 0,
    },
    {
      "q": "ASL is most similar to sign language from:",
      "a": ["United Kingdom", "Mexico", "France", "Germany"],
      "correct": 0,
    },
    {
      "q": "The “Deaf President Now” protest happened in:",
      "a": ["1972", "1988", "2001", "1964"],
      "correct": 1,
    },
  ];

  void _answer(int index) {
    _correctAnswer = _questions[_currentIndex]['correct'];
    _selectedAnswer = index;
    
    // Haptic feedback for answer selection
    if (index == _correctAnswer) {
      HapticFeedback.mediumImpact();
      _score++;
    } else {
      HapticFeedback.heavyImpact();
    }

    setState(() {
      // Just update selected answer and correct answer, let animation controller handle the glow
    });

    _resultController.forward();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          if (_currentIndex < _questions.length - 1) {
            _currentIndex++;
            _selectedAnswer = null;
            _correctAnswer = null;
            _resultController.reset();
          } else {
            _showResult = true;
            // Create more natural confetti particles
            for (int i = 0; i < 50; i++) {
              _particles.add(ConfettiParticle());
            }
            _confettiController.forward(from: 0);
          }
        });
      }
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
      final percent = ((_score / _questions.length) * 100).toInt();
      return Stack(
        children: [
          // Main result content
          ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    color: const Color(0xFFC67C4E).withOpacity(0.4),
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "🎉 Quiz finished! 🎉",
                    style: TextStyle(
                      color: EducationScreen.cardGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                      CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
                    ),
                    child: Text(
                      "$percent%",
                      style: const TextStyle(
                        color: Color(0xFFC67C4E),
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.7, end: 1.0).animate(
                      CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
                    ),
                    child: ElevatedButton(
                      onPressed: _restart,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        backgroundColor: EducationScreen.cardGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                      ),
                      child: const Text("Restart quiz", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Natural confetti overlay - spans full result box width
          ..._particles.map((particle) {
            // Center confetti on screen center (result box is centered)
            final screenWidth = MediaQuery.of(context).size.width;
            final centerX = screenWidth / 2;
            
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
                    borderRadius: particle.shape == BoxShape.rectangle 
                      ? BorderRadius.circular(2) : null,
                  ),
                ),
              ),
            );
          }),
        ],
      );
    }    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EducationScreen.cardGreen,
            const Color(0xFF2C2C2C),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          BoxShadow(
            blurRadius: 10,
            color: const Color(0xFFC67C4E).withValues(alpha: 0.3),
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Question ${_currentIndex + 1} of ${_questions.length}",
                style: const TextStyle(
                  color: Color(0xFFC67C4E),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFC67C4E).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Score: $_score/${_questions.length}",
                  style: const TextStyle(
                    color: Color(0xFFC67C4E),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _questions[_currentIndex]['q'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(
            4,
            (index) => _TriviaOptionAnimated(
              text: _questions[_currentIndex]['a'][index],
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
  late AnimationController _tapController;
  late Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 200),  // Slightly longer for more fluid feel
      vsync: this,
    );

    _tapScale = Tween<double>(begin: 1.0, end: 0.92).animate(  // More pronounced scale
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOutCubic),  // More organic curve
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
    // Very gentle, aesthetic colors that blend with peach/cream theme
    const Color gentleGreen = Color(0xFF81C784);      // Soft, muted green
    const Color gentleRed = Color(0xFFE57373);        // Soft, muted coral
    const Color veryLightGreen = Color(0xFFF1F8F6);   // Almost white with hint of green
    const Color veryLightRed = Color(0xFFFEF5F5);     // Almost white with hint of red

    final backgroundColor = widget.isSelected && widget.showFeedback
        ? Colors.white.withValues(alpha: 0.08)  // Very subtle brightness increase
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
        child: _buildGlowingAnimatedOption(backgroundColor, borderColor, glowColor),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ScaleTransition(
        scale: _tapScale,
        child: _buildOptionContainer(backgroundColor, borderColor, glowColor),
      ),
    );
  }

  Widget _buildGlowingAnimatedOption(Color backgroundColor, Color borderColor, Color glowColor) {
    return AnimatedBuilder(
      animation: widget.resultAnimation,
      builder: (context, child) {
        // Gentle shake for wrong answer
        final shakeOffset = widget.isCorrect 
            ? 0.0 
            : sin(widget.resultAnimation.value * 8 * pi) * 4;

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              // Very subtle, gentle glow - single soft layer
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: _buildOptionContainer(backgroundColor, borderColor, glowColor),
          ),
        );
      },
    );
  }

  Widget _buildOptionContainer(Color backgroundColor, Color borderColor, Color glowColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: widget.isSelected ? 2.5 : 1.5,
        ),
      ),
      child: OutlinedButton(
        onPressed: widget.isSelected ? null : _handleTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          foregroundColor: Colors.white,
          side: BorderSide(color: borderColor, width: widget.isSelected ? 2.5 : 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: glowColor.withValues(alpha: 0.08),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.15),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isCorrect ? Icons.check_circle : Icons.cancel,
                    color: glowColor,
                    size: 32,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TriviaOption extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const _TriviaOption({required this.text, required this.onTap});

  @override
  State<_TriviaOption> createState() => _TriviaOptionState();
}

class _TriviaOptionState extends State<_TriviaOption> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _pulseController.forward().then((_) => _pulseController.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              onPressed: _handleTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.text,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------- POPULATION VISUAL ----------------

class InteractivePopulationVisual extends StatefulWidget {
  const InteractivePopulationVisual({super.key});

  @override
  State<InteractivePopulationVisual> createState() =>
      _InteractivePopulationVisualState();
}

class _InteractivePopulationVisualState
    extends State<InteractivePopulationVisual> with TickerProviderStateMixin {
  bool isRevealed = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ));
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
                color: const Color(0xFFFFF8F0),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
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
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: isRevealed
                      ? Column(
                          key: const ValueKey("ratio"),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                10,
                                (index) => AnimatedOpacity(
                                  opacity: 1.0,
                                  duration: Duration(milliseconds: 300 + index * 50),
                                  child: Icon(
                                    Icons.person,
                                    color: index == 0 ? const Color(0xFFC67C4E) : const Color(0xFFDDB5A0),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 600),
                              child: Text(
                                "Global Ratio",
                                style: TextStyle(
                                  color: Color(0xFFC67C4E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 800),
                              child: Text(
                                "430+ million people",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF3C3C3C),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            SizedBox(height: 6),
                            AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 1000),
                              child: Text(
                                "require rehabilitation for disabling hearing loss.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF8B6B5F)),
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Tap again to hide",
                              style: TextStyle(color: Color(0xFFDDB5A0)),
                            ),
                          ],
                        )
                      : Column(
                          key: const ValueKey("tap"),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                10,
                                (_) => const Icon(
                                  Icons.person,
                                  color: Color(0xFFDDB5A0),
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  "Tap to reveal the global ratio",
                                  style: TextStyle(
                                    color: Color(0xFF3C3C3C),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFFC67C4E),
                                  size: 20,
                                ),
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

// ---------------- HISTORY / ALLY / SUPPORT / BODY ----------------

class _HistoryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _HistoryItem({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EducationScreen.cardGreen,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            color: Colors.black26,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  desc,
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

class AllyTip extends StatelessWidget {
  final String text;
  const AllyTip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EducationScreen.cardGreen,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            color: Colors.black26,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportButton extends StatelessWidget {
  final String title;
  final String url;
  final VoidCallback onPressed;

  const _SupportButton({
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
          foregroundColor: EducationScreen.cardGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.open_in_new, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);

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
