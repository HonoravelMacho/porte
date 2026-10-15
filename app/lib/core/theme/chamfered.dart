import 'package:flutter/material.dart';

/// Recorte chanfrado (bordas cortadas estilo HUD de jogo).
class ChamferedBorder extends OutlinedBorder {
  final double chamfer;
  const ChamferedBorder({this.chamfer = 12, super.side = BorderSide.none});

  @override
  OutlinedBorder copyWith({BorderSide? side}) =>
      ChamferedBorder(chamfer: chamfer, side: side ?? this.side);

  Path _path(Rect rect) {
    final c = chamfer.clamp(0, 40).toDouble();
    return Path()
      ..moveTo(rect.left + c, rect.top)
      ..lineTo(rect.right - c, rect.top)
      ..lineTo(rect.right, rect.top + c)
      ..lineTo(rect.right, rect.bottom - c)
      ..lineTo(rect.right - c, rect.bottom)
      ..lineTo(rect.left + c, rect.bottom)
      ..lineTo(rect.left, rect.bottom - c)
      ..lineTo(rect.left, rect.top + c)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(_path(rect), side.toPaint());
  }

  @override
  ShapeBorder scale(double t) => ChamferedBorder(chamfer: chamfer * t, side: side.scale(t));
}

/// Clip chanfrado para painéis translúcidos.
class ChamferedClipper extends CustomClipper<Path> {
  final double chamfer;
  const ChamferedClipper({this.chamfer = 14});

  @override
  Path getClip(Size size) {
    final c = chamfer;
    return Path()
      ..moveTo(c, 0)
      ..lineTo(size.width - c, 0)
      ..lineTo(size.width, c)
      ..lineTo(size.width, size.height - c)
      ..lineTo(size.width - c, size.height)
      ..lineTo(c, size.height)
      ..lineTo(0, size.height - c)
      ..lineTo(0, c)
      ..close();
  }

  @override
  bool shouldReclip(covariant ChamferedClipper old) => old.chamfer != chamfer;
}
