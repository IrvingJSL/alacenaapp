import 'package:flutter/material.dart';
import '../app_state.dart';
import '../db/database_helper.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/common.dart';
import '../widgets/compra_sheet.dart';
import '../widgets/producto_tile.dart';
import 'product_form_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen(
      {super.key, required this.productoId, this.heroTag});
  final int productoId;
  final String? heroTag;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<(List<TiendaResumen>, List<Compra>)> _traza;

  @override
  void initState() {
    super.initState();
    _traza = _cargarTraza();
  }

  Future<(List<TiendaResumen>, List<Compra>)> _cargarTraza() async {
    final db = DatabaseHelper.instance;
    final tiendas = await db.tiendasDeProducto(widget.productoId);
    final compras = await db.comprasDeProducto(widget.productoId);
    return (tiendas, compras);
  }

  void _recargarTraza() => setState(() => _traza = _cargarTraza());

  Future<void> _consumir(Producto p) async {
    final ctrl = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Consumir'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
              'Se descontará primero del lote con la caducidad más próxima (FEFO).'),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: deco('Cantidad (${p.unidad})',
                icon: Icons.remove_circle_outline),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Consumir')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final n = int.tryParse(ctrl.text) ?? 0;
    final exito = await AppState.instance.consumir(p, n);
    if (!mounted) return;
    if (!exito) {
      snack(context, 'Cantidad inválida o mayor al stock (${p.stockTotal}).');
    } else if (p.stockTotal - n <= 0) {
      snack(context, 'Se agotó: se agregó automáticamente al carrito.');
    } else {
      snack(context, 'Consumido: $n ${p.unidad}');
    }
  }

  Future<void> _comprar(Producto p) async {
    final ok = await showCompraSheet(context, p);
    if (ok) {
      _recargarTraza();
      if (mounted) snack(context, 'Compra registrada');
    }
  }

  Future<void> _editarLote(Producto p, Lote l) async {
    final ctrl = TextEditingController(text: '${l.cantidad}');
    DateTime fecha = l.fechaCaducidad;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Editar lote'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: deco('Cantidad', icon: Icons.numbers),
            ),
            const SizedBox(height: 12),
            DateField(
              label: 'Caducidad',
              value: fecha,
              onChanged: (d) => setD(() => fecha = d),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Guardar')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final n = int.tryParse(ctrl.text);
    if (n == null || n < 0) {
      snack(context, 'Cantidad inválida');
      return;
    }
    await AppState.instance.actualizarLote(l.id!, n, fecha);
  }

  Future<void> _eliminarLote(Lote l) async {
    final ok = await _confirmar('¿Eliminar este lote?',
        'Se quitarán ${l.cantidad} unidades del inventario.');
    if (ok) await AppState.instance.eliminarLote(l.id!);
  }

  Future<void> _eliminarProducto(Producto p) async {
    final ok = await _confirmar('¿Eliminar "${p.nombre}"?',
        'Se borrarán también sus lotes y su historial de compras.');
    if (!ok || !mounted) return;
    Navigator.pop(context);
    await AppState.instance.eliminarProducto(p.id!);
  }

  Future<bool> _confirmar(String titulo, String msg) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    return r ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final p = AppState.instance.porId(widget.productoId);
        if (p == null) return const Scaffold(body: SizedBox.shrink());
        final lotes = p.lotesActivos;
        final enCarrito = AppState.instance.enCarrito(p.id!);

        return Scaffold(
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: GradientButton(
                label: 'REGISTRAR COMPRA',
                icon: Icons.add_business,
                onPressed: () => _comprar(p),
              ),
            ),
          ),
          body: CustomScrollView(slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 280,
              backgroundColor: Pal.bg,
              leadingWidth: 60,
              leading: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Center(
                  child: CircleIconButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pop(context)),
                ),
              ),
              actions: [
                CircleIconButton(
                  tooltip: 'Editar',
                  icon: Icons.edit,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProductFormScreen(producto: p))),
                ),
                const SizedBox(width: 8),
                CircleIconButton(
                  tooltip: 'Eliminar',
                  icon: Icons.delete_outline,
                  onTap: () => _eliminarProducto(p),
                ),
                const SizedBox(width: 16),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: ClipPath(
                  clipper: _DiagonalClipper(),
                  child: Stack(fit: StackFit.expand, children: [
                    ProductImage(
                      imagenPath: p.imagenPath,
                      icono: p.categoriaIcono,
                      radius: 0,
                      heroTag: widget.heroTag,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Pal.cyan.withValues(alpha: 0.55),
                            Pal.blue.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nombre,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(
                          '${p.categoriaNombre ?? ''} · ${p.ultimaTiendaNombre ?? 'Sin compras'}',
                          style: const TextStyle(color: Pal.textDim)),
                      const SizedBox(height: 10),
                      Row(children: [
                        StatusChip(p.estado),
                        const SizedBox(width: 10),
                        const Icon(Icons.schedule, size: 16, color: Pal.amber),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(textoCaducidad(p),
                              style: const TextStyle(color: Colors.white70)),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Text(
                        p.alarmaActiva
                            ? 'Alarma activa: te avisamos ${p.diasAlerta} día(s) antes y el día que caduca. Al consumir se usa primero el lote que caduca antes (FEFO).'
                            : 'Alarma desactivada. Al consumir se usa primero el lote que caduca antes (FEFO).',
                        style: const TextStyle(color: Pal.textDim, height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      Row(children: [
                        Expanded(
                            child: StatBox(
                                label: 'Stock',
                                value: '${p.stockTotal} ${p.unidad}',
                                color: Pal.cyan)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatBox(
                                label: 'Mínimo',
                                value: '${p.stockMinimo}',
                                color: Pal.amber)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatBox(
                                label: 'Aviso',
                                value: '${p.diasAlerta} d',
                                color: Pal.magenta)),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed:
                                p.stockTotal > 0 ? () => _consumir(p) : null,
                            icon: const Icon(Icons.remove),
                            label: const Text('Consumir'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => agregarCarritoConAviso(context, p),
                            icon: Icon(
                                enCarrito
                                    ? Icons.check
                                    : Icons.add_shopping_cart,
                                color: enCarrito ? Pal.green : Colors.white),
                            label:
                                Text(enCarrito ? 'En carrito' : 'Al carrito'),
                          ),
                        ),
                      ]),
                    ]),
              ),
            ),
            const SliverToBoxAdapter(child: SectionTitle('Lotes (orden FEFO)')),
            if (lotes.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Sin lotes activos: el artículo está agotado.',
                      style: TextStyle(color: Pal.textDim)),
                ),
              )
            else
              SliverList.builder(
                itemCount: lotes.length,
                itemBuilder: (_, i) {
                  final l = lotes[i];
                  final e = Evento(p, l).estado;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: e.color.withValues(alpha: 0.4)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: e.color.withValues(alpha: 0.18),
                          child: Icon(e.icon, color: e.color, size: 20),
                        ),
                        title: Text('${l.cantidad} ${p.unidad}'
                            '${i == 0 ? '  ·  sale primero' : ''}'),
                        subtitle: Text(
                            '${fmtFecha(l.fechaCaducidad)} · ${textoDias(l.fechaCaducidad)}',
                            style: const TextStyle(color: Pal.textDim)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) =>
                              v == 'e' ? _editarLote(p, l) : _eliminarLote(l),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'e', child: Text('Editar')),
                            PopupMenuItem(value: 'x', child: Text('Eliminar')),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SliverToBoxAdapter(child: SectionTitle('Trazabilidad')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: FutureBuilder<(List<TiendaResumen>, List<Compra>)>(
                  future: _traza,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final (tiendas, compras) = snap.data!;
                    return Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: Pal.border),
                      ),
                      child: Column(children: [
                        ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          leading:
                              const Icon(Icons.storefront, color: Pal.cyan),
                          title: Text(
                              'Tiendas donde se compró (${tiendas.length})'),
                          children: [
                            if (tiendas.isEmpty)
                              const ListTile(
                                  title:
                                      Text('Aún no hay compras registradas.')),
                            for (final r in tiendas)
                              ListTile(
                                title: Text(r.tienda.nombre),
                                subtitle: Text(
                                    '${r.compras} compra${r.compras == 1 ? '' : 's'} · última ${r.ultima == null ? '-' : fmtFecha(r.ultima!)}',
                                    style: const TextStyle(color: Pal.textDim)),
                                trailing: Text(fmtMoneda(r.total)),
                              ),
                          ],
                        ),
                        const Divider(height: 1, color: Pal.border),
                        ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          leading: const Icon(Icons.receipt_long,
                              color: Pal.magenta),
                          title:
                              Text('Historial de compras (${compras.length})'),
                          children: [
                            if (compras.isEmpty)
                              const ListTile(title: Text('Sin movimientos.')),
                            for (final c in compras)
                              ListTile(
                                title: Text(
                                    '${c.cantidad} ${p.unidad} en ${c.tiendaNombre}'),
                                subtitle: Text(fmtFecha(c.fecha),
                                    style: const TextStyle(color: Pal.textDim)),
                                trailing:
                                    Text(fmtMoneda(c.precio * c.cantidad)),
                              ),
                          ],
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height - 44)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
