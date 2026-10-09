import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../screens/product_detail_screen.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import 'common.dart';

void abrirDetalle(BuildContext context, Producto p, [String? heroTag]) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => ProductDetailScreen(productoId: p.id!, heroTag: heroTag),
  ));
}

Future<void> agregarCarritoConAviso(BuildContext context, Producto p) async {
  final s = AppState.instance;
  if (s.enCarrito(p.id!)) {
    snack(context, 'Ya está en tu lista de compras');
    return;
  }
  await s.agregarAlCarrito(p);
  if (context.mounted) snack(context, '${p.nombre} agregado al carrito');
}

class ProductoTile extends StatelessWidget {
  const ProductoTile({super.key, required this.producto, this.heroTag});
  final Producto producto;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final p = producto;
    final e = p.estado;
    final enCarrito = AppState.instance.enCarrito(p.id!);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: e.color.withValues(alpha: 0.55), width: 1.2),
      ),
      child: InkWell(
        onTap: () => abrirDetalle(context, p, heroTag),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            ProductImage(
              imagenPath: p.imagenPath,
              icono: p.categoriaIcono,
              size: 68,
              radius: 14,
              heroTag: heroTag,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('${p.categoriaNombre ?? ''} · ${textoCaducidad(p)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Pal.textDim, fontSize: 12)),
                    const SizedBox(height: 6),
                    StatusChip(e),
                  ]),
            ),
            const SizedBox(width: 8),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Pal.card2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Pal.border),
                ),
                child: Text('${p.stockTotal} ${p.unidad}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const SizedBox(height: 8),
              CircleIconButton(
                size: 38,
                tooltip: enCarrito ? 'En el carrito' : 'Agregar al carrito',
                icon: enCarrito ? Icons.check : Icons.add_shopping_cart,
                color: enCarrito ? Pal.green : Colors.white,
                onTap: () => agregarCarritoConAviso(context, p),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
