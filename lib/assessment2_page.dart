import 'dart:math';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'data/progress_manager.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';



class Assessment2Page extends StatefulWidget {
  const Assessment2Page({super.key});

  @override
  State<Assessment2Page> createState() => _Assessment2PageState();
}

class _Assessment2PageState extends State<Assessment2Page> {
  late String letter;
  late List<String> correctImages;
  late List<String> allOptions;

  late FlutterTts flutterTts;
  late AudioPlayer audioPlayer;
  late ConfettiController _confettiController;
  late DateTime _questionStartTime;



  final Set<String> disabledOptions = {};
  final Set<String> selectedCorrect = {};
  final Set<String> wrongSelected = {};
  int _totalLetters = 0;
  int _correctLetters = 0;




  static const int maxChances = 3;
  static const int requiredCorrectSelections = 3;

  int usedChances = 0;
  bool revealMode = false;




  @override
  void initState() {
    super.initState();

    flutterTts = FlutterTts()
      ..setLanguage("en-GB")
      ..setSpeechRate(0.45)
      ..setPitch(1.0)
      ..setVolume(1.0);

    audioPlayer = AudioPlayer();

    _loadCurrentLetter();
    _totalLetters =
        ProgressManager.cycles[ProgressManager.currentCycle].length;
    _correctLetters = 0;

    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 800));

  }

  void _loadCurrentLetter() {
    final cycleLetters = ProgressManager.cycles[ProgressManager.currentCycle];

    if (ProgressManager.assessment2Index >= cycleLetters.length) {
      // Safety guard — should never happen, but prevents crash
      ProgressManager.assessment2Index = 0;
    }

    letter = cycleLetters[ProgressManager.assessment2Index];

    correctImages = _correctImagesForLetter(letter);
    allOptions = _generateOptions(letter);

    disabledOptions.clear();
    selectedCorrect.clear();
    wrongSelected.clear();
    usedChances = 0;
    revealMode = false;

    _questionStartTime = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakInstruction();
    });
  }


  Future<void> _speakInstruction() async {
    await flutterTts.stop();
    await flutterTts.speak(
      "Find all the images that start with ${letter.toUpperCase()}",
    );
  }

  // 🔊 CORRECT FEEDBACK
  Future<void> _playCorrectFeedback() async {
    await audioPlayer.stop();
    await audioPlayer.play(AssetSource("audio/correct.mp3"));
    await Future.delayed(const Duration(milliseconds: 600));
    await flutterTts.speak("Correct");
  }

  // 🔊 WRONG FEEDBACK
  Future<void> _playWrongFeedback() async {
    await audioPlayer.stop();
    await audioPlayer.play(AssetSource("audio/wrong.mp3"));
    await Future.delayed(const Duration(milliseconds: 600));
    await flutterTts.speak("Wrong");
  }
  Future<void> _showCorrectPopup({required List<String> images}) async {
    // Show popup overlay first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✨ Text at the top
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  "The correct images of",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ✅ LETTER CARD
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    letter.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 🖼️ Images in a row/wrap (CARD ADDED HERE)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: images.map((img) {
                  return Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 160,
                      height: 160,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 4),
                        color: Colors.white,
                      ),
                      child: Image.asset(
                        "assets/images/$img.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );

    // 🔹 Wait for dialog to render
    await Future.delayed(const Duration(milliseconds: 500));

    // 🔊 Speak the correct images safely
    String imagesText = images.map((e) => e.replaceAll('_', ' ')).join(", ");
    await flutterTts.stop();
    await flutterTts.speak("The correct images are: $imagesText");

    // 🔹 Auto close popup
    await Future.delayed(const Duration(seconds: 5));
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        body: OrientationBuilder(
          builder: (context, orientation) {
            final isPortrait = orientation == Orientation.portrait;

            return Stack(
              children: [
                // 🌄 BACKGROUND + MAIN UI
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        isPortrait
                            ? "assets/images/assessment2_portrait.png"
                            : "assets/images/assessment2_landscape.png",
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // 🌈 APP BAR STYLE HEADER
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 40),
                            ],
                          ),
                        ),

                        // 🎯 MAIN CONTENT CARD
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter, // 👈 FORCE TOP
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(16),
                              width: isPortrait
                                  ? double.infinity
                                  : MediaQuery.of(context).size.width * 0.7,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.0),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // 🗣️ INSTRUCTION
                                  Transform.translate(
                                    offset: const Offset(0, -55), // 👈 move text UP (negative = up)
                                    child: Text(
                                      "Find all images that start with",
                                      style: TextStyle(
                                        fontSize: isPortrait ? 26 : 26,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'BubbleFont',
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ),


                                  const SizedBox(height: 0),

                                  // 🔤 LETTER BUBBLE
                                  // 🔤 LETTER BUBBLE — MOVE UP
                                  Transform.translate(
                                    offset: const Offset(0, -35), // 👈 adjust value if needed
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        letter.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 38,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),


                                  const SizedBox(height: 1),

                                  // 🖼️ GRID TAKES REST
                                  Expanded(
                                    child: GridView.builder(
                                      itemCount: allOptions.length,
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isPortrait ? 3 : 4,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                      ),
                                      itemBuilder: (context, index) {
                                        final img = allOptions[index];
                                        final isDisabled = disabledOptions.contains(img);

                                        return GestureDetector(
                                          onTap: isDisabled || revealMode
                                              ? null
                                              : () => _onOptionTap(img),
                                          child: AnimatedScale(
                                            scale: selectedCorrect.contains(img)
                                                ? 1.05
                                                : wrongSelected.contains(img)
                                                ? 0.90
                                                : 0.95,
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeOutBack,
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 300),
                                              decoration: BoxDecoration(
                                                color: wrongSelected.contains(img)
                                                    ? Colors.red.withOpacity(0.75)
                                                    : Colors.white,
                                                borderRadius: BorderRadius.circular(18),
                                                border: selectedCorrect.contains(img)
                                                    ? Border.all(color: Colors.green, width: 4)
                                                    : wrongSelected.contains(img)
                                                    ? Border.all(color: Colors.red, width: 4)
                                                    : Border.all(
                                                  color: Colors.orangeAccent,
                                                  width: 3,
                                                ),
                                              ),
                                              child: Opacity(
                                                opacity: isDisabled ? 0.4 : 1,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8),
                                                  child: Stack(
                                                    children: [
                                                      // 🖼️ IMAGE
                                                      Image.asset(
                                                        "assets/images/$img.png",
                                                        fit: BoxFit.contain,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                      ),

                                                      // ✅ GREEN TICK (CORRECT)
                                                      if (selectedCorrect.contains(img))
                                                        Positioned(
                                                          top: 6,
                                                          right: 6,
                                                          child: Container(
                                                            decoration: const BoxDecoration(
                                                              color: Colors.green,
                                                              shape: BoxShape.circle,
                                                            ),
                                                            padding: const EdgeInsets.all(6),
                                                            child: const Icon(
                                                              Icons.check,
                                                              color: Colors.white,
                                                              size: 20,
                                                            ),
                                                          ),
                                                        ),

                                                      // ❌ RED CROSS (WRONG)
                                                      if (wrongSelected.contains(img))
                                                        Positioned(
                                                          top: 6,
                                                          right: 6,
                                                          child: Container(
                                                            decoration: const BoxDecoration(
                                                              color: Colors.red,
                                                              shape: BoxShape.circle,
                                                            ),
                                                            padding: const EdgeInsets.all(6),
                                                            child: const Icon(
                                                              Icons.close,
                                                              color: Colors.white,
                                                              size: 20,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                            ),
                                          ),

                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),

                // 🎉 CONFETTI OVERLAY (ON TOP OF EVERYTHING)
                Align(
                  alignment: Alignment.center,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    emissionFrequency: 0.25,
                    numberOfParticles: 30,
                    minBlastForce: 15,
                    maxBlastForce: 30,
                    gravity: 0.5,
                    shouldLoop: false,
                    colors: const [
                      Colors.red,
                      Colors.blue,
                      Colors.white,
                      Colors.yellow,
                    ],
                  ),
                ),



              ],
            );

          },
        ),
      ),
    );
  }


  /// 🧠 OPTION TAP HANDLER
  void _onOptionTap(String img) {
    if (revealMode) return;
    final double timeTaken =
        DateTime.now().difference(_questionStartTime).inMilliseconds / 1000;


    usedChances++;

    if (correctImages.contains(img)) {
      ProgressManager.recordAttempt(
        letter: letter,
        isCorrect: true,
        timeTaken: timeTaken,
        mode: 'assessment2',
      );

      selectedCorrect.add(img);
      _confettiController.play(); // 🎉 CONFETTI
      _playCorrectFeedback();


      if (selectedCorrect.length == requiredCorrectSelections) {
        _correctLetters++;

        ProgressManager.completedLetters.add(letter.toUpperCase());

        setState(() => revealMode = true);

        Future.delayed(const Duration(seconds: 0), () {
          _revealCorrectAndProceed(); // 🔥 let ONE function handle advancing
        });

        return;
      }
    } else {
      ProgressManager.recordAttempt(
        letter: letter,
        isCorrect: false,
        timeTaken: timeTaken,
        mode: 'assessment2',
      );

      disabledOptions.add(img);
      wrongSelected.add(img);
      _playWrongFeedback();
    }

    if (usedChances >= maxChances &&
        selectedCorrect.length < requiredCorrectSelections) {

      setState(() => revealMode = true); // prevent further taps

      // ⏳ ADD DELAY BEFORE POPUP
      Future.delayed(const Duration(seconds: 2), () {
        _showCorrectPopup(images: correctImages).then((_) {
          _revealCorrectAndProceed();
        });
      });

    }
    else {
      setState(() {});
    }


  }

  void _revealCorrectAndProceed() {
    setState(() {
      revealMode = true;
      for (final img in allOptions) {
        if (!correctImages.contains(img)) {
          disabledOptions.add(img);
        } else {
          selectedCorrect.add(img);
        }
      }
    });

    Future.delayed(const Duration(seconds: 4), () {
      final finished = ProgressManager.nextAssessment2Letter();

      if (finished) {
        final percentage =
            (_correctLetters / _totalLetters) * 100;

        _showAssessment2Result(percentage);

      } else {
        setState(_loadCurrentLetter);
      }

    });
  }
  void _showAssessment2Result(double percentage) {
    final bool isPass = percentage >= 70;
    final bool isFirstFail =
        percentage < 70 && !ProgressManager.assessment2RetakeUsed;

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
                    ? [Color(0xFF4ADE80), Color(0xFF0BDC17)]
                    : [Color(0xFFFACC15), Color(0xFFF97316)],
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

                // 🎉 Big Emoji
                Text(
                  isPass ? "🏆" : "💪",
                  style: const TextStyle(fontSize: 80),
                ),

                const SizedBox(height: 15),

                Text(
                  isPass
                      ? "Amazing Work! You Completed The Assessment"
                      : isFirstFail
                      ? "Let's Try Again!"
                      : "Good Effort!",
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
                  "Correct: $_correctLetters / ${ProgressManager.cycles[ProgressManager.currentCycle].length}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 25),

                // 🎈 Button
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
                      // 🔁 Allow one retry
                      ProgressManager.assessment2RetakeUsed = true;
                      ProgressManager.assessment2Index = 0;
                      _correctLetters = 0;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Assessment2Page(),
                        ),
                      );
                    } else {
                      // ➡️ Always Next after pass or reattempt
                      ProgressManager.assessment2RetakeUsed = false;
                      ProgressManager.assessment2Index = 0;

                      ProgressManager.moveToNextCycle();

                      if (ProgressManager.isAllCyclesCompleted()) {
                        ProgressManager.finishGame();
                      }

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HomePage(),
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

                // 🌈 Decorative icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("⭐", style: TextStyle(fontSize: 28)),
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




  List<String> _generateOptions(String letter) {
    final random = Random();
    final cycleLetters =
    ProgressManager.cycles[ProgressManager.currentCycle];

    final wrongPool = cycleLetters
        .where((l) => l != letter)
        .expand((l) => _correctImagesMap[l]!)
        .toList()
      ..shuffle(random);

    List<String> options;

    do {
      options = [...correctImages, ...wrongPool.take(5)]..shuffle(random);
    } while (_hasConsecutiveCorrect(options));

    return options;
  }
  bool _hasConsecutiveCorrect(List<String> options) {
    for (int i = 0; i < options.length - 1; i++) {
      if (correctImages.contains(options[i]) &&
          correctImages.contains(options[i + 1])) {
        return true;
      }
    }
    return false;
  }



  List<String> _correctImagesForLetter(String letter) =>
      _correctImagesMap[letter]!;

  static const Map<String, List<String>> _correctImagesMap = {
    "a": ["anchor", "arrow", "axe"],
    "b": ["ball", "bat", "bag"],
    "c": ["cat", "camel", "cow"],
    "d": ["deer", "dog", "donkey"],
    "e": ["Eagle", "egret", "emu"],
    "f": ["fan", "fire", "fork"],
    "g": ["giraffe", "goat", "gorilla"],
    "h": ["hippopotamus", "horse", "hyena"],
    "i": ["inhaler", "ink", "iron"],
    "j": ["jam", "jelly", "juice"],
    "k": ["kettle", "key", "kite"],
    "l": ["leopard", "lion", "llama"],
    "m": ["mango", "mulberry", "muskmelon"],
    "n": ["nail", "needle", "net"],
    "o": ["octopus", "otter", "oyster"],
    "p": ["parrot", "peacock", "pelican"],
    "q": ["quartz", "quilt", "quiver"],
    "r": ["rabbit", "rat", "rhinoceros"],
    "s": ["seahorse", "shark", "starfish"],
    "t": ["tractor", "train", "truck"],
    "u": ["umbrella", "unicycle", "usb"],
    "v": ["vacuumcleaner", "van", "vase"],
    "w": ["watch", "wheel", "whistle"],
    "x": ["xmas_tree", "xray", "xylophone"],
    "y": ["yam", "yoghurt", "yolk"],
    "z": ["zero", "zigzag", "zip"],
  };

  @override
  void dispose() {
    _confettiController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }
}
