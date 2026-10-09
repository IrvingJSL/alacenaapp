import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../utils/helpers.dart';
import '../widgets/common.dart';
import '../widgets/producto_tile.dart';

class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({super.key, required this.dia});
  final DateTime dia;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final evs = AppState.instance.eventosDelDia(dia);
        final t = Theme.of(context);
        final productos = evs.map((e) => e.producto.id).toSet().length;

        return Scaffold(
          appBar: AppBar(
            leading: const CloseButton(),
            title: const Text('Alertas del día'),
            actions: const [CartAction(), SizedBox(width: 8)],
          ),
          body: CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fmtFechaLarga(dia),
                          style: t.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        evs.isEmpty
                            ? 'Sin lotes por caducar'
                            : '${evs.length} lote${evs.length == 1 ? '' : 's'} · $productos producto${productos == 1 ? '' : 's'}',
                        style: t.textTheme.bodyMedium
                            ?.copyWith(color: t.colorScheme.outline),
                      ),
                    ]),
              ),
            ),
            if (evs.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.event_available,
                  title: 'Nada caduca este día',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList.separated(
                  itemCount: evs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _EventoTile(evento: evs[i]),
                ),
              ),
          ]),
        );
      },
    );
  }
}

class _EventoTile extends StatelessWidget {
  const _EventoTile({required this.evento});
  final Evento evento;

  @override
  Widget build(BuildContext context) {
    final p = evento.producto;
    final l = evento.lote;
    final e = evento.estado;
    final t = Theme.of(context);
    final enCarrito = AppState.instance.enCarrito(p.id!);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: e.color.withValues(alpha: 0.45), width: 1.2),
      ),
      child: InkWell(
        onTap: () => abrirDetalle(context, p),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            ProductImage(
                imagenPath: p.imagenPath, icono: p.categoriaIcono, size: 72),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(p.categoriaNombre ?? '', style: t.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    StatusChip(e),
                    const SizedBox(height: 4),
                    Text(
                        'Lote: ${l.cantidad} ${p.unidad}  ·  Stock total: ${p.stockTotal}',
                        style: t.textTheme.bodySmall),
                    if (p.ultimaTiendaNombre != null)
                      Text('Última compra en ${p.ultimaTiendaNombre}',
                          style: t.textTheme.bodySmall
                              ?.copyWith(color: t.colorScheme.outline)),
                  ]),
            ),
            IconButton.filledTonal(
              tooltip: 'Agregar al carrito',
              onPressed: () => agregarCarritoConAviso(context, p),
              icon: Icon(enCarrito ? Icons.check : Icons.add_shopping_cart),
            ),
          ]),
        ),
      ),
    );
  }
}
