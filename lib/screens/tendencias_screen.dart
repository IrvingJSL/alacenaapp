import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../app_state.dart';
import '../db/database_helper.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

enum _Metrica { gasto, unidades }

enum _Periodo { meses, semanas }

typedef _Fila = ({DateTime fecha, int cantidad, double precio});

class TendenciasScreen extends StatefulWidget {
  const TendenciasScreen({super.key});

  @override
  State<TendenciasScreen> createState() => _TendenciasScreenState();
}

class _TendenciasScreenState extends State<TendenciasScreen> {
  _Metrica _m = _Metrica.gasto;
  _Periodo _p = _Periodo.meses;
  late Future<List<_Fila>> _f;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _f =
        DatabaseHelper.instance.comprasDesde(DateTime(now.year, now.month - 5));
  }

  double _valor(_Fila f) =>
      _m == _Metrica.gasto ? f.cantidad * f.precio : f.cantidad.toDouble();

  String _fmt(double v) =>
      _m == _Metrica.gasto ? fmtMonedaCorto(v) : v.round().toString();

  ({List<String> etiquetas, List<double> valores}) _agrupar(List<_Fila> filas) {
    final now = DateTime.now();
    final et = <String>[];
    if (_p == _Periodo.meses) {
      final ini = DateTime(now.year, now.month - 5);
      final vals = List<double>.filled(6, 0);
      for (var i = 0; i < 6; i++) {
        final t = DateFormat('MMM', 'es_MX')
            .format(DateTime(ini.year, ini.month + i));
        et.add(t[0].toUpperCase() + t.substring(1));
      }
      for (final f in filas) {
        final idx = (f.fecha.year - ini.year) * 12 + f.fecha.month - ini.month;
        if (idx >= 0 && idx < 6) vals[idx] += _valor(f);
      }
      return (etiquetas: et, valores: vals);
    }
    final lunes = soloFecha(now).subtract(Duration(days: now.weekday - 1));
    final ini = lunes.subtract(const Duration(days: 49));
    final vals = List<double>.filled(8, 0);
    for (var i = 0; i < 8; i++) {
      et.add(DateFormat('d/M').format(ini.add(Duration(days: 7 * i))));
    }
    for (final f in filas) {
      final d = soloFecha(f.fecha);
      final idx = DateTime.utc(d.year, d.month, d.day)
              .difference(DateTime.utc(ini.year, ini.month, ini.day))
              .inDays ~/
          7;
      if (idx >= 0 && idx < 8) vals[idx] += _valor(f);
    }
    return (etiquetas: et, valores: vals);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Tendencias')),
      body: FutureBuilder<List<_Fila>>(
        future: _f,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final g = _agrupar(snap.data!);
          final v = g.valores;
          final total = v.fold<double>(0, (a, b) => a + b);
          final prom = total / v.length;
          final maxV = v.reduce(math.max);
          final maxI = v.indexOf(maxV);
          final ult = v.last;
          final ant = v[v.length - 2];

          String insight;
          Color insightColor;
          IconData insightIcon;
          if (ult == 0 && ant == 0) {
            insight = 'Sin movimientos recientes';
            insightColor = Pal.textDim;
            insightIcon = Icons.horizontal_rule;
          } else if (ant == 0) {
            insight = 'Nuevo movimiento este periodo';
            insightColor = Pal.cyan;
            insightIcon = Icons.trending_up;
          } else {
            final pct = (ult - ant) / ant * 100;
            final sube = pct >= 0;
            insight =
                '${sube ? '+' : ''}${pct.toStringAsFixed(0)}% vs periodo anterior';
            insightColor = sube ? Pal.cyan : Pal.magenta;
            insightIcon = sube ? Icons.trending_up : Icons.trending_down;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              SegmentedButton<_Metrica>(
                segments: const [
                  ButtonSegment(
                      value: _Metrica.gasto,
                      label: Text('Gasto'),
                      icon: Icon(Icons.attach_money)),
                  ButtonSegment(
                      value: _Metrica.unidades,
                      label: Text('Unidades'),
                      icon: Icon(Icons.inventory_2_outlined)),
                ],
                selected: {_m},
                onSelectionChanged: (x) => setState(() => _m = x.first),
              ),
              const SizedBox(height: 10),
              SegmentedButton<_Periodo>(
                segments: const [
                  ButtonSegment(
                      value: _Periodo.meses,
                      label: Text('6 meses'),
                      icon: Icon(Icons.calendar_view_month)),
                  ButtonSegment(
                      value: _Periodo.semanas,
                      label: Text('8 semanas'),
                      icon: Icon(Icons.view_week)),
                ],
                selected: {_p},
                onSelectionChanged: (x) => setState(() => _p = x.first),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                    child: StatBox(
                        label: 'Total', value: _fmt(total), color: Pal.cyan)),
                const SizedBox(width: 10),
                Expanded(
                    child: StatBox(
                        label: 'Promedio',
                        value: _fmt(prom),
                        color: Pal.amber)),
                const SizedBox(width: 10),
                Expanded(
                    child: StatBox(
                        label: 'Pico',
                        value: maxV == 0 ? '-' : g.etiquetas[maxI],
                        color: Pal.magenta)),
              ]),
              const SectionTitleInline('Tendencia'),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                decoration: BoxDecoration(
                  color: Pal.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Pal.border),
                ),
                child: Column(children: [
                  SizedBox(
                    height: 220,
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey('${_m.name}_${_p.name}'),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, t, __) => CustomPaint(
                        size: Size.infinite,
                        painter: _LineChartPainter(
                          valores: v,
                          etiquetas: g.etiquetas,
                          progreso: t,
                          formato: _fmt,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(insightIcon, color: insightColor, size: 18),
                    const SizedBox(width: 6),
                    Text(insight,
                        style: TextStyle(
                            color: insightColor, fontWeight: FontWeight.w700)),
                  ]),
                ]),
              ),
              if (total == 0)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Aún no hay compras en este periodo. Registra una compra para ver tu tendencia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Pal.textDim),
                  ),
                ),
              const SectionTitleInline('Estado del inventario'),
              Row(children: [
                for (final e in [
                  EstadoProducto.caducado,
                  EstadoProducto.agotado,
                  EstadoProducto.porCaducar,
                  EstadoProducto.porAgotarse,
                ]) ...[
                  Expanded(
                      child: StatBox(
                          label: e.label,
                          value: '${s.conteo(e)}',
                          color: e.color)),
                  if (e != EstadoProducto.porAgotarse) const SizedBox(width: 8),
                ],
              ]),
            ],
          );
        },
      ),
    );
  }
}

