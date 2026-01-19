import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  // Match the rest of your app
  static const Color mintGreen = Color.fromARGB(255, 122, 217, 168);
  static const Color cardGreen = Color.fromARGB(255, 60, 120, 88);
  static const Color deepGreen = Color.fromARGB(255, 5, 68, 18);

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mintGreen,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header card (same style as login card)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cardGreen,
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
          color: Color.fromARGB(255, 60, 120, 88),
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

class _TriviaWidgetState extends State<TriviaWidget> {
  int _currentIndex = 0;
  int _score = 0;
  bool _showResult = false;

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
      "correct": 2,
    },
    {
      "q": "The “Deaf President Now” protest happened in:",
      "a": ["1972", "1988", "2001", "1964"],
      "correct": 1,
    },
  ];

  void _answer(int index) {
    if (index == _questions[_currentIndex]['correct']) _score++;

    setState(() {
      if (_currentIndex < _questions.length - 1) {
        _currentIndex++;
      } else {
        _showResult = true;
      }
    });
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _showResult = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      final percent = ((_score / _questions.length) * 100).toInt();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              blurRadius: 14,
              color: Colors.black26,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              "Quiz finished",
              style: TextStyle(
                color: EducationScreen.cardGreen,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$percent%",
              style: const TextStyle(
                color: EducationScreen.cardGreen,
                fontSize: 44,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _restart,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: EducationScreen.cardGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Restart quiz"),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Question ${_currentIndex + 1} of ${_questions.length}",
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
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
            (index) => _TriviaOption(
              text: _questions[_currentIndex]['a'][index],
              onTap: () => _answer(index),
            ),
          ),
        ],
      ),
    );
  }
}

class _TriviaOption extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _TriviaOption({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton(
        onPressed: onTap,
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
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
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
    extends State<InteractivePopulationVisual> {
  bool isRevealed = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          isRevealed = !isRevealed;
        });
      },
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 85, 145, 110),
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
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: isRevealed
                ? Column(
                    key: const ValueKey("ratio"),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          10,
                          (index) => Icon(
                            Icons.person,
                            color: index == 0 ? Colors.white : Colors.white54,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Global Ratio",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "430+ million people",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "require rehabilitation for disabling hearing loss.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Tap again to hide",
                        style: TextStyle(color: Colors.white54),
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
                            color: Colors.white54,
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
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
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
