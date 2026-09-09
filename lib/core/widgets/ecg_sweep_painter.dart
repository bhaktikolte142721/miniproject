import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Renders a clinical patient monitor ECG trace with glowing trail and grid lines.
class EcgSweepView extends StatefulWidget {
  final double height;
  final Color traceColor;
  final double speed; // sweeps per second
  final bool isPaused;

  const EcgSweepView({
    super.key,
    this.height = 120,
    this.traceColor = AppColors.primaryMint,
    this.speed = 0.25,
    this.isPaused = false,
  });

  @override
  State<EcgSweepView> createState() => _EcgSweepViewState();
}

class _EcgSweepViewState extends State<EcgSweepView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (1000 / widget.speed).round()),
    )..repeat();
  }

  @override
  void didUpdateWidget(EcgSweepView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.isPaused && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Dark slate hospital display
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryTeal.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryMint.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Clinical grid overlay
            CustomPaint(
              painter: _EcgGridPainter(),
              size: Size.infinite,
            ),
            // Animated ECG wave
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _EcgWavePainter(
                    progress: _controller.value,
                    traceColor: widget.traceColor,
                  ),
                  size: Size.infinite,
                );
              },
            ),
            // Status overlay tag
            Positioned(
              top: 10,
              left: 14,
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.traceColor,
                      boxShadow: [
                        BoxShadow(
                          color: widget.traceColor,
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LEAD II • LIVE ECG (50mm/s)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: widget.traceColor.withOpacity(0.85),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EcgGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final majorPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;

    const double step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), majorPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), majorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EcgWavePainter extends CustomPainter {
  final double progress;
  final Color traceColor;

  _EcgWavePainter({required this.progress, required this.traceColor});

  double _getEcgSample(double t) {
    // Standard P-Q-R-S-T physiological wave cycle (0.0 to 1.0)
    final cycle = t % 1.0;
    if (cycle < 0.15) {
      // Baseline
      return 0.0;
    } else if (cycle < 0.25) {
      // P wave (atrial depolarization)
      final pT = (cycle - 0.15) / 0.10;
      return 0.18 * math.sin(pT * math.pi);
    } else if (cycle < 0.32) {
      // PR segment
      return 0.0;
    } else if (cycle < 0.35) {
      // Q wave (septal depolarization)
      final qT = (cycle - 0.32) / 0.03;
      return -0.15 * math.sin(qT * math.pi);
    } else if (cycle < 0.40) {
      // R wave (ventricular depolarization - high sharp spike)
      final rT = (cycle - 0.35) / 0.05;
      return 1.0 * math.sin(rT * math.pi);
    } else if (cycle < 0.44) {
      // S wave
      final sT = (cycle - 0.40) / 0.04;
      return -0.28 * math.sin(sT * math.pi);
    } else if (cycle < 0.52) {
      // ST segment
      return 0.0;
    } else if (cycle < 0.68) {
      // T wave (ventricular repolarization)
      final tT = (cycle - 0.52) / 0.16;
      return 0.32 * math.sin(tT * math.pi);
    } else {
      // Baseline until next beat
      return 0.0;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height * 0.55;
    final maxAmp = size.height * 0.38;
    final sweepX = progress * size.width;

    final glowPaint = Paint()
      ..color = traceColor.withOpacity(0.4)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final linePaint = Paint()
      ..color = traceColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool started = false;

    // We draw the wave up to sweepX, with an erase gap ahead of the sweep head
    const double eraseGap = 28.0;
    const int numSamples = 240;
    const double cycleCount = 3.2; // 3.2 beats across screen width

    for (int i = 0; i <= numSamples; i++) {
      final x = (i / numSamples) * size.width;
      // Distance behind sweep head
      final distFromSweep = (x - sweepX);

      // Skip drawing in erase window just ahead of the sweep
      if (distFromSweep > 0 && distFromSweep < eraseGap) {
        continue;
      }

      final normalizedT = (x / size.width) * cycleCount;
      final yVal = _getEcgSample(normalizedT);
      final y = centerY - (yVal * maxAmp);

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    // Glowing sweep head dot
    final sweepY = centerY - (_getEcgSample((sweepX / size.width) * cycleCount) * maxAmp);
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(sweepX, sweepY), 3.5, dotPaint);

    final haloPaint = Paint()
      ..color = traceColor.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(sweepX, sweepY), 7, haloPaint);
  }

  @override
  bool shouldRepaint(covariant _EcgWavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.traceColor != traceColor;
  }
}