class SectionTitleInline extends StatelessWidget {
  const SectionTitleInline(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      );
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.valores,
    required this.etiquetas,
    required this.progreso,
    required this.formato,
  });

  final List<double> valores;
  final List<String> etiquetas;
  final double progreso;
  final String Function(double) formato;

  void _texto(Canvas c, String t, Offset centro, TextStyle st, double minX,
      double maxX) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: st),
      textDirection: TextDirection.ltr,
    )..layout();
    final x = (centro.dx - tp.width / 2)
        .clamp(minX, math.max(minX, maxX - tp.width))
        .toDouble();
    tp.paint(c, Offset(x, centro.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const padX = 14.0, padTop = 28.0, padBottom = 26.0;
    final left = padX, right = size.width - padX;
    final top = padTop, bottom = size.height - padBottom;
    final w = right - left, h = bottom - top;
    final n = valores.length;
    final maxV = math.max(valores.reduce(math.max), 1.0) * 1.1;

    final grid = Paint()
      ..color = Pal.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = top + h * i / 3;
      for (double x = left; x < right; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, right), y), grid);
      }
    }

    final pts = <Offset>[
      for (var i = 0; i < n; i++)
        Offset(
          n > 1 ? left + w * i / (n - 1) : left + w / 2,
          bottom - (valores[i] / maxV) * h * progreso,
        ),
    ];

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < n; i++) {
      final cx = (pts[i - 1].dx + pts[i].dx) / 2;
      line.cubicTo(cx, pts[i - 1].dy, cx, pts[i].dy, pts[i].dx, pts[i].dy);
    }

    final area = Path.from(line)
      ..lineTo(pts.last.dx, bottom)
      ..lineTo(pts.first.dx, bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Pal.cyan.withValues(alpha: 0.4),
            Pal.cyan.withValues(alpha: 0.02)
          ],
        ).createShader(Rect.fromLTRB(left, top, right, bottom)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = Pal.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    for (final p in pts) {
      canvas.drawCircle(p, 3.5, Paint()..color = Pal.cyan);
    }

    final maxI = valores.indexOf(valores.reduce(math.max));
    if (valores[maxI] > 0) {
      final p = pts[maxI];
      canvas.drawCircle(p, 8, Paint()..color = Pal.cyan.withValues(alpha: 0.3));
      canvas.drawCircle(p, 5.5, Paint()..color = Colors.white);
      _texto(
        canvas,
        formato(valores[maxI]),
        Offset(p.dx, p.dy - 24),
        const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
        0,
        size.width,
      );
    }

    for (var i = 0; i < n; i++) {
      _texto(
        canvas,
        etiquetas[i],
        Offset(pts[i].dx, bottom + 8),
        const TextStyle(color: Pal.textDim, fontSize: 10),
        0,
        size.width,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.progreso != progreso ||
      old.valores != valores ||
      old.etiquetas != etiquetas;
}
