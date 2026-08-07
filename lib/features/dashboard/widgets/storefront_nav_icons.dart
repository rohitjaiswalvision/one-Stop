import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sixam_mart/features/home/widgets/storefront/storefront_tokens.dart';

/// The two tab glyphs that have no Material equivalent, painted rather than
/// approximated with a near-miss icon.
class StorefrontNavIcons {
  const StorefrontNavIcons._();

  /// The assistant face: a filled yellow disc with two eyes and a smile. It keeps
  /// its colour whether or not the tab is selected — it is a mark, not a state.
  static Widget assistant({double size = 24}) => CustomPaint(
    size: Size.square(size),
    painter: const _AssistantFacePainter(),
  );

  /// Four dots in a 2x2 block, the "everything else" glyph.
  static Widget grid({double size = 24, required Color color}) => CustomPaint(
    size: Size.square(size),
    painter: _GridDotsPainter(color),
  );
}

class _AssistantFacePainter extends CustomPainter {
  const _AssistantFacePainter();

  static const Color _face = StorefrontTokens.yellow;
  static const Color _feature = Color(0xFF2E2F32);

  @override
  void paint(Canvas canvas, Size size) {
    final double d = size.shortestSide;
    final Offset center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, d / 2, Paint()..color = _face..isAntiAlias = true);

    final Paint feature = Paint()..color = _feature..isAntiAlias = true;
    final double eyeR = d * 0.062;
    canvas.drawCircle(center.translate(-d * 0.19, -d * 0.13), eyeR, feature);
    canvas.drawCircle(center.translate(d * 0.19, -d * 0.13), eyeR, feature);

    // Smile: the lower arc of a circle a touch above centre, so the curve sits
    // where a mouth would rather than hugging the rim.
    final Rect mouth = Rect.fromCenter(center: center.translate(0, -d * 0.04), width: d * 0.52, height: d * 0.52);
    canvas.drawArc(
      mouth, math.pi * 0.18, math.pi * 0.64, false,
      Paint()
        ..color = _feature
        ..style = PaintingStyle.stroke
        ..strokeWidth = d * 0.075
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_AssistantFacePainter oldDelegate) => false;
}

class _GridDotsPainter extends CustomPainter {
  final Color color;
  const _GridDotsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final double d = size.shortestSide;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double offset = d * 0.245;
    final Paint paint = Paint()..color = color..isAntiAlias = true;

    for(final double dx in [-offset, offset]) {
      for(final double dy in [-offset, offset]) {
        canvas.drawCircle(center.translate(dx, dy), d * 0.175, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridDotsPainter oldDelegate) => oldDelegate.color != color;
}
