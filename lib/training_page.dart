import 'package:flutter/material.dart';
import 'assessment1_page.dart';
import 'data/progress_manager.dart';
import 'package:flutter_tts/flutter_tts.dart';


class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage>
    with SingleTickerProviderStateMixin {
  late String letter;
  late List<String> images;
  late FlutterTts flutterTts;
  int activeImageIndex = 0;
  late AnimationController blinkController;
  late Animation<double> blinkAnimation;

  final Set<String> practicedImages = {};








  static const int minDragsToComplete = 3;
  static const int maxAllowedDrags = 5;

  final Map<String, int> dragCount = {};
  bool trainingCompleted = false;

  Future<void> speak(String text) async {
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  @override
  void initState() {
    super.initState();

    flutterTts = FlutterTts();
    _initTts();

    letter = ProgressManager.currentTrainingLetter;
    images = _imagesForLetter(letter);

    dragCount.clear();
    for (var img in images) {
      dragCount[img] = 0;
    }
    blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    blinkAnimation = Tween<double>(begin: 1.0, end: 0.4).animate(blinkController);

  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-GB");
    await flutterTts.setSpeechRate(0.35);
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);
  }

  Future<void> _exitTraining() async {
    await flutterTts.stop();
    if (dragCount.values.any((v) => v > 0)) {
      ProgressManager.completedTrainingLetters.add(letter.toUpperCase());
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _exitTraining();
        return false;
      },
      child: Scaffold(

        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                MediaQuery.of(context).orientation == Orientation.portrait
                    ? "assets/images/training_bg_portrait.png"
                    : "assets/images/training_bg_landscape.png",
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Container(
                      color: Colors.white.withOpacity(0.15),
                      child: Column(
                        children: [
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
                          const SizedBox(height: 20),

                          /// IMAGES (NOW AT TOP)
                          Padding(
                            padding: const EdgeInsets.only(top: 90),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 16,
                              runSpacing: 16,
                              children: images.map(buildDraggable).toList(),
                            ),
                          ),

                          const SizedBox(height: 40),

                          /// DROP TARGET (ALPHABET NOW BELOW)
                          DragTarget<String>(
                            onAccept: (img) async {
                              final count = dragCount[img]!;

                              if (count >= maxAllowedDrags) return;

                              await speak(
                                "${letter.toUpperCase()} is for ${img.replaceAll("_", " ")}",
                              );

                              setState(() {
                                dragCount[img] = count + 1;

                                // -------- TRAINING SEQUENCE --------
                                if (!trainingCompleted &&
                                    dragCount[img]! >= minDragsToComplete &&
                                    activeImageIndex < images.length - 1) {
                                  activeImageIndex++;
                                }

                                // -------- TRAINING COMPLETE --------
                                final earlyComplete =
                                    activeImageIndex == images.length - 1 &&
                                        dragCount[images.last]! >= minDragsToComplete;

                                trainingCompleted =
                                    dragCount.values.every((v) => v >= minDragsToComplete) ||
                                        earlyComplete;

                                if (trainingCompleted) {
                                  activeImageIndex = -1; // enable all
                                }
                              });
                            },



                            builder: (_, __, ___) => CircleAvatar(
                              radius: 85,
                              backgroundColor: Colors.blueAccent.shade100,
                              child: Text(
                                letter.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 90,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),



                          const SizedBox(height: 16),

                          const Text(
                            "Drag Each Picture Atleast 3 Times To The Alphabet",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),

                          const Spacer(),

                          if (trainingCompleted)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade50,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: onNextPressed,
                                child: const Text(
                                  "Next ➡️",
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> onNextPressed() async{
    await flutterTts.stop();
    final finishedTraining = ProgressManager.nextTrainingLetter();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
        finishedTraining ? const Assessment1Page() : const TrainingPage(),
      ),
    );
  }

  Widget buildDraggable(String name) {
    final count = dragCount[name]!; // ✅ DEFINE FIRST

    final index = images.indexOf(name);

    final isActive = !trainingCompleted && index == activeImageIndex;
    final locked =
        (!trainingCompleted && index != activeImageIndex) ||
            count >= maxAllowedDrags;



    // ✅ PER-IMAGE PRACTICE BLINK LOGIC (SAFE LOCATION)
    final shouldBlinkInPractice =
        trainingCompleted && count < maxAllowedDrags;

    final displayName = name
        .replaceAll("_", " ")
        .split(" ")
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(" ");

    return Column(
      children: [
        IgnorePointer(
          ignoring: locked,
          child: AnimatedBuilder(
            animation: blinkAnimation,
            builder: (_, child) {
              return Opacity(
                opacity: shouldBlinkInPractice
                    ? blinkAnimation.value              // 🔔 per-image blink
                    : trainingCompleted
                    ? 1.0                           // ✅ finished image
                    : (isActive
                    ? blinkAnimation.value
                    : 0.3),
                child: child,
              );
            },
            child: Draggable<String>(
              data: name,
              feedback: _imageCard(name),
              childWhenDragging:
              Opacity(opacity: 0.3, child: _imageCard(name)),
              child: _imageCard(name),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.blue, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontFamily: 'BubbleFont',
              ),
            ),
          ),
        ),
        Text(
          "$count / $maxAllowedDrags",
          style: TextStyle(
            fontSize: 12,
            color: locked ? Colors.red : Colors.grey,
            fontWeight: locked ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }


  Widget _imageCard(String name) {
    final size = MediaQuery.of(context).size.width * 0.12;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Colors.blue, // 🎨 border color
          width: 5,                 // 📏 border thickness
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Image.asset(
          "assets/images/$name.png",
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }


  List<String> _imagesForLetter(String letter) {
    return {
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
    }[letter]!;
  }

  @override
  void dispose() {
    super.dispose();
    blinkController.dispose();
  }
}
