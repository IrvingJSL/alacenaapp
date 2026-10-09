import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'day_detail_screen.dart';

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;
  CalendarFormat _format = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        return CustomScrollView(slivers: [
          const SliverSafeArea(
            bottom: false,
            sliver: SliverToBoxAdapter(
              child: AppHeader(
                eyebrow: 'Caducidades',
                title: 'Calendario',
                actions: [CartAction()],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedButton<CalendarFormat>(
                segments: const [
                  ButtonSegment(
                      value: CalendarFormat.month,
                      label: Text('Mes'),
                      icon: Icon(Icons.calendar_view_month)),
                  ButtonSegment(
                      value: CalendarFormat.twoWeeks,
                      label: Text('2 sem'),
                      icon: Icon(Icons.view_week)),
                  ButtonSegment(
                      value: CalendarFormat.week,
                      label: Text('Semana'),
                      icon: Icon(Icons.view_day)),
                ],
                selected: {_format},
                onSelectionChanged: (v) => setState(() => _format = v.first),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: const BorderSide(color: Pal.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar<Evento>(
                    locale: 'es_MX',
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2100, 12, 31),
                    focusedDay: _focused,
                    calendarFormat: _format,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    headerStyle: const HeaderStyle(
                        formatButtonVisible: false, titleCentered: true),
                    selectedDayPredicate: (d) => isSameDay(_selected, d),
                    eventLoader: AppState.instance.eventosDelDia,
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                          color: Pal.blue.withValues(alpha: 0.45),
                          shape: BoxShape.circle),
                      selectedDecoration: const BoxDecoration(
                          gradient: Pal.gradPrimary, shape: BoxShape.circle),
                      outsideTextStyle: const TextStyle(color: Pal.textDim),
                      weekendTextStyle: const TextStyle(color: Pal.cyan),
                    ),
                    onPageChanged: (d) => _focused = d,
                    onDaySelected: (sel, foc) {
                      setState(() {
                        _selected = sel;
                        _focused = foc;
                      });
                      Navigator.of(context).push(MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => DayDetailScreen(dia: sel),
                      ));
                    },
                    calendarBuilders: CalendarBuilders<Evento>(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return null;
                        return Positioned(
                          bottom: 3,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            for (final e in events.take(8))
                              Container(
                                width: 6,
                                height: 6,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: e.estado.color),
                              ),
                          ]),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(spacing: 16, runSpacing: 6, children: [
                for (final e in [
                  EstadoProducto.caducado,
                  EstadoProducto.porCaducar,
                  EstadoProducto.ok
                ])
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.circle, size: 10, color: e.color),
                    const SizedBox(width: 6),
                    Text(e.label, style: Theme.of(context).textTheme.bodySmall),
                  ]),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Text(
                'Cada punto es un lote que caduca ese día. Toca un día para ver el detalle.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.outline),
              ),
            ),
          ),
        ]);
      },
    );
  }
}
