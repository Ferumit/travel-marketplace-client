import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Утилита для генерации кастомных PNG-маркеров точек маршрута.
///
/// Маркер — это пин-форма (круг + треугольный хвостик снизу) с:
///   вЂў цветным фоном и мягкой тенью
///   вЂў белым номером точки по центру
///
/// Используется совместно с [BitmapDescriptor.fromBytes] из yandex_mapkit.
class WaypointMarkerPainter {
  WaypointMarkerPainter._();

  /// Генерирует PNG-байты маркера нужного [color] с порядковым [number].
  ///
  /// [size] — диаметр круглой части маркера в логических пикселях.
  /// [devicePixelRatio] — multiplier для чёткого рендера на HiDPI/Retina.
  static Future<Uint8List> generate({
    required ui.Color color,
    required int number,
    double size = 52,
    double devicePixelRatio = 2.5,
  }) async {
    final scale = devicePixelRatio;
    final w = size * scale;
    // Высота = diameter + tail height
    final tailH = size * 0.42 * scale;
    final h = size * scale + tailH;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // в”Ђв”Ђ Тень в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    final shadowPaint = ui.Paint()
      ..color = const ui.Color(0x55000000)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 6 * scale);
    _drawPin(
      canvas,
      w,
      h,
      tailH,
      size * scale,
      shadowPaint,
      offsetY: 3 * scale,
    );

    // в”Ђв”Ђ Основной круг + хвостик в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    final fillPaint = ui.Paint()..color = color;
    _drawPin(canvas, w, h, tailH, size * scale, fillPaint);

    // в”Ђв”Ђ Белое внутреннее кольцо (border) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale;
    final r = size * scale / 2;
    canvas.drawCircle(ui.Offset(w / 2, r), r - 2 * scale, borderPaint);

    // в”Ђв”Ђ Номер точки в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    final paraBuilder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: ui.TextAlign.center,
              fontSize: size * scale * 0.38,
              fontWeight: ui.FontWeight.w700,
            ),
          )
          ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFFFFFFF)))
          ..addText(number.toString());

    final para = paraBuilder.build();
    para.layout(ui.ParagraphConstraints(width: w));

    // Вертикально центрируем текст в круге
    final textY = r - para.height / 2;
    canvas.drawParagraph(para, ui.Offset(0, textY));

    // в”Ђв”Ђ Финализируем в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    final picture = recorder.endRecording();
    final image = await picture.toImage(w.round(), h.round());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError(
        '[WaypointMarkerPainter] toByteData returned null — '
        'cannot encode marker PNG for color=$color, number=$number',
      );
    }
    return byteData.buffer.asUint8List();
  }

  /// Рисует пин-форму: круг + острый хвостик снизу.
  static void _drawPin(
    ui.Canvas canvas,
    double w,
    double h,
    double tailH,
    double diameter,
    ui.Paint paint, {
    double offsetY = 0,
  }) {
    final r = diameter / 2;
    final cx = w / 2;
    final cy = r + offsetY;

    final path = ui.Path();

    // Хвостик: треугольник от нижней точки круга к острию
    final tailTip = ui.Offset(cx, h - 1 + offsetY);
    final tailLeft = ui.Offset(cx - r * 0.55, cy + r * 0.65);
    final tailRight = ui.Offset(cx + r * 0.55, cy + r * 0.65);

    path.moveTo(tailTip.dx, tailTip.dy);
    path.lineTo(tailLeft.dx, tailLeft.dy);

    // Дуга по нижней части круга слева направо
    path.arcTo(
      ui.Rect.fromCircle(center: ui.Offset(cx, cy), radius: r),
      math.pi * 0.55 + math.pi, // startAngle: ~200В° (слева снизу)
      -math.pi * 1.1, // sweepAngle: -198В° в†’ заканчивается справа снизу
      false,
    );

    path.lineTo(tailRight.dx, tailRight.dy);
    path.close();

    // Рисуем полный круг отдельно
    canvas.drawCircle(ui.Offset(cx, cy), r, paint);
    canvas.drawPath(path, paint);
  }
}


