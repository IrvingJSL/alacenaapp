import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/common.dart';
import '../widgets/producto_tile.dart';

class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  String _q = '';
  int? _cat;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final s = AppState.instance;
        final lista = s.productos.where((p) {
          final okCat = _cat == null || p.categoriaId == _cat;
          final okQ =
              _q.isEmpty || p.nombre.toLowerCase().contains(_q.toLowerCase());
          return okCat && okQ;
        }).toList();

        return CustomScrollView(slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverToBoxAdapter(
              child: AppHeader(
                eyebrow: '${s.productos.length} artículos registrados',
                title: 'Inventario',
                actions: const [CartAction()],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                decoration: deco('Buscar artículo', icon: Icons.search),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: _cat == null,
                    onSelected: (_) => setState(() => _cat = null),
                  ),
                  for (final c in s.categorias)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        avatar: Icon(iconoDe(c.icono), size: 18),
                        label: Text(c.nombre),
                        selected: _cat == c.id,
                        onSelected: (_) =>
                            setState(() => _cat = _cat == c.id ? null : c.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (lista.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Sin artículos',
                subtitle: 'Agrega uno con el botón "Nuevo artículo".',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _GridCard(producto: lista[i]),
                  childCount: lista.length,
                ),
              ),
            ),
        ]);
      },
    );
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({required this.producto});
  final Producto producto;

  @override
  Widget build(BuildContext context) {
    final p = producto;
    final e = p.estado;
    final t = Theme.of(context);
    final tag = 'inv_${p.id}';
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: e.color.withValues(alpha: 0.55), width: 1.2),
      ),
      child: InkWell(
        onTap: () => abrirDetalle(context, p, tag),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              ProductImage(
                  imagenPath: p.imagenPath,
                  icono: p.categoriaIcono,
                  radius: 0,
                  heroTag: tag),
              Positioned(
                top: 8,
                left: 8,
                child: Material(
                  color: t.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  child: StatusChip(e),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text('${p.stockTotal} ${p.unidad} · ${textoCaducidad(p)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.bodySmall
                      ?.copyWith(color: t.colorScheme.outline)),
            ]),
          ),
        ]),
      ),
    );
  }
}
