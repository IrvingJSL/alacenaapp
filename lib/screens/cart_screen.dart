import 'package:flutter/material.dart';
import '../app_state.dart';
import '../utils/helpers.dart';
import '../widgets/common.dart';
import '../widgets/compra_sheet.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _vaciar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Vaciar la lista?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Vaciar')),
        ],
      ),
    );
    if (ok == true) await AppState.instance.vaciarCarrito();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final s = AppState.instance;
        final items = s.carrito;
        final t = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Lista de compras'),
            actions: [
              if (items.isNotEmpty)
                IconButton(
                  tooltip: 'Vaciar',
                  onPressed: () => _vaciar(context),
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
            ],
          ),
          body: CustomScrollView(slivers: [
            if (items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Tu lista está vacía',
                  subtitle:
                      'Agrega artículos desde la pantalla principal. Desliza para quitarlos.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final it = items[i];
                    return Dismissible(
                      key: ValueKey('cart_${it.productoId}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: t.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.delete_outline,
                            color: t.colorScheme.onErrorContainer),
                      ),
                      onDismissed: (_) {
                        s.quitarDelCarrito(it.productoId);
                        snack(context, '${it.nombre} quitado de la lista');
                      },
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(children: [
                            Row(children: [
                              ProductImage(
                                  imagenPath: it.imagenPath,
                                  icono: it.categoriaIcono,
                                  size: 56,
                                  radius: 12),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(it.nombre,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                onPressed: it.cantidad > 1
                                    ? () => s.cambiarCantidadCarrito(
                                        it.productoId, it.cantidad - 1)
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('${it.cantidad}',
                                  style: t.textTheme.titleMedium),
                              IconButton(
                                onPressed: () => s.cambiarCantidadCarrito(
                                    it.productoId, it.cantidad + 1),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ]),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  final p = s.porId(it.productoId);
                                  if (p != null) {
                                    showCompraSheet(context, p,
                                        cantidadInicial: it.cantidad);
                                  }
                                },
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Ya lo compré'),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ]),
        );
      },
    );
  }
}
