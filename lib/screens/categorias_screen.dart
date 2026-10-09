import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../utils/helpers.dart';
import '../widgets/common.dart';

class CategoriasScreen extends StatelessWidget {
  const CategoriasScreen({super.key});

  Future<void> _editar(BuildContext context, [Categoria? c]) async {
    final nombre = TextEditingController(text: c?.nombre ?? '');
    String icono = c?.icono ?? 'despensa';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(c == null ? 'Nueva categoría' : 'Editar categoría'),
          content: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nombre,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: deco('Nombre'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Ícono'),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final e in iconosCategoria.entries)
                      ChoiceChip(
                        label: Icon(e.value, size: 20),
                        selected: icono == e.key,
                        onSelected: (_) => setD(() => icono = e.key),
                      ),
                  ]),
                ]),
          ),
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
    if (ok != true || !context.mounted) return;
    if (nombre.text.trim().isEmpty) {
      snack(context, 'El nombre es obligatorio');
      return;
    }
    final err = await AppState.instance.guardarCategoria(
        Categoria(id: c?.id, nombre: nombre.text.trim(), icono: icono));
    if (err != null && context.mounted) snack(context, err);
  }

  Future<void> _eliminar(BuildContext context, Categoria c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar "${c.nombre}"?'),
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
    final err = await AppState.instance.eliminarCategoria(c.id!);
    if (err != null && context.mounted) snack(context, err);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final s = AppState.instance;
        return Scaffold(
          appBar: AppBar(title: const Text('Categorías')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _editar(context),
            icon: const Icon(Icons.add),
            label: const Text('Nueva'),
          ),
          body: CustomScrollView(slivers: [
            if (s.categorias.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                    icon: Icons.category_outlined, title: 'Sin categorías'),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList.separated(
                  itemCount: s.categorias.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final c = s.categorias[i];
                    final n =
                        s.productos.where((p) => p.categoriaId == c.id).length;
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(iconoDe(c.icono))),
                        title: Text(c.nombre),
                        subtitle: Text('$n artículo${n == 1 ? '' : 's'}'),
                        onTap: () => _editar(context, c),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _eliminar(context, c),
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
