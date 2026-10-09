import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/common.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.producto});
  final Producto? producto;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  static const _unidades = ['pzas', 'kg', 'g', 'L', 'ml', 'paq', 'latas'];

  final _key = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _min;
  late final TextEditingController _dias;
  final _cant = TextEditingController(text: '0');
  final _precio = TextEditingController(text: '0');
  int? _cat;
  String _unidad = 'pzas';
  String? _imagen;
  bool _alarma = true;
  DateTime? _cad;
  int? _tienda;
  bool _guardando = false;

  bool get _editando => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final prod = widget.producto;
    final s = AppState.instance;
    _nombre = TextEditingController(text: prod?.nombre ?? '');
    _min = TextEditingController(text: '${prod?.stockMinimo ?? 1}');
    _dias = TextEditingController(text: '${prod?.diasAlerta ?? 3}');
    _cat = prod?.categoriaId ??
        (s.categorias.isNotEmpty ? s.categorias.first.id : null);
    _unidad = prod?.unidad ?? 'pzas';
    _imagen = prod?.imagenPath;
    _alarma = prod?.alarmaActiva ?? true;
    _tienda = s.tiendas.isNotEmpty ? s.tiendas.first.id : null;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _min.dispose();
    _dias.dispose();
    _cant.dispose();
    _precio.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto(ImageSource fuente) async {
    try {
      final x = await ImagePicker()
          .pickImage(source: fuente, maxWidth: 1024, imageQuality: 80);
      if (x == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final destino =
          '${dir.path}/img_${DateTime.now().millisecondsSinceEpoch}${p.extension(x.path)}';
      await File(x.path).copy(destino);
      if (mounted) setState(() => _imagen = destino);
    } catch (e) {
      if (mounted) snack(context, 'No se pudo obtener la imagen');
    }
  }

  void _menuFoto() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Tomar foto'),
            onTap: () {
              Navigator.pop(ctx);
              _elegirFoto(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Elegir de la galería'),
            onTap: () {
              Navigator.pop(ctx);
              _elegirFoto(ImageSource.gallery);
            },
          ),
          if (_imagen != null)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Quitar foto'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _imagen = null);
              },
            ),
        ]),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_key.currentState!.validate()) return;
    if (_cat == null) {
      snack(context, 'Crea primero una categoría (Más → Categorías)');
      return;
    }
    setState(() => _guardando = true);
    final s = AppState.instance;
    final original = widget.producto;
    final prod = Producto(
      id: original?.id,
      nombre: _nombre.text.trim(),
      categoriaId: _cat!,
      imagenPath: _imagen,
      unidad: _unidad,
      stockMinimo: int.parse(_min.text),
      ultimaTiendaId: original?.ultimaTiendaId,
      diasAlerta: int.parse(_dias.text),
      alarmaActiva: _alarma,
    );
    final id = await s.guardarProducto(prod);
    final cant = int.tryParse(_cant.text) ?? 0;
    if (!_editando && cant > 0) {
      await s.registrarCompra(
        productoId: id,
        tiendaId: _tienda!,
        cantidad: cant,
        precio: double.tryParse(_precio.text.replaceAll(',', '.')) ?? 0,
        caducidad: _cad!,
      );
    }
    if (mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final cs = Theme.of(context).colorScheme;
    final iconoCat =
        s.categorias.where((c) => c.id == _cat).map((c) => c.icono).firstOrNull;
    final conExistencia = (int.tryParse(_cant.text) ?? 0) > 0;

    return Scaffold(
      appBar:
          AppBar(title: Text(_editando ? 'Editar artículo' : 'Nuevo artículo')),
      body: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _menuFoto,
                child: Stack(children: [
                  ProductImage(
                      imagenPath: _imagen,
                      icono: iconoCat,
                      size: 140,
                      radius: 28),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: cs.primary,
                      child: Icon(Icons.photo_camera,
                          size: 18, color: cs.onPrimary),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  deco('Nombre del artículo', icon: Icons.label_outline),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe un nombre' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _cat,
              decoration: deco('Categoría', icon: Icons.category_outlined),
              items: [
                for (final c in s.categorias)
                  DropdownMenuItem(
                    value: c.id,
                    child: Row(children: [
                      Icon(iconoDe(c.icono), size: 18),
                      const SizedBox(width: 8),
                      Text(c.nombre),
                    ]),
                  ),
              ],
              onChanged: (v) => setState(() => _cat = v),
              validator: (v) => v == null ? 'Selecciona una categoría' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _unidad,
                  decoration: deco('Unidad', icon: Icons.straighten),
                  items: [
                    for (final u in _unidades)
                      DropdownMenuItem(value: u, child: Text(u)),
                  ],
                  onChanged: (v) => setState(() => _unidad = v ?? 'pzas'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _min,
                  keyboardType: TextInputType.number,
                  decoration: deco('Stock mínimo', icon: Icons.trending_down),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return (n == null || n < 0) ? 'Número ≥ 0' : null;
                  },
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dias,
              keyboardType: TextInputType.number,
              decoration: deco('Avisar días antes de caducar',
                  icon: Icons.hourglass_bottom),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n < 0) ? 'Número ≥ 0' : null;
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Alarma de caducidad'),
              subtitle: const Text('Notificación local el día que caduca'),
              value: _alarma,
              onChanged: (v) => setState(() => _alarma = v),
            ),
            if (!_editando) ...[
              const Divider(height: 32),
              Text('Existencia inicial (opcional)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Crea el primer lote y registra la compra en el historial.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.outline)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _cant,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: deco('Cantidad', icon: Icons.numbers),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final n = int.tryParse(v);
                      return (n == null || n < 0) ? 'Número ≥ 0' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _precio,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: deco('Precio unit.', icon: Icons.attach_money),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final n = double.tryParse(v.replaceAll(',', '.'));
                      return (n == null || n < 0) ? 'Inválido' : null;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              DateField(
                label: 'Fecha de caducidad',
                value: _cad,
                required: conExistencia,
                onChanged: (d) => setState(() => _cad = d),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _tienda,
                decoration: deco('Tienda de compra', icon: Icons.storefront),
                items: [
                  for (final t in s.tiendas)
                    DropdownMenuItem(value: t.id, child: Text(t.nombre)),
                ],
                onChanged: (v) => setState(() => _tienda = v),
                validator: (v) =>
                    conExistencia && v == null ? 'Selecciona la tienda' : null,
              ),
            ],
            const SizedBox(height: 24),
            GradientButton(
              label: _editando ? 'GUARDAR CAMBIOS' : 'GUARDAR ARTÍCULO',
              icon: Icons.save,
              onPressed: _guardando ? null : _guardar,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
