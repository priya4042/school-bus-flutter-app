import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Stylish animated loader matching premium app aesthetic
/// - Dual rotating rings with gradient
/// - Smooth animation
/// - Optional label below
class StylishLoader extends StatefulWidget {
  final double size;
  final String? label;
  final Color? color;

  const StylishLoader({
    super.key,
    this.size = 56,
    this.label,
    this.color,
  });

  @override
  State<StylishLoader> createState() => _StylishLoaderState();
}

class _StylishLoaderState extends State<StylishLoader> with TickerProviderStateMixin {
  late AnimationController _outerCtrl;
  late AnimationController _innerCtrl;

  @override
  void initState() {
    super.initState();
    _outerCtrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _innerCtrl = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _outerCtrl.dispose();
    _innerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer rotating ring
              AnimatedBuilder(
                animation: _outerCtrl,
                builder: (_, __) => Transform.rotate(
                  angle: _outerCtrl.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _RingPainter(
                      color: color,
                      strokeWidth: 3.5,
                      sweepAngle: math.pi * 1.4,
                    ),
                  ),
                ),
              ),
              // Inner pulsing dot
              AnimatedBuilder(
                animation: _innerCtrl,
                builder: (_, __) => Container(
                  width: widget.size * 0.25,
                  height: widget.size * 0.25,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4 * _innerCtrl.value),
                        blurRadius: 12 * _innerCtrl.value,
                        spreadRadius: 2 * _innerCtrl.value,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.label!,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: AppColors.slate500,
            ),
          ),
        ],
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double sweepAngle;

  _RingPainter({
    required this.color,
    required this.strokeWidth,
    required this.sweepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring (light)
    final bgPaint = Paint()
      ..color = AppColors.slate100
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Animated arc with gradient
    final arcPaint = Paint()
      ..shader = SweepGradient(
        colors: [color.withOpacity(0.0), color, color.withOpacity(0.8)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.sweepAngle != sweepAngle;
}

/// Compact loader for inline use (e.g., in lists)
class StylishLoaderCompact extends StatelessWidget {
  final String? label;
  const StylishLoaderCompact({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: StylishLoader(size: 48, label: label),
      ),
    );
  }
}

/// Full-page loading screen with branding
class AppLoadingScreen extends StatefulWidget {
  final String? message;
  const AppLoadingScreen({super.key, this.message});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen> with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _ringCtrl = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _ringCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.4,
            colors: [
              AppColors.slate800,
              AppColors.slate900,
              Color(0xFF000000),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo with glowing rings
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer rotating ring
                    AnimatedBuilder(
                      animation: _ringCtrl,
                      builder: (_, __) => Transform.rotate(
                        angle: _ringCtrl.value * 2 * math.pi,
                        child: CustomPaint(
                          size: const Size(140, 140),
                          painter: _RingPainter(
                            color: AppColors.primary,
                            strokeWidth: 2,
                            sweepAngle: math.pi * 1.6,
                          ),
                        ),
                      ),
                    ),
                    // Inner counter-rotating ring
                    AnimatedBuilder(
                      animation: _ringCtrl,
                      builder: (_, __) => Transform.rotate(
                        angle: -_ringCtrl.value * 2 * math.pi,
                        child: CustomPaint(
                          size: const Size(110, 110),
                          painter: _RingPainter(
                            color: AppColors.primaryLight,
                            strokeWidth: 1.5,
                            sweepAngle: math.pi * 1.2,
                          ),
                        ),
                      ),
                    ),
                    // Pulsing logo container
                    AnimatedBuilder(
                      animation: _glowCtrl,
                      builder: (_, __) => Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4 + (0.2 * _glowCtrl.value)),
                              blurRadius: 24 + (12 * _glowCtrl.value),
                              spreadRadius: 2 + (2 * _glowCtrl.value),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Brand name with shimmer
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Colors.white,
                    Color(0xFF60A5FA),
                    Colors.white,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ).createShader(bounds),
                child: const Text(
                  'BusWay Pro',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Enterprise Fleet Manager',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: 32),
              // Subtle status text
              Text(
                widget.message ?? 'Initializing...',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
