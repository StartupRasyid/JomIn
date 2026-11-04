
import 'package:flutter/material.dart';

enum JominLogoType {
  extended,
  compact,
}

class JominLogo extends StatefulWidget {
  final JominLogoType type;
  final double width;
  final bool animated;
  final Duration duration;
  final Color burgundy;
  final Color background;

  const JominLogo({
    super.key,
    this.type = JominLogoType.extended,
    this.width = 300,
    this.animated = false,
    this.duration = const Duration(milliseconds: 1400),
    this.burgundy = const Color(0xFF7C2140),
    this.background = const Color(0xFFFCFBFC),
  });

  @override
  State<JominLogo> createState() => _JominLogoState();
}

class _JominLogoState extends State<JominLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (widget.animated) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant JominLogo oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animated != widget.animated) {
      if (widget.animated) {
        _controller.forward(from: 0);
      } else {
        _controller.value = 1;
      }
    }

    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExtended = widget.type == JominLogoType.extended;

    return SizedBox(
      width: widget.width,
      height: isExtended ? widget.width * 0.30 : widget.width,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: JominLogoPainter(
              type: widget.type,
              progress: Curves.easeInOut.transform(
                _controller.value,
              ),
              burgundy: widget.burgundy,
              background: widget.background,
            ),
          );
        },
      ),
    );
  }
}

class JominLogoPainter extends CustomPainter {
  final JominLogoType type;
  final double progress;
  final Color burgundy;
  final Color background;

  JominLogoPainter({
    required this.type,
    required this.progress,
    required this.burgundy,
    required this.background,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (type == JominLogoType.extended) {
      _drawExtended(canvas, size);
    } else {
      _drawCompact(canvas, size);
    }
  }

  void _drawExtended(Canvas canvas, Size size) {
    final unit = size.height / 100;
    final symbolSize = size.height;
    final wordWidth = size.width - symbolSize;

    // Draw the Jom wordmark.
    if (progress > 0.65) {
      final opacity = ((progress - 0.65) / 0.35).clamp(0.0, 1.0);

      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Jom',
          style: TextStyle(
            fontSize: 68 * unit,
            fontWeight: FontWeight.w800,
            color: burgundy.withValues(alpha: opacity),
            letterSpacing: -3 * unit,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: wordWidth);

      textPainter.paint(
        canvas,
        Offset(0, 13 * unit),
      );
    }

    // Draw the symbol.
    canvas.save();

    canvas.translate(wordWidth, 0);
    canvas.scale(unit);

    _drawSquareSymbol(canvas);

    canvas.restore();
  }

  void _drawSquareSymbol(Canvas canvas) {
    final squarePaint = Paint()
      ..color = burgundy
      ..style = PaintingStyle.fill;

    // Burgundy rounded square.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 100, 100),
        const Radius.circular(12),
      ),
      squarePaint,
    );

    final whitePaint = Paint()
      ..color = background
      ..style = PaintingStyle.fill;

    // Dot.
    if (progress > 0.05) {
      canvas.drawCircle(
        const Offset(28, 16),
        8 * _fade(0.05, 0.25),
        whitePaint,
      );
    }

    // Vertical stem.
    if (progress > 0.25) {
      canvas.drawRect(
        const Rect.fromLTWH(22, 30, 12, 58),
        whitePaint..color = background.withValues(
          alpha: _fade(0.25, 0.45),
        ),
      );
    }

    // Doorway.
    if (progress > 0.40) {
      final doorPaint = Paint()
        ..color = background.withValues(
          alpha: _fade(0.40, 0.80),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.square;

      final door = Path()
        ..moveTo(39, 88)
        ..lineTo(39, 36)
        ..quadraticBezierTo(39, 20, 57, 20)
        ..quadraticBezierTo(75, 20, 75, 36)
        ..lineTo(75, 88);

      canvas.drawPath(door, doorPaint);
    }

    // Door handle.
    if (progress > 0.80) {
      final handlePaint = Paint()
        ..color = background
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        const Offset(49, 56),
        3.5 * _fade(0.80, 1.0),
        handlePaint,
      );

      canvas.drawCircle(
        const Offset(49, 56),
        1.5 * _fade(0.80, 1.0),
        squarePaint,
      );
    }
  }

  void _drawCompact(Canvas canvas, Size size) {
    final unit = size.width / 100;

    canvas.save();
    canvas.scale(unit);

    final outlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.square;

    // Outer compact shield / doorway outline.
    final outline = Path()
      ..moveTo(42, 8)
      ..lineTo(88, 8)
      ..lineTo(88, 65)
      ..cubicTo(85, 82, 72, 93, 50, 94)
      ..cubicTo(27, 94, 13, 83, 10, 65);

    if (progress > 0.1) {
      canvas.drawPath(outline, outlinePaint);
    }

    final burgundyPaint = Paint()
      ..color = burgundy
      ..style = PaintingStyle.fill;

    // Dot.
    if (progress > 0.2) {
      canvas.drawCircle(
        const Offset(31, 16),
        8 * _fade(0.2, 0.4),
        burgundyPaint,
      );
    }

    // Vertical stem.
    if (progress > 0.4) {
      canvas.drawRect(
        const Rect.fromLTWH(25, 32, 12, 37),
        burgundyPaint,
      );
    }

    // Door shape.
    if (progress > 0.55) {
      final outerDoor = Path()
        ..moveTo(42, 69)
        ..lineTo(42, 39)
        ..quadraticBezierTo(42, 20, 61, 20)
        ..quadraticBezierTo(80, 20, 80, 39)
        ..lineTo(80, 69)
        ..close();

      canvas.drawPath(outerDoor, burgundyPaint);

      final innerDoor = Path()
        ..moveTo(48, 69)
        ..lineTo(48, 41)
        ..lineTo(62, 33)
        ..quadraticBezierTo(74, 38, 74, 42)
        ..lineTo(74, 69)
        ..close();

      canvas.drawPath(
        innerDoor,
        Paint()..color = background,
      );
    }

    // Door handle.
    if (progress > 0.8) {
      canvas.drawCircle(
        const Offset(58, 49),
        3,
        burgundyPaint,
      );

      canvas.drawCircle(
        const Offset(58, 49),
        1.2,
        Paint()..color = background,
      );
    }

    canvas.restore();
  }

  double _fade(double start, double end) {
    return ((progress - start) / (end - start))
        .clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(covariant JominLogoPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.type != type ||
        oldDelegate.burgundy != burgundy ||
        oldDelegate.background != background;
  }
}

// Extended Logo - Splash Screen:

// JominLogo(
//   type: JominLogoType.extended,
//   width: 320,
//   animated: true,
// )

// Compact Logo - App Navigation

// JominLogo(
//   type: JominLogoType.compact,
//   width: 64,
//   animated: false,
// )

// Compact Logo - Animation Loading

// JominLogo(
//   type: JominLogoType.compact,
//   width: 120,
//   animated: true,
//   duration: const Duration(milliseconds: 1800),
// )