import 'package:flutter/material.dart';
import 'home_page.dart';
import 'dart:math';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> with TickerProviderStateMixin {

  late final AnimationController _bounceController;
  late final AnimationController _pulseController;
  late final AnimationController _starController;
  late final AnimationController _floatController;

  late final Animation<double> _pulseAnim;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _pulseController.dispose();
    _starController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;

          return Stack(
            children: [

              // 🎨 Rainbow Gradient Background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFFD966),
                      Color(0xFFFF9F40),
                      Color(0xFFFF6B9D),
                      Color(0xFFC06EF3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              // ✨ Twinkling Stars — adjusts star positions per orientation
              AnimatedBuilder(
                animation: _starController,
                builder: (_, __) {
                  return CustomPaint(
                    size: size,
                    painter: StarFieldPainter(
                      _starController.value,
                      isPortrait: isPortrait,
                    ),
                  );
                },
              ),

              // 🌊 Bottom Wave
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(size.width, isPortrait ? 140 : 100),
                  painter: WavePainter(),
                ),
              ),

              // 🎮 Auto-switching layout
              SafeArea(
                child: isPortrait
                    ? _buildPortraitLayout()
                    : _buildLandscapeLayout(),
              ),

            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────
  // 📱 PORTRAIT LAYOUT
  // ─────────────────────────────────────────
  Widget _buildPortraitLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        const SizedBox(height: 24),

        // 🐾 Emoji row stays at top
        _buildEmojiRow(horizontal: 16),

        const SizedBox(height: 300), // fixed gap between emoji and card

        // 📛 Title card — floats gently
        AnimatedBuilder(
          animation: _floatAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _floatAnim.value),
            child: child,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: _buildTitleCard(fontSize: 40, iconSize: 52),
          ),
        ),

        const SizedBox(height: 36), // fixed gap between card and button

        // 🚀 Start button directly below card
        _buildStartButton(),

      ],
    );
  }

  // ─────────────────────────────────────────
  // 🖥️ LANDSCAPE LAYOUT
  // ─────────────────────────────────────────
  Widget _buildLandscapeLayout() {
    return Column(
      children: [

        const SizedBox(height: 16),

        _buildEmojiRow(horizontal: 24),

        const Spacer(),

        AnimatedBuilder(
          animation: _floatAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _floatAnim.value),
            child: child,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: _buildTitleCard(fontSize: 32, iconSize: 42),
          ),
        ),

        const SizedBox(height: 28),

        _buildStartButton(),

        const Spacer(),

      ],
    );
  }

  // ─────────────────────────────────────────
  // 🃏 Shared Title Card
  // ─────────────────────────────────────────
  Widget _buildTitleCard({required double fontSize, required double iconSize}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360), // 👈 replaces width: double.infinity
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFFFF176)],
            ).createShader(bounds),
            child: Text(
              "Letter Sound\nMaze",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.15,
                letterSpacing: 1.2,
                shadows: const [
                  Shadow(blurRadius: 12, color: Color(0x88000000), offset: Offset(3, 3)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "🎯 Learn • Play • Grow",
              style: TextStyle(
                fontSize: 14, color: Colors.white,
                fontWeight: FontWeight.w700, letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🚀 Shared Start Button
  // ─────────────────────────────────────────
  Widget _buildStartButton() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: _pulseAnim.value,
        child: child,
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.red.withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
            border: Border.all(
                color: Colors.white.withOpacity(0.6), width: 2.5),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🚀', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Text(
                "Let's Go!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
                  shadows: [
                    Shadow(
                      blurRadius: 6,
                      color: Colors.black26,
                      offset: Offset(1, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🐾 Shared Emoji Row
  // ─────────────────────────────────────────
  Widget _buildEmojiRow({required double horizontal}) {
    final emojis = ['🦁', '🐸', '🦋', '🐳', '🦊'];
    final delays = [0.0, 0.15, 0.30, 0.45, 0.60];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(emojis.length, (i) {
          return AnimatedBuilder(
            animation: _bounceController,
            builder: (_, __) {
              final staggered =
              sin((_bounceController.value + delays[i]) * pi * 2);
              return Transform.translate(
                offset: Offset(0, staggered * 12),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(emojis[i],
                        style: const TextStyle(fontSize: 28)),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────
// ✨ Star Field Painter
// ─────────────────────────────────────────
class StarFieldPainter extends CustomPainter {
  final double animValue;
  final bool isPortrait;

  StarFieldPainter(this.animValue, {required this.isPortrait});

  final List<Offset> _portraitPositions = const [
    Offset(0.08, 0.06), Offset(0.88, 0.05), Offset(0.50, 0.03),
    Offset(0.93, 0.18), Offset(0.05, 0.30), Offset(0.80, 0.35),
    Offset(0.15, 0.55), Offset(0.92, 0.50), Offset(0.40, 0.65),
    Offset(0.10, 0.75), Offset(0.85, 0.70), Offset(0.55, 0.80),
    Offset(0.25, 0.88), Offset(0.70, 0.90), Offset(0.48, 0.95),
  ];

  final List<Offset> _landscapePositions = const [
    Offset(0.08, 0.12), Offset(0.85, 0.08), Offset(0.45, 0.05),
    Offset(0.92, 0.25), Offset(0.15, 0.40), Offset(0.78, 0.50),
    Offset(0.30, 0.70), Offset(0.60, 0.80), Offset(0.10, 0.85),
    Offset(0.90, 0.75), Offset(0.50, 0.55), Offset(0.70, 0.18),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final positions = isPortrait ? _portraitPositions : _landscapePositions;

    for (int i = 0; i < positions.length; i++) {
      final opacity = 0.4 + 0.6 * sin((animValue + i * 0.15) * pi);
      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      final radius = 3.0 + 2.0 * sin((animValue + i * 0.2) * pi);
      canvas.drawCircle(
        Offset(positions[i].dx * size.width, positions[i].dy * size.height),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StarFieldPainter old) =>
      old.animValue != animValue || old.isPortrait != isPortrait;
}

// ─────────────────────────────────────────
// 🌊 Wave Painter
// ─────────────────────────────────────────
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.2,
          size.width * 0.5, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.7,
          size.width, size.height * 0.4)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.35,
          size.width * 0.6, size.height * 0.60)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.75,
          size.width, size.height * 0.55)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}