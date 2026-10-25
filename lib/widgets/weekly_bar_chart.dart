import 'dart:math' as math;
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Animated weekly bar chart (last 7 days) drawn with CustomPainter.
class WeeklyBarChart extends StatefulWidget {
  final List<MapEntry<DateTime, int>> data;
  const WeeklyBarChart({super.key, required this.data});

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();
  late final Animation<double> _anim =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);

  int? _selected;

  @override
  void didUpdateWidget(covariant WeeklyBarChart old) {
    super.didUpdateWidget(old);
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1.6,
      child: LayoutBuilder(builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        return GestureDetector(
          onTapUp: (d) {
            final slot = size.width / widget.data.length;
            final i = (d.localPosition.dx / slot).floor();
            setState(() => _selected = _selected == i ? null : i);
          },
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _BarPainter(
                data: widget.data,
                progress: _anim.value.clamp(0.0, 1.2),
                selected: _selected,
                barColor: cs.primary,
                gridColor: cs.outlineVariant,
                textColor: cs.onSurface,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<MapEntry<DateTime, int>> data;
  final double progress;
  final int? selected;
  final Color barColor, gridColor, textColor;

  _BarPainter({
    required this.data,
    required this.progress,
    required this.selected,
    required this.barColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 28.0, bottomPad = 24.0;
    final chartH = size.height - topPad - bottomPad;
    final maxV = math.max(1, data.map((e) => e.value).fold<int>(0, math.max));
    final niceMax = _niceMax(maxV);
    final slot = size.width / data.length;
    final barW = slot * 0.5;

    // Grid lines (4 steps).
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = topPad + chartH * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    for (var i = 0; i < data.length; i++) {
      final v = data[i].value;
      final h = chartH * (v / niceMax) * progress.clamp(0.0, 1.0);
      final x = slot * i + (slot - barW) / 2;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, topPad + chartH - h, barW, h),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      final isSel = selected == i;
      canvas.drawRRect(
        rect,
        Paint()
          ..color =
              barColor.withValues(alpha: selected == null || isSel ? 1 : 0.4),
      );

      // Day label.
      _text(canvas, DateFormat('E').format(data[i].key),
          Offset(slot * i + slot / 2, size.height - 10), 11,
          textColor.withValues(alpha: 0.7));

      // Value bubble on selection.
      if (isSel && v > 0) {
        _text(canvas, _short(v),
            Offset(slot * i + slot / 2, topPad + chartH - h - 12), 12,
            textColor,
            bold: true);
      }
    }
  }

  static int _niceMax(int v) {
    final mag = math.pow(10, v.toString().length - 1).toInt();
    return ((v / mag).ceil() * mag).clamp(1, 1 << 40);
  }

  static String _short(int v) => v >= 1000000
      ? '${(v / 1000000).toStringAsFixed(1)}M'
      : '${(v / 1000).round()}k';

  void _text(Canvas c, String s, Offset center, double fs, Color col,
      {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              fontSize: fs,
              color: col,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
      textDirection: widgets.TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _BarPainter o) =>
      o.progress != progress || o.selected != selected || o.data != data;
}
