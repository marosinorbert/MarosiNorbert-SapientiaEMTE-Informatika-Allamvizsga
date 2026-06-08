import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _fade;
  late final Animation<double> _cardScale;
  late final Animation<Offset> _slide;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );

    _cardScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _progress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeInOutCubic),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 3100), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _pulse(double offset) {
    return 0.5 + 0.5 * math.sin((_controller.value * 2 * math.pi) + offset);
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFEAF7EF);
    const primary = Color(0xFF22C55E);
    const darkGreen = Color(0xFF14532D);

    return Scaffold(
      backgroundColor: background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final pulse1 = _pulse(0);
          final pulse2 = _pulse(1.6);
          final pulse3 = _pulse(3.2);

          return Center(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: ScaleTransition(
                  scale: _cardScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.22 + pulse1 * 0.12),
                              blurRadius: 45 + pulse1 * 18,
                              spreadRadius: 6 + pulse1 * 4,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 158,
                              height: 158,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(38),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 30,
                                    offset: const Offset(0, 18),
                                  ),
                                ],
                              ),
                            ),

                            Image.asset(
                              'assets/images/logo.png',
                              width: 112,
                              height: 112,
                            ),

                            Positioned(
                              top: 32,
                              right: 34,
                              child: _SensorDot(opacity: 0.35 + pulse1 * 0.65),
                            ),
                            Positioned(
                              bottom: 38,
                              left: 30,
                              child: _SensorDot(opacity: 0.35 + pulse2 * 0.65),
                            ),
                            Positioned(
                              bottom: 32,
                              right: 42,
                              child: _SensorDot(opacity: 0.35 + pulse3 * 0.65),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'GreenHouse Pro',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: darkGreen,
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Okos üvegház vezérlés',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4B6354),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 30),

                      Container(
                        width: 180,
                        height: 7,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _progress.value,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF86EFAC),
                                    Color(0xFF22C55E),
                                    Color(0xFF16A34A),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        'Rendszer indítása...',
                        style: TextStyle(
                          fontSize: 12,
                          color: darkGreen.withOpacity(0.65),
                          fontWeight: FontWeight.w500,
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
    );
  }
}

class _SensorDot extends StatelessWidget {
  final double opacity;

  const _SensorDot({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withOpacity(opacity),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(opacity * 0.55),
            blurRadius: 14,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }
}