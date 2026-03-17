import 'dart:math';
import 'package:flutter/material.dart';
import 'assessment2_page.dart';
import 'data/progress_manager.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';


class Assessment1Page extends StatefulWidget {
  const Assessment1Page({super.key});

  @override
  State<Assessment1Page> createState() => _Assessment1PageState();
}

class _Assessment1PageState extends State<Assessment1Page> {
  String? letter;
  List<String>? options;
  String? correctImage;
  int _totalQuestions = 0;
  int _correctAnswers = 0;


  late FlutterTts flutterTts;
  late AudioPlayer audioPlayer;
  late ConfettiController confettiController;
  late DateTime _questionStartTime;


  final Set<String> disabled = {};

  bool revealMode = false;
  bool _instructionSpoken = false;

  String? wrongSelected;
  String? correctSelected;

  @override
  void initState() {
    super.initState();

    flutterTts = FlutterTts()
      ..setLanguage("en-GB")
      ..setSpeechRate(0.35)
      ..setPitch(1.0)
      ..setVolume(1.0);

    audioPlayer = AudioPlayer();
    confettiController =
        ConfettiController(duration: const Duration(seconds: 1));

    _loadLetter();
    _totalQuestions =
        ProgressManager.cycles[ProgressManager.currentCycle].length;
    _correctAnswers = 0;

  }

  void _loadLetter() {
    letter = ProgressManager.currentAssessment1Letter;
    correctImage = _correctForLetter(letter!);
    options = _buildOptions(letter!);

    disabled.clear();
    revealMode = false;
    wrongSelected = null;
    correctSelected = null;
    _instructionSpoken = false;
    _questionStartTime = DateTime.now(); // ✅ ADD


    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakInstruction();
    });
  }

  Future<void> _speakInstruction() async {
    if (_instructionSpoken) return;
    _instructionSpoken = true;
    await flutterTts.speak(
      "Select the correct image for ${letter!.toUpperCase()}",
    );
  }

  Future<void> _playCorrect() async {
    await audioPlayer.stop();
    await audioPlayer.play(AssetSource("audio/correct.mp3"));
    await Future.delayed(const Duration(milliseconds: 600));
    await flutterTts.speak("Correct");
  }

  Future<void> _playWrong() async {
    await audioPlayer.stop();
    await audioPlayer.play(AssetSource("audio/wrong.mp3"));
    await Future.delayed(const Duration(milliseconds: 600));
    await flutterTts.speak("Wrong");
  }

  void _showCorrectImagePopup() async {
    final spokenName = correctImage!.replaceAll("_", " ");

    await Future.delayed(const Duration(milliseconds: 2000));
    await flutterTts.stop();
    await flutterTts.speak("$spokenName is the correct answer");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Correct Answer",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 10),

              // ✅ ADDED LETTER (this is the ONLY addition)
              Text(
                letter!.toUpperCase(),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),

              const SizedBox(height: 12),

              Image.asset(
                "assets/images/${correctImage!}.png",
                width: 180,
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.pop(context);
    });
  }
  void _showResultDialog(double percentage) {
    final bool isFirstFail =
        percentage < 70 && !ProgressManager.assessment1RetakeUsed;

    final bool isPass = percentage >= 70;

    showDialog(
      context: context,
      barrierDismissible: false,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: SizedBox(
              width: 280, // 🔥 change this value (try 250–320)
              child: Container(


              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPass
                    ? [Color(0xFF32C13C), Color(0xFF38C63B)]
                    : [Color(0xFFFBBF24), Color(0xFFF97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ⭐ Decorative Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("⭐", style: TextStyle(fontSize: 28)),
                    Text("🌟", style: TextStyle(fontSize: 28)),
                  ],
                ),

                const SizedBox(height: 10),

                // 🎉 Big Emoji
                AnimatedScale(
                  scale: 1.1,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  child: Text(
                    isPass ? "🎉" : "💪",
                    style: const TextStyle(fontSize: 80),
                  ),
                ),

                const SizedBox(height: 15),

                // 🏆 Message
                Text(
                  isPass
                      ? "Amazing Work! You Completed The Assessment"
                      : isFirstFail
                      ? "Oops! Try Again!"
                      : "Nice Try!",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 15),

                // 🎯 Score Bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    "${percentage.toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: isPass ? Colors.green : Colors.deepOrange,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  "Correct: $_correctAnswers / $_totalQuestions",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 25),

                // 🎈 Main Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                  ),
                  onPressed: () {
                    Navigator.pop(context);

                    if (isFirstFail) {
                      // 🔁 Retry ONCE

                      ProgressManager.assessment1RetakeUsed = true;

                      // 🔥 RESET everything properly
                      ProgressManager.assessment1Index = 0;

                      _correctAnswers = 0;
                      _totalQuestions =
                          ProgressManager.cycles[ProgressManager.currentCycle].length;

                      // Reset cycle percentage counters if used
                      ProgressManager.assessmentCorrect = 0;
                      ProgressManager.assessmentTotal = 0;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Assessment1Page(),
                        ),
                      );

                    } else {
                      // ➡️ Move to Assessment 2

                      ProgressManager.assessment1RetakeUsed = false;
                      ProgressManager.assessment1Index = 0;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Assessment2Page(),
                        ),
                      );
                    }
                  },

                  child: Text(
                    isFirstFail ? "Retry 🔁" : "Next ➡️",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("🌟", style: TextStyle(fontSize: 28)),
                    Text("⭐", style: TextStyle(fontSize: 28)),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
        ),
    );

  }




  void _onTap(String img) {
    if (revealMode) return;
    if (correctImage == null || letter == null) return;

    final double timeTaken =
        DateTime.now().difference(_questionStartTime).inMilliseconds / 1000;

    if (img == correctImage) {
      // ✅ CORRECT
      _correctAnswers++;

      ProgressManager.recordAttempt(
        letter: letter!,
        isCorrect: true,
        timeTaken: timeTaken,
        mode: 'assessment1',
      );

      _playCorrect();
      confettiController.play();

      setState(() {
        revealMode = true;
        correctSelected = img;
      });

      Future.delayed(const Duration(seconds: 3), () {
        final finished = ProgressManager.nextAssessment1Letter();

        if (finished) {
          final percentage =
              (_correctAnswers / _totalQuestions) * 100;
          _showResultDialog(percentage);
        } else {
          _loadLetter();
          setState(() {});
        }
      });

    } else {
      // ❌ WRONG
      ProgressManager.recordAttempt(
        letter: letter!,
        isCorrect: false,
        timeTaken: timeTaken,
        mode: 'assessment1',
      );

      _playWrong();

      setState(() {
        revealMode = true;
        wrongSelected = img;
        disabled.add(img);
      });

      _showCorrectImagePopup();

      Future.delayed(const Duration(seconds: 7), () {
        final finished = ProgressManager.nextAssessment1Letter();

        if (finished) {
          final percentage =
              (_correctAnswers / _totalQuestions) * 100;
          _showResultDialog(percentage);
        } else {
          _loadLetter();
          setState(() {});
        }
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    if (letter == null || options == null || correctImage == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;

          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  isPortrait
                      ? "assets/images/assessment1_portrait.png"
                      : "assets/images/assessment1_landscape.png",
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [

                  // 🎉 CONFETTI
                  ConfettiWidget(
                    confettiController: confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    gravity: 0.4,
                    emissionFrequency: 0.05,
                    numberOfParticles: 30,
                  ),

                  // 📦 MAIN CONTENT
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 0),
                        const Text(
                          "Select the correct image for",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'BubbleFont',
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            letter!.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          alignment: WrapAlignment.center,
                          children: options!.map((img) {
                            final disabledImg = disabled.contains(img);

                            return GestureDetector(
                              onTap: (disabledImg || revealMode)
                                  ? null
                                  : () => _onTap(img),
                              child: Opacity(
                                opacity: disabledImg ? 0.35 : 1,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: wrongSelected == img
                                        ? Colors.red.withOpacity(0.75)
                                        : revealMode && img == correctImage
                                        ? Colors.green.withOpacity(0.30)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: revealMode && img == correctImage
                                          ? Colors.green
                                          : wrongSelected == img
                                          ? Colors.red
                                          : Colors.orangeAccent,
                                      width: 3,
                                    ),
                                  ),
                                  child: AnimatedScale(
                                    scale: revealMode && img == correctSelected
                                        ? 1.5                       // ✅ correct grows
                                        : revealMode && img == wrongSelected
                                        ? 0.85                  // ❌ wrong shrinks
                                        : 1.0,                  // normal
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOutBack,
                                    child: Image.asset(
                                      "assets/images/$img.png",
                                      width: isPortrait ? 90 : 110,
                                    ),
                                  ),

                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // 🔙 BACK BUTTON (ALWAYS ON TOP)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

  }

  List<String> _buildOptions(String letter) {
    final correct = _correctForLetter(letter);
    final wrong = _wrongImagesForLetter(letter)..shuffle(Random());
    return [correct, wrong[0], wrong[1]]..shuffle();
  }

  String _correctForLetter(String letter) => {
    "a": "arrow",
    "b": "ball",
    "c": "cat",
    "d": "dog",
    "e": "Eagle",
    "f": "fire",
    "g": "gorilla",
    "h": "hippopotamus",
    "i": "iron",
    "j": "jelly",
    "k": "key",
    "l": "leopard",
    "m": "mango",
    "n": "needle",
    "o": "otter",
    "p": "peacock",
    "q": "quartz",
    "r": "rhinoceros",
    "s": "shark",
    "t": "truck",
    "u": "umbrella",
    "v": "vacuumcleaner",
    "w": "watch",
    "x": "xray",
    "y": "yolk",
    "z": "zip",
  }[letter]!;

  List<String> _wrongImagesForLetter(String letter) => {
    "a": ["cat", "dog", "ball"],
    "b": ["Eagle", "cat", "axe"],
    "c": ["arrow", "donkey", "bag"],
    "d": ["anchor", "bat", "cat"],
    "e": ["ball", "dog", "cow"],
    "f": ["giraffe", "hyena", "ink"],
    "g": ["fan", "hippopotamus", "juice"],
    "h": ["ink", "gorilla", "fork"],
    "i": ["goat", "jelly", "horse"],
    "j": ["fan", "inhaler", "hyena"],
    "k": ["lion", "mango", "nail"],
    "l": ["kettle", "mulberry", "octopus"],
    "m": ["key", "octopus", "llama"],
    "n": ["lion", "otter", "kettle"],
    "o": ["mulberry", "needle", "key"],
    "p": ["quartz", "rabbit", "seahorse"],
    "q": ["parrot", "rat", "shark"],
    "r": ["peacock", "quilt", "truck"],
    "s": ["rhinoceros", "quiver", "tractor"],
    "t": ["starfish", "quilt", "pelican"],
    "u": ["yolk", "watch", "xmas_tree"],
    "v": ["umbrella", "xylophone", "wheel"],
    "w": ["unicycle", "vase", "yam"],
    "x": ["umbrella", "zip", "whistle"],
    "y": ["usb", "zero", "xray"],
    "z": ["yolk", "xmas_tree", "vacuumcleaner"],
  }[letter]!;

  @override
  void dispose() {
    confettiController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }
}
