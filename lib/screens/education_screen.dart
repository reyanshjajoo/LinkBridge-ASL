import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MaterialApp(home: EducationScreen(), debugShowCheckedModeBanner: false));
}

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  // Custom Color Palette as requested
  static const Color mintGreen = Color.fromARGB(255, 122, 217, 168);
  static const Color leafGreen = Color.fromARGB(255, 9, 173, 31);
  static const Color forestGreen = Color.fromARGB(255, 5, 68, 18);

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) throw Exception('Could not launch $url');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: forestGreen,
      body: CustomScrollView(
        slivers: [
          // 1. SMALLER HEADER SECTION
          SliverAppBar(
            expandedHeight: 180.0,
            pinned: true,
            backgroundColor: leafGreen,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                "DEAF AWARENESS & ASL",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [forestGreen, leafGreen],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. GLOBAL POPULATION & DEMOGRAPHICS
                  _buildSectionHeader("The Global Population"),
                  const InteractivePopulationVisual(),
                  const _BodyText(
                    "Globally, over 430 million people require rehabilitation to address 'disabling' hearing loss. This demographic is diverse, spanning every age and country. While often thought of as a condition of old age, millions of children and young adults are part of this community, facing unique challenges in education and social integration."
                  ),
                  
                  const Divider(color: mintGreen, thickness: 0.1, height: 40),

                  // 3. TRIVIA SECTION (Large Buttons)
                  _buildSectionHeader("Test Your Knowledge"),
                  const TriviaWidget(),

                  const Divider(color: mintGreen, thickness: 0.1, height: 40),

                  // 4. HISTORY OF DEAFNESS
                  _buildSectionHeader("History of Deafness"),
                  const _HistoryItem(
                    icon: Icons.gavel,
                    title: "Legal Hurdles",
                    desc: "In the 6th century, the Justinian Code often denied property and marriage rights to deaf individuals who couldn't speak, creating a long-standing legal stigma."
                  ),
                  const _HistoryItem(
                    icon: Icons.block,
                    title: "The Ban on Signs",
                    desc: "At the 1880 Milan Conference, educators voted to ban sign language in schools, forcing students to 'oralism' (lip-reading), which decimated Deaf culture for decades."
                  ),
                  const _HistoryItem(
                    icon: Icons.tsunami,
                    title: "Martha's Vineyard",
                    desc: "On this island in the 1700s, hereditary deafness was so common that nearly every hearing resident was bilingual in sign language, making it a perfectly accessible society."
                  ),

                  const Divider(color: mintGreen, thickness: 0.1, height: 40),

                  // 5. ALLY TIPS
                  _buildSectionHeader("How to be an Ally"),
                  const AllyTip(text: "Always get attention with a gentle tap or wave."),
                  const AllyTip(text: "Face the person directly so they can see your expressions."),
                  const AllyTip(text: "Never say 'nevermind' if they ask you to repeat yourself."),

                  const Divider(color: mintGreen, thickness: 0.1, height: 40),

                  // 6. SUPPORT LINKS
                  _buildSectionHeader("Ways to Support"),
                  _SupportButton(
                    title: "Hearing Health Foundation",
                    url: "https://hearinghealthfoundation.org",
                    onPressed: () => _launchURL("https://hearinghealthfoundation.org"),
                  ),
                  _SupportButton(
                    title: "Global Deaf Research",
                    url: "https://globaldeafresearch.org/",
                    onPressed: () => _launchURL("https://globaldeafresearch.org/"),
                  ),
                  _SupportButton(
                    title: "Global Deaf Research Institute",
                    url: "https://deaforganizationsfund.org/npo/global-deaf-research-institute/",
                    onPressed: () => _launchURL("https://deaforganizationsfund.org/npo/global-deaf-research-institute/"),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 30, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: mintGreen, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
    );
  }
}

// --- TRIVIA COMPONENT (Restored to Large Buttons) ---
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
    {"q": "What % of Deaf children have hearing parents?", "a": ["20%", "50%", "90%", "75%"], "correct": 2},
    {"q": "Where was the 1st US Deaf school founded?", "a": ["New York City", "Hartford", "Washington D.C.", "Boston"], "correct": 1},
    {"q": "Who signed the Gallaudet charter?", "a": ["Abraham Lincoln", "George Washington", "Thomas Jefferson", "Andrew Jackson"], "correct": 0},
    {"q": "ASL is most similar to sign from:", "a": ["United Kingdom", "Mexico", "France", "Germany"], "correct": 2},
    {"q": "The 'Deaf President Now' protest was in:", "a": ["1972", "1988", "2001", "1964"], "correct": 1}
  ];

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      return Container(
        padding: const EdgeInsets.all(30),
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            const Text("Quiz Finished", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("${(_score / 5 * 100).toInt()}%", style: const TextStyle(color: EducationScreen.mintGreen, fontSize: 48, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: EducationScreen.leafGreen),
              onPressed: () => setState(() { _currentIndex = 0; _score = 0; _showResult = false; }), 
              child: const Text("Restart Quiz", style: TextStyle(color: Colors.white))
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Question ${_currentIndex + 1} of 5", style: const TextStyle(color: EducationScreen.mintGreen, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(_questions[_currentIndex]['q'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 25),
        ...List.generate(4, (index) => _TriviaOption(
          text: _questions[_currentIndex]['a'][index],
          onTap: () {
            if (index == _questions[_currentIndex]['correct']) _score++;
            setState(() { if (_currentIndex < 4) { _currentIndex++; } else { _showResult = true; } });
          },
        )),
      ],
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

class _TriviaOptionState extends State<_TriviaOption> {
  bool isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 15), // Spaced out
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20), // Large button feel
          width: double.infinity,
          decoration: BoxDecoration(
            color: isHovered ? EducationScreen.mintGreen.withOpacity(0.3) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isHovered ? EducationScreen.mintGreen : Colors.white12, width: 1.5),
          ),
          child: Text(widget.text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}

// --- REMAINING UI COMPONENTS ---

class InteractivePopulationVisual extends StatefulWidget {
  const InteractivePopulationVisual({super.key});
  @override
  State<InteractivePopulationVisual> createState() => _InteractivePopulationVisualState();
}

class _InteractivePopulationVisualState extends State<InteractivePopulationVisual> {
  bool isRevealed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => isRevealed = !isRevealed),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Wrap(
              spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
              children: List.generate(20, (index) => Icon(Icons.person, color: (isRevealed && index == 0) ? EducationScreen.mintGreen : Colors.white24, size: 28)),
            ),
            const SizedBox(height: 15),
            Text(isRevealed ? "1 in 20 people have disabling hearing loss." : "Tap to reveal the global ratio", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _HistoryItem({required this.icon, required this.title, required this.desc});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: EducationScreen.mintGreen, size: 28),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
          ])),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        const Icon(Icons.auto_awesome, color: EducationScreen.mintGreen, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15))),
      ]),
    );
  }
}

class _SupportButton extends StatelessWidget {
  final String title;
  final String url;
  final VoidCallback onPressed;
  const _SupportButton({required this.title, required this.url, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: EducationScreen.leafGreen, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        onPressed: onPressed,
        child: Column(children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(url, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ]),
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
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6)),
    );
  }
}