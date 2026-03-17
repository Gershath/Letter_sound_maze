import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';
import 'data/progress_manager.dart';
import 'performance_analysis_page.dart';





class Bubble {
  double x;
  double y;
  double radius;
  double speed;
  double opacity;
  final Color color;

  Bubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.color,
  });
}
class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;

  BubblePainter(this.bubbles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final paint = Paint()
        ..color = b.color.withOpacity(b.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(Offset(b.x, b.y), b.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
class BubbleBackground extends StatefulWidget {
  const BubbleBackground({super.key});

  @override
  State<BubbleBackground> createState() => _BubbleBackgroundState();
}

class _BubbleBackgroundState extends State<BubbleBackground>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late List<Bubble> bubbles;
  final rand = Random();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..addListener(_updateBubbles)
      ..repeat();

    bubbles = List.generate(16, (_) {
      return Bubble(
        x: rand.nextDouble() * 800,
        y: rand.nextDouble() * 1200,
        radius: 22 + rand.nextDouble() * 38,
        speed: 0.6 + rand.nextDouble() * 0.8,
        opacity: 0.4,
        color: const Color(0xFF9BDCF6),
      );
    });
  }

  void _updateBubbles() {
    final size = MediaQuery.of(context).size;

    for (final b in bubbles) {
      b.y -= b.speed;
      if (b.y + b.radius < 0) {
        b.y = size.height + b.radius;
        b.x = rand.nextDouble() * size.width;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return CustomPaint(
            painter: BubblePainter(bubbles),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}





class GamingPage extends StatefulWidget {
  const GamingPage({super.key});

  @override
  State<GamingPage> createState() => GamingPageState();
}

class GamingPageState extends State<GamingPage>
    with SingleTickerProviderStateMixin {

  late String currentLetter;
  late List<String> correctImages;
  late List<String> allImages;
  late AudioPlayer bgmPlayer; // 🎵 background music
  late AudioPlayer sfxPlayer; //// 🔊 correct / wrong sounds
  late FlutterTts flutterTts;
  late ConfettiController _confettiController;
  bool allCorrectFound = false;
  late DateTime _letterStartTime;




  final Set<String> selectedCorrect = {};
  final Set<String> tappedWrongImages = {};
  final AudioContext gameAudioContext = AudioContext(
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none, // 🔥 THIS LINE
    ),
  );


  late List<String> gameLetters; // 20 unique letters
  int currentIndex = 0;

  String? animatingWrong;

  int totalTaps = 0;
  bool wrongTapped = false;
  bool revealCorrect = false;




  late AnimationController _controller;

  /// 🔤 Alphabet → Images mapping
  final Map<String, List<String>> alphabetImages = {
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
  void initState() {
    super.initState();
    flutterTts = FlutterTts();

    flutterTts.setLanguage("en-GB");
    flutterTts.setSpeechRate(0.45); // slower for kids
    flutterTts.setPitch(1.1);
    flutterTts.setVolume(1.0);


    bgmPlayer = AudioPlayer();
    sfxPlayer = AudioPlayer();

    bgmPlayer.setAudioContext(gameAudioContext);
    sfxPlayer.setAudioContext(gameAudioContext);

    _playBackgroundMusic();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );


    _initGameLetters();
    _loadCurrentLetter();


  }
  bool _bubblesInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_bubblesInitialized) {
      _bubblesInitialized = true;
    }
  }



  void _initGameLetters() {
    final rand = Random();

    gameLetters = alphabetImages.keys.toList();
    gameLetters.shuffle(rand);

    gameLetters = gameLetters.take(20).toList(); // ✅ ONLY 20
    currentIndex = 0;
  }



  @override
  void dispose() {
    bgmPlayer.dispose();
    sfxPlayer.dispose();
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  List<String> buildSpacedImageList(
      List<String> correct,
      List<String> wrong,
      ) {
    final rand = Random();
    final List<String> result = [];
    int wrongIndex = 0;

    for (int i = 0; i < correct.length; i++) {
      // ✅ REQUIRED minimum gap (2 wrong images)
      for (int j = 0; j < 2 && wrongIndex < wrong.length; j++) {
        result.add(wrong[wrongIndex++]);
      }

      // 🎲 OPTIONAL extra gap (random)
      int extraGap = rand.nextInt(3); // 0–2 extra wrong images
      for (int j = 0;
      j < extraGap && wrongIndex < wrong.length;
      j++) {
        result.add(wrong[wrongIndex++]);
      }

      // ➕ add correct image
      result.add(correct[i]);
    }

    // ➕ add remaining wrong images
    while (wrongIndex < wrong.length) {
      result.add(wrong[wrongIndex++]);
    }

    return result;
  }



  /// 🎯 START NEW ROUND
  void _loadCurrentLetter() {
    if (currentIndex >= gameLetters.length) {
      _endGame();
      return;
    }

    currentLetter = gameLetters[currentIndex];

    correctImages = List.from(alphabetImages[currentLetter]!);

    List<String> wrongPool = [];
    alphabetImages.forEach((k, v) {
      if (k != currentLetter) wrongPool.addAll(v);
    });

    wrongPool.shuffle();
    final wrongImages = wrongPool.take(12).toList();

    wrongImages.shuffle();
    correctImages.shuffle(); // optional, keeps variety

    allImages = buildSpacedImageList(correctImages, wrongImages);

    totalTaps = 0;
    wrongTapped = false;
    revealCorrect = false;
    selectedCorrect.clear();
    tappedWrongImages.clear(); // 🔥 RESET wrong clicks for new letter
    allCorrectFound = false;
    _letterStartTime = DateTime.now();



    setState(() {});
    Future.delayed(const Duration(milliseconds: 400), () {
      _speakInstruction();
    });
  }

  void _endGame() {
    ProgressManager.finishGame();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: SizedBox(
            width: 270, // 🔥 compact width
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF60A5FA),
                    Color(0xFF9333EA),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // 🎉 Big Emoji
                  const Text(
                    "🎉",
                    style: TextStyle(fontSize: 70),
                  ),

                  const SizedBox(height: 10),

                  // 🏆 Title
                  const Text(
                    "Great Job!",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  // 📘 Message
                  const Text(
                    "You completed the game",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // 🌟 Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 35, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 6,
                    ),
                    onPressed: () {
                      Navigator.pop(context);

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const PerformanceAnalysisPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "View Performance ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ⭐ Decorative Row
                  const Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text("⭐", style: TextStyle(fontSize: 24)),
                      Text("🌟", style: TextStyle(fontSize: 24)),
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




  /// 🖱 IMAGE TAP HANDLER
  void _onImageTap(String img) {
    if (totalTaps >= 3) return;
    final double timeTaken =
        DateTime.now().difference(_letterStartTime).inMilliseconds / 1000;


    if (selectedCorrect.contains(img) ||
        tappedWrongImages.contains(img) ||
        animatingWrong == img) return;

    totalTaps++;

    if (correctImages.contains(img)) {
      ProgressManager.recordAttempt(
        letter: currentLetter,
        isCorrect: true,
        timeTaken: timeTaken,
        mode: 'game',
      );

      selectedCorrect.add(img);
      _playSound('correct_game.mp3');

      // 🎉 CHECK IF ALL CORRECT IMAGES FOUND
      if (selectedCorrect.length == correctImages.length && !allCorrectFound) {
        allCorrectFound = true;

        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;

          _confettiController.play();
          _playSound('all_correct.mp3');

          setState(() {});
        });
      }


    }
    else {
      ProgressManager.recordAttempt(
        letter: currentLetter,
        isCorrect: false,
        timeTaken: timeTaken,
        mode: 'game',
      );

      tappedWrongImages.add(img); // ✅ ONLY store clicked wrong
      wrongTapped = true;
      animatingWrong = img;
      _playSound('wrong-game.mp3');

      Future.delayed(const Duration(milliseconds: 550), () {
        if (!mounted) return;

        setState(() {
          animatingWrong = null;

          // 🔥 REMOVE ONLY THE CLICKED WRONG IMAGE
          allImages.remove(img);
        });
      });
    }


    if (totalTaps == 3) {
      final int revealDelayMs = wrongTapped ? 1200 : 800;

      Future.delayed(Duration(milliseconds: revealDelayMs), () {
        if (!mounted) return;

        revealCorrect = true;
        setState(() {});

        final int nextDelay = wrongTapped ? 6 : 4;
        Future.delayed(Duration(seconds: nextDelay), () {
          currentIndex++;
          _loadCurrentLetter();
        });
      });
    }


    setState(() {});
  }


  void _playSound(String file) async {
    await sfxPlayer.stop();
    await sfxPlayer.play(
      AssetSource('audio/$file'),
      volume: 1.0,
    );
  }


  void _playBackgroundMusic() async {
    await bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await bgmPlayer.setVolume(0.25); // background level
    await bgmPlayer.play(
      AssetSource('audio/background_music.mp3'),
    );
  }

  Future<void> _speakInstruction() async {
    await flutterTts.stop(); // avoid overlap
    await flutterTts.speak(
      "Find the correct images for ${currentLetter.toUpperCase()}",
    );
  }

  Future<void> _speakLetter() async {
    await flutterTts.stop(); // prevent overlap
    await flutterTts.speak(
      "${currentLetter.toUpperCase()}...",
    );
  }


  Widget _buildResponsiveBackground(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Positioned.fill(
      child: Image.asset(
        isPortrait
            ? 'assets/images/bg_game_portrait.png'
            : 'assets/images/bg_game_landscape.png',
        fit: BoxFit.cover, // fills screen without distortion
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.35;
    final double pulse =
        0.5 + 0.5 * sin(_controller.value * 2 * pi);
    final double imageSize = 100;
    // ✅ Images that should be visible in orbit
    final List<String> visibleImages = allImages.where((img) {
      // Before 3 taps → show everything
      if (!revealCorrect) return true;

      // After 3 taps → show:
      // 1. all correct images
      // 2. wrong images that were CLICKED
      return correctImages.contains(img) ||
          selectedCorrect.contains(img);

    }).toList();




    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 🌄 BACKGROUND IMAGE
          _buildResponsiveBackground(context),
          // 🫧 BUBBLE EFFECT BACKGROUND
          const Positioned.fill(
            child: IgnorePointer(
              child: BubbleBackground(),
            ),
          ),


          /// 🔤 CENTER ALPHABET
          Center(
            child: GestureDetector(
              onTap: _speakLetter,
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.lightBlueAccent,
                child: Text(
                  currentLetter.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 90,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),


          /// 🖼 ORBITING IMAGES
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return Stack(
                children: List.generate(visibleImages.length, (i) {
                  final angle = (2 * pi / visibleImages.length) * i
                      + (_controller.value * 2 * pi);

                  final x = center.dx + radius * cos(angle) - imageSize / 2;
                  final y = center.dy + radius * sin(angle) - imageSize / 2;


                  final img = visibleImages[i];

                  Color borderColor = Colors.transparent;
                  if (selectedCorrect.contains(img)) {
                    borderColor = Colors.green;
                  } else if (tappedWrongImages.contains(img)) {
                    borderColor = Colors.red;
                  }


                  return Positioned(
                    left: x,
                    top: y,
                    child: GestureDetector(
                      onTap: () => _onImageTap(img),
                      child: AnimatedScale(
                        scale: animatingWrong == img
                            ? 0.7
                            : (revealCorrect && correctImages.contains(img)
                            ? 1.1 + 0.1 * pulse
                            : 1.0),

                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInBack,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 🖼 IMAGE
                            AnimatedOpacity(
                              opacity: animatingWrong == img ? 0.4 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                width: imageSize,
                                height: imageSize,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor, width: 6),
                                  boxShadow: revealCorrect && correctImages.contains(img)
                                      ? [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3 + 0.4 * pulse),
                                      blurRadius: 12 + 18 * pulse,
                                      spreadRadius: 3 + 6 * pulse,
                                    )
                                  ]
                                      : [],
                                  image: DecorationImage(
                                    image: AssetImage("assets/images/$img.png"),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),

                            // ❌ RED CROSS (wrong selection)
                            if (tappedWrongImages.contains(img))

                              const Icon(
                                Icons.close,
                                size: 60,
                                color: Colors.red,
                              ),
                          ],

                        ),
                      ),
                    ),

                  );

                }),
              );
            },
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                emissionFrequency: 0.05,
                numberOfParticles: 25,
                gravity: 0.2,
              ),
            ),
          ),

        ],
      ),
    );
  }
}
