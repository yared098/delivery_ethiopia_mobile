import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  // Master fade/scale-in for the logo + title
  late final AnimationController _introCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  // Continuous shimmer on the progress bar
  late final AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();

    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _introCtrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _introCtrl, curve: Curves.easeOutBack),
    );
    _introCtrl.forward();

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary,
              Color.lerp(scheme.primary, Colors.black, 0.35) ?? scheme.primary,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Decorative blurred circles ──
              Positioned(
                top: -80,
                right: -80,
                child: _Blob(
                  color: Colors.white.withOpacity(0.10),
                  size: 240,
                ),
              ),
              Positioned(
                bottom: -100,
                left: -60,
                child: _Blob(
                  color: Colors.white.withOpacity(0.08),
                  size: 280,
                ),
              ),

              // ── Center content ──
              Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LogoBadge(scheme: scheme),
                        const SizedBox(height: 26),
                        const Text(
                          'Deliver Ethiopia',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Fast. Safe. Nationwide.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13.5,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 56),
                        _ShimmerBar(
                          controller: _progressCtrl,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Preparing your account…',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Footer version tag ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: FadeTransition(
                  opacity: _fade,
                  child: Column(
                    children: [
                      Text(
                        'v1.0.0',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 11.5,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Made in Ethiopia 🇪🇹',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Logo badge — rounded square with soft glow
// ═══════════════════════════════════════════════════════════════
class _LogoBadge extends StatelessWidget {
  const _LogoBadge({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Icon(
        Icons.local_shipping_rounded,
        size: 56,
        color: scheme.primary,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Soft blurred circle in the background
// ═══════════════════════════════════════════════════════════════
class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Shimmer bar — an indeterminate pill-shaped progress bar
// ═══════════════════════════════════════════════════════════════
class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({required this.controller, required this.color});
  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const barWidth = 180.0;
    const barHeight = 4.0;

    return SizedBox(
      width: barWidth,
      height: barHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(barHeight),
        child: Stack(
          children: [
            // Track
            Container(
              color: color.withOpacity(0.22),
            ),
            // Moving highlight
            AnimatedBuilder(
              animation: controller,
              builder: (_, __) {
                final t = controller.value; // 0..1
                final travel = barWidth * 0.6;
                final left = (barWidth + travel) * t - travel;
                return Positioned(
                  left: left,
                  top: 0,
                  bottom: 0,
                  width: travel,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0),
                          color.withOpacity(0.9),
                          color.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
