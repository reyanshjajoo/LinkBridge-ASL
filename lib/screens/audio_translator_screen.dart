import 'package:flutter/material.dart';

class AudioTranslatorScreen extends StatefulWidget {
  const AudioTranslatorScreen({super.key});

  @override
  State<AudioTranslatorScreen> createState() => _AudioTranslatorScreenState();
}

class _AudioTranslatorScreenState extends State<AudioTranslatorScreen> {
  bool isListening = false;
  String recognizedText = "";

  // TODO: integrate actual speech recognition (Speech-to-Text)
  void toggleListening() {
    setState(() {
      isListening = !isListening;

      if (isListening) {
        // Simulated text
        recognizedText = "Listening...";
      } else {
        recognizedText = "Tap the microphone to begin speaking.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 122, 217, 168),
      appBar: AppBar(title: const Text("Audio to Text")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            width: 700,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 60, 120, 88),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "Speech Input",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                // Microphone bubble
                GestureDetector(
                  onTap: toggleListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isListening ? 160 : 140,
                    width: isListening ? 160 : 140,
                    decoration: BoxDecoration(
                      color: isListening
                          ? const Color.fromARGB(255, 9, 173, 31)
                          : Colors.blueGrey[200],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isListening
                              ? const Color.fromARGB(255, 5, 68, 18)
                              : Colors.black12,
                          blurRadius: isListening ? 25 : 10,
                          spreadRadius: isListening ? 4 : 1,
                        ),
                      ],
                    ),
                    child: Icon(Icons.mic, size: 70, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 25),

                // Start/Stop Listening button
                ElevatedButton(
                  onPressed: toggleListening,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    isListening ? "Stop Listening" : "Start Listening",
                  ),
                ),

                const SizedBox(height: 20),

                // Recognized text output
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 60, 120, 88),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        recognizedText.isEmpty
                            ? "Tap the microphone to begin."
                            : recognizedText,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
