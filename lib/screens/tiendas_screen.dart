import 'package:flutter/material.dart';
import '../app_state.dart';
import '../db/database_helper.dart';
import '../models/models.dart';
import '../utils/helpers.dart';
import '../widgets/common.dart';

class TiendasScreen extends StatefulWidget {
  const TiendasScreen({super.key});

  @override
  State<TiendasScreen> createState() => _TiendasScreenState();
}

class _TiendasScreenState extends State<TiendasScreen> {
  late Future<List<TiendaResumen>> _f;

  @override
  void initState() {
    super.initState();
    _f = DatabaseHelper.instance.resumenTiendas();
  }

  void _recargar() =>
      setState(() => _f = DatabaseHelper.instance.resumenTiendas());

  Future<void> _editar([Tienda? t]) async {
    final nombre = TextEditingController(text: t?.nombre ?? '');
    final dir = TextEditingController(text: t?.direccion ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t == null ? 'Nueva tienda' : 'Editar tienda'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nombre,
            textCapitalization: TextCapitalization.words,
            decoration: deco('Nombre', icon: Icons.storefront),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dir,
            decoration:
                deco('Dirección (opcional)', icon: Icons.place_outlined),
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
    );
    if (ok != true || !mounted) return;
    if (nombre.text.trim().isEmpty) {
      snack(context, 'El nombre es obligatorio');
      return;
    }
    final err = await AppState.instance.guardarTienda(Tienda(
      id: t?.id,
      nombre: nombre.text.trim(),
      direccion: dir.text.trim().isEmpty ? null : dir.text.trim(),
    ));
    if (!mounted) return;
    if (err != null) snack(context, err);
    _recargar();
  }

  Future<void> _eliminar(Tienda t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar "${t.nombre}"?'),
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
    if (ok != true) return;
    final err = await AppState.instance.eliminarTienda(t.id!);
    if (!mounted) return;
    if (err != null) snack(context, err);
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tiendas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editar(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: FutureBuilder<List<TiendaResumen>>(
        future: _f,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final lista = snap.data!;
          return CustomScrollView(slivers: [
            if (lista.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(icon: Icons.storefront, title: 'Sin tiendas'),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList.separated(
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = lista[i];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading:
                            const CircleAvatar(child: Icon(Icons.storefront)),
                        title: Text(r.tienda.nombre),
                        subtitle: Text([
                          if (r.tienda.direccion != null) r.tienda.direccion!,
                          '${r.compras} compra${r.compras == 1 ? '' : 's'} · ${fmtMoneda(r.total)}',
                        ].join('\n')),
                        isThreeLine: r.tienda.direccion != null,
                        onTap: () => _editar(r.tienda),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _eliminar(r.tienda),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ]);
        },
      ),
    );
  }
}
