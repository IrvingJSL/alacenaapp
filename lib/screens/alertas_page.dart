import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/producto_tile.dart';
import 'day_detail_screen.dart';
import 'tendencias_screen.dart';

class AlertasPage extends StatefulWidget {
  const AlertasPage({super.key});

  @override
  State<AlertasPage> createState() => _AlertasPageState();
}

class _AlertasPageState extends State<AlertasPage> {
  EstadoProducto? _filtro;

  void _abrirHoy() => Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => DayDetailScreen(dia: DateTime.now()),
      ));

  void _abrirTendencias() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const TendenciasScreen()));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final s = AppState.instance;
        final todas = s.alertas;
        final lista = _filtro == null
            ? todas
            : todas.where((p) => p.estado == _filtro).toList();
        final hoy = s.eventosDelDia(DateTime.now()).length;

        return CustomScrollView(slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverToBoxAdapter(
              child: AppHeader(
                eyebrow: 'Bienvenido de nuevo',
                title: 'Mi Alacena',
                actions: [
                  CircleIconButton(
                    icon: Icons.insights,
                    tooltip: 'Tendencias',
                    onTap: _abrirTendencias,
                  ),
                  const CartAction(),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: hoy > 0
                  ? HeroCard(
                      title: 'HOY CADUCAN $hoy',
                      subtitle:
                          'Lote${hoy == 1 ? '' : 's'} con alarma activa hoy',
                      buttonLabel: 'VER AHORA',
                      onPressed: _abrirHoy,
                    )
                  : HeroCard(
                      title:
                          '${todas.length} ALERTA${todas.length == 1 ? '' : 'S'}',
                      subtitle:
                          'Nada caduca hoy · revisa tu tendencia de compras',
                      buttonLabel: 'VER TENDENCIAS',
                      onPressed: _abrirTendencias,
                    ),
            ),
          ),
          const SliverToBoxAdapter(child: SectionTitle('Filtrar por estado')),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  ChoiceChip(
                    label: Text('Todas (${todas.length})'),
                    selected: _filtro == null,
                    onSelected: (_) => setState(() => _filtro = null),
                  ),
                  for (final e in [
                    EstadoProducto.caducado,
                    EstadoProducto.agotado,
                    EstadoProducto.porCaducar,
                    EstadoProducto.porAgotarse,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        avatar: Icon(e.icon, size: 18, color: e.color),
                        label: Text('${e.label} (${s.conteo(e)})'),
                        selected: _filtro == e,
                        onSelected: (_) =>
                            setState(() => _filtro = _filtro == e ? null : e),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SectionTitle('Requieren atención')),
          if (lista.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.verified_outlined,
                title: '¡Todo en orden!',
                subtitle: 'No hay artículos por caducar ni por agotarse.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              sliver: SliverList.separated(
                itemCount: lista.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => ProductoTile(
                  producto: lista[i],
                  heroTag: 'alerta_${lista[i].id}',
                ),
              ),
            ),
        ]);
      },
    );
  }
}
