import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/common.dart';
import 'categorias_screen.dart';
import 'day_detail_screen.dart';
import 'tendencias_screen.dart';
import 'tiendas_screen.dart';

class MasPage extends StatelessWidget {
  const MasPage({super.key});

  Widget _item(IconData icon, Color color, String titulo, String sub,
      VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Pal.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(titulo,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: Colors.white)),
        subtitle: Text(sub, style: const TextStyle(color: Pal.textDim)),
        trailing: const Icon(Icons.chevron_right, color: Pal.textDim),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return CustomScrollView(slivers: [
      const SliverSafeArea(
        bottom: false,
        sliver: SliverToBoxAdapter(
          child: AppHeader(
            eyebrow: 'Catálogos y ajustes',
            title: 'Más',
            actions: [CartAction()],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        sliver: SliverList.list(children: [
          _item(Icons.insights, Pal.cyan, 'Tendencias',
              'Gráfica de gasto y compras', () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TendenciasScreen()));
          }),
          _item(Icons.category_outlined, Pal.magenta, 'Categorías',
              '${s.categorias.length} registradas', () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriasScreen()));
          }),
          _item(Icons.storefront, Pal.blue, 'Tiendas',
              'Establecimientos y gasto por tienda', () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const TiendasScreen()));
          }),
          _item(Icons.today, Pal.amber, 'Caducan hoy',
              '${s.eventosDelDia(DateTime.now()).length} lote(s)', () {
            Navigator.of(context).push(MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => DayDetailScreen(dia: DateTime.now()),
            ));
          }),
          _item(Icons.alarm_add, Pal.green, 'Probar alarma',
              'Lanza una notificación local ahora', () async {
            final ok = await NotificationService.instance.probar();
            if (context.mounted) {
              snack(
                  context,
                  ok
                      ? 'Notificación enviada'
                      : 'Notificaciones no disponibles en esta plataforma');
            }
          }),
        ]),
      ),
    ]);
  }
}
