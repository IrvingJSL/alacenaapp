import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../utils/helpers.dart';
import '../theme/app_theme.dart';
import 'common.dart';

Future<bool> showCompraSheet(BuildContext context, Producto producto,
    {int cantidadInicial = 1}) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _CompraForm(producto: producto, cantidadInicial: cantidadInicial),
    ),
  );
  return r ?? false;
}

class _CompraForm extends StatefulWidget {
  const _CompraForm({required this.producto, required this.cantidadInicial});
  final Producto producto;
  final int cantidadInicial;

  @override
  State<_CompraForm> createState() => _CompraFormState();
}

class _CompraFormState extends State<_CompraForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _cant;
  final _precio = TextEditingController(text: '0');
  DateTime? _cad;
  int? _tienda;

  @override
  void initState() {
    super.initState();
    _cant = TextEditingController(text: '${widget.cantidadInicial}');
    final tiendas = AppState.instance.tiendas;
    _tienda = widget.producto.ultimaTiendaId ??
        (tiendas.isNotEmpty ? tiendas.first.id : null);
  }

  @override
  void dispose() {
    _cant.dispose();
    _precio.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_key.currentState!.validate()) return;
    await AppState.instance.registrarCompra(
      productoId: widget.producto.id!,
      tiendaId: _tienda!,
      cantidad: int.parse(_cant.text),
      precio: double.tryParse(_precio.text.replaceAll(',', '.')) ?? 0,
      caducidad: _cad!,
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final tiendas = AppState.instance.tiendas;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Form(
        key: _key,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Registrar compra',
              style: Theme.of(context).textTheme.titleLarge),
          Text(widget.producto.nombre,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          if (tiendas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Primero registra una tienda en Más → Tiendas.'),
            )
          else
            DropdownButtonFormField<int>(
              initialValue: _tienda,
              decoration: deco('Tienda', icon: Icons.storefront),
              items: [
                for (final t in tiendas)
                  DropdownMenuItem(value: t.id, child: Text(t.nombre)),
              ],
              onChanged: (v) => setState(() => _tienda = v),
              validator: (v) => v == null ? 'Selecciona la tienda' : null,
            ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _cant,
                keyboardType: TextInputType.number,
                decoration: deco('Cantidad', icon: Icons.numbers),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n <= 0) ? 'Mayor a 0' : null;
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
                  final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                  return (n == null || n < 0) ? 'Inválido' : null;
                },
              ),
            ),
          ]),
          const SizedBox(height: 12),
          DateField(
            label: 'Fecha de caducidad',
            value: _cad,
            required: true,
            onChanged: (d) => setState(() => _cad = d),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'GUARDAR COMPRA',
            icon: Icons.check,
            onPressed: tiendas.isEmpty ? null : _guardar,
          ),
        ]),
      ),
    );
  }
}
