import 'package:flutter/material.dart';
import 'home_page.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>
    with TickerProviderStateMixin {

  late final AnimationController _cloudController;

  @override
  void initState() {
    super.initState();

    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [

          // 🌤 Sky Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF87CEEB), // sky blue
                  Color(0xFFB0E0E6), // lighter blue
                  Color(0xFFE0F7FF), // soft white blue
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ☁ Moving Clouds
          AnimatedBuilder(
            animation: _cloudController,
            builder: (_, __) {

              double animationValue = _cloudController.value;

              return Stack(
                children: List.generate(4, (index) {

                  double cloudWidth = size.width * 0.35;
                  double cloudHeight = cloudWidth * 0.6;

                  double startY = (index + 1) * size.height / 5;

                  double horizontalPosition =
                      (animationValue * size.width + (index * 200))
                          % (size.width + 200) - 200;

                  return Positioned(
                    left: horizontalPosition,
                    top: startY,
                    child: SizedBox(
                      width: cloudWidth,
                      height: cloudHeight,
                      child: const CloudWidget(),
                    ),
                  );
                }),
              );
            },
          ),

          // 🎮 Center Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Text(
                  "Letter Sound Maze",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black26,
                        offset: Offset(2, 2),
                      )
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    elevation: 12,
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomePage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Start 🚀",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
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

class CloudWidget extends StatelessWidget {
  const CloudWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CloudPainter(),
    );
  }
}

class CloudPainter extends CustomPainter {

  @override
  void paint(Canvas canvas, Size size) {

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    // Main cloud body
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.3,
        size.width * 0.8,
        size.height * 0.4,
      ),
      paint,
    );

    // Cloud puffs
    canvas.drawCircle(
        Offset(size.width * 0.3, size.height * 0.35),
        size.height * 0.25,
        paint);

    canvas.drawCircle(
        Offset(size.width * 0.55, size.height * 0.3),
        size.height * 0.28,
        paint);

    canvas.drawCircle(
        Offset(size.width * 0.75, size.height * 0.4),
        size.height * 0.22,
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}