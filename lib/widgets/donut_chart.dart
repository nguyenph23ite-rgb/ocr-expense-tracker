import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/expense.dart';

/// Animated, tappable donut chart drawn purely with CustomPainter.
class DonutChart extends StatefulWidget {
  final Map<ExpenseCategory, int> data;
  const DonutChart({super.key, required this.data});

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final Animation<double> _anim =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

  ExpenseCategory? _selected;

  @override
  void didUpdateWidget(covariant DonutChart old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap(Offset local, Size size) {
    final total = widget.data.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;
    final center = size.center(Offset.zero);
    final d = local - center;
    final r = d.distance;
    final outer = math.min(size.width, size.height) / 2;
    if (r < outer * 0.55 || r > outer) {
      setState(() => _selected = null);
      return;
    }
    var angle = math.atan2(d.dy, d.dx) + math.pi / 2; // 0 at top
    if (angle < 0) angle += 2 * math.pi;
    var acc = 0.0;
    for (final e in widget.data.entries) {
      final sweep = e.value / total * 2 * math.pi;
      if (angle >= acc && angle < acc + sweep) {
        setState(() => _selected = _selected == e.key ? null : e.key);
        return;
      }
      acc += sweep;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.data.values.fold<int>(0, (a, b) => a + b);
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.3,
          child: LayoutBuilder(builder: (context, c) {
            final size = Size(c.maxWidth, c.maxHeight);
            return GestureDetector(
              onTapUp: (d) => _onTap(d.localPosition, size),
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => CustomPaint(
                  size: size,
                  painter: _DonutPainter(
                    data: widget.data,
                    progress: _anim.value,
                    selected: _selected,
                    centerTitle: _selected?.label ?? 'Total',
                    centerValue: _selected == null
                        ? total
                        : widget.data[_selected]!,
                    textColor: Theme.of(context).colorScheme.onSurface,
                    trackColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final e in widget.data.entries)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: e.key.color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(e.key.label, style: const TextStyle(fontSize: 12)),
              ]),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Map<ExpenseCategory, int> data;
  final double progress; // 0..1 sweep animation
  final ExpenseCategory? selected;
  final String centerTitle;
  final int centerValue;
  final Color textColor;
  final Color trackColor;

  _DonutPainter({
    required this.data,
    required this.progress,
    required this.selected,
    required this.centerTitle,
    required this.centerValue,
    required this.textColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = math.min(size.width, size.height) / 2 - 8;
    final stroke = outer * 0.38;
    final rect = Rect.fromCircle(center: center, radius: outer - stroke / 2);
    final total = data.values.fold<int>(0, (a, b) => a + b);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    if (total > 0) {
      var start = -math.pi / 2;
      var consumed = 0.0; // angle already used by previous slices
      final revealed = progress * 2 * math.pi; // clockwise reveal
      const gap = 0.02;
      for (final e in data.entries) {
        if (e.value == 0) continue;
        final fullSweep = e.value / total * 2 * math.pi;
        final sweep = (revealed - consumed)
	    .clamp(0.0, math.max(0.0, fullSweep - gap))
	    .toDouble();    
    consumed += fullSweep;
        final isSel = selected == e.key;
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSel ? stroke + 10 : stroke
          ..strokeCap = StrokeCap.butt
          ..color = e.key.color
              .withValues(alpha: selected == null || isSel ? 1 : 0.35);
        canvas.drawArc(rect, start + gap / 2, sweep, false, p);
        start += fullSweep;
      }
    }

    // Center labels.
    _text(canvas, centerTitle, center.translate(0, -16), 12,
        textColor.withValues(alpha: 0.6), FontWeight.w500);
    _text(canvas, _fmt(centerValue), center.translate(0, 6), 18, textColor,
        FontWeight.w700);
    if (total > 0 && selected != null) {
      final pct = (centerValue / total * 100).toStringAsFixed(1);
      _text(canvas, '$pct%', center.translate(0, 28), 12,
          selected!.color, FontWeight.w600);
    }
  }

  void _text(Canvas c, String s, Offset center, double fs, Color col,
      FontWeight w) {
    final tp = TextPainter(
      text: TextSpan(
          text: s, style: TextStyle(fontSize: fs, color: col, fontWeight: w)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  static String _fmt(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return '$b đ';
  }

  @override
  bool shouldRepaint(covariant _DonutPainter o) =>
      o.progress != progress ||
      o.selected != selected ||
      o.data != data ||
      o.centerValue != centerValue;
}
