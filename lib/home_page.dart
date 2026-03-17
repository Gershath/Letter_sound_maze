import 'package:flutter/material.dart';
import 'training_page.dart';
import 'gaming_page.dart';
import 'data/progress_manager.dart';
import 'performance_analysis_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}


class FloatingButtonWrapper extends StatefulWidget {
  final Widget child;
  final double distance; // how many pixels to move
  final Duration duration;

  const FloatingButtonWrapper({
    super.key,
    required this.child,
    this.distance = 8,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<FloatingButtonWrapper> createState() => _FloatingButtonWrapperState();
}

class _FloatingButtonWrapperState extends State<FloatingButtonWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -widget.distance,
      end: widget.distance,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0), // left ↔ right
          child: child,
        );
      },
      child: widget.child,
    );
  }
}



class _HomePageState extends State<HomePage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    allDone = ProgressManager.isAllCyclesCompleted();

    if (allDone && !_gameUnlockPopupShown) {
      _gameUnlockPopupShown = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showGameUnlockedPopup();
      });
    }
  }


  static bool _gameUnlockPopupShown = false;
  bool allDone = false;
  // ✅ FIX

  @override
  Widget build(BuildContext context) {



    return Scaffold(


      body: Stack(
        children: [
          // 🌄 FULL SCREEN BACKGROUND
          Positioned.fill(
            child: Image.asset(
              MediaQuery.of(context).orientation == Orientation.portrait
                  ? "assets/images/home_pot_bg.png"
                  : "assets/images/home_bg.png",
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // 🌟 CONTENT
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [

                            // 📊 Top Right Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 0, right: 10),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(30),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const PerformanceAnalysisPage(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.bar_chart_rounded,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            //Title
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "Letter Sound Maze",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),

                            const SizedBox(height: 25),

                            _greeting(),

                            const SizedBox(height: 30),

                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                FloatingButtonWrapper(
                                  child: _cycleButton(0, "A–E"),
                                ),
                                FloatingButtonWrapper(
                                  child: _cycleButton(1, "F–J"),
                                ),
                                FloatingButtonWrapper(
                                  child: _cycleButton(2, "K–O"),
                                ),
                                FloatingButtonWrapper(
                                  child: _cycleButton(3, "P–T"),
                                ),
                                FloatingButtonWrapper(
                                  child: _cycleButton(4, "U–Z"),
                                ),
                              ],
                            ),


                            const SizedBox(height: 25),

                            FloatingButtonWrapper(
                              distance: 10, // slightly more for game button
                              duration: const Duration(seconds: 2),
                              child: _gameButton(),
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


        ],
      ),



    );


  }
  Widget _cycleButton(int index, String label) {
    bool unlocked = ProgressManager.isCycleUnlocked(index);

    return Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: 100,
        height: 70,
        child: ElevatedButton(
          onPressed: () {
            if (unlocked) {
              ProgressManager.currentCycle = index;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TrainingPage(),
                ),
              ).then((_) => setState(() {}));
            } else {
              // 🎉 Show dropdown notification
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 20),
                  duration: const Duration(seconds: 2),
                  content: const Row(
                    children: [
                      Icon(Icons.lock, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "✨ Complete a previous set to unlock!",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
            unlocked ? Colors.pink.shade100 : Colors.grey.shade400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: EdgeInsets.zero,
          ),
          child: unlocked
              ? Text(
            "SET ${index + 1}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: "BubbleFont",
            ),
          )
              : const Icon(Icons.lock, size: 22),
        ),
      ),
    );
  }


  Widget _gameButton() {
    bool unlocked = ProgressManager.isGameUnlocked;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Center(
        child: SizedBox(
          width: 250,
          height: 100,
          child: ElevatedButton(
            onPressed: () {
              if (unlocked) {


                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GamingPage(),
                  ),
                ).then((_) {
                  setState(() {});
                });

              } else {

                // 🎉 Show dropdown notification
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    duration: const Duration(seconds: 2),
                    content: const Row(
                      children: [
                        Icon(Icons.lock, color: Colors.white),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "✨ Complete all sets to unlock the game!",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
              unlocked ? Colors.lightGreen.shade400 : Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              unlocked ? "🎮 Play Game" : "🔒 Game Locked",
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
      ),
    );
  }




  Widget _greeting() {
    return Column(
      children: const [
        Text(
          "👋 Hello, Little Explorer!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: "BubbleFont", // 🎈 YOUR CUSTOM FONT
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.deepPurple,
          ),
        ),
        SizedBox(height: 6),
        Text(
          "Let’s continue your letter adventure 🚀",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: "BubbleFont", // 🎈 SAME FONT
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }








  void _showGameUnlockedPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Center(
            child: Text(
              "🎉 Congratulations!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.videogame_asset,
                size: 60,
                color: Colors.green,
              ),
              SizedBox(height: 12),
              Text(
                "You have completed all sets.\n\n🎮 Game is now unlocked!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    "Okay",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

}
