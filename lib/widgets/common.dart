import 'dart:io';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../screens/cart_screen.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    this.imagenPath,
    this.icono,
    this.size,
    this.radius = 16,
    this.heroTag,
  });

  final String? imagenPath;
  final String? icono;
  final double? size;
  final double radius;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final path = imagenPath;
    final tieneFoto = path != null && File(path).existsSync();

    Widget child = tieneFoto
        ? Image.file(File(path), fit: BoxFit.cover, width: size, height: size)
        : Container(
            width: size,
            height: size,
            color: Pal.card2,
            alignment: Alignment.center,
            child:
                Icon(iconoDe(icono), size: (size ?? 80) * 0.5, color: Pal.cyan),
          );
    if (size == null) child = SizedBox.expand(child: child);

    Widget w =
        ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
    if (heroTag != null) w = Hero(tag: heroTag!, child: w);
    return w;
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.estado, {super.key});
  final EstadoProducto estado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: estado.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(estado.icon, size: 14, color: estado.color),
        const SizedBox(width: 4),
        Text(estado.label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: estado.color)),
      ]),
    );
  }
}

class CartAction extends StatelessWidget {
  const CartAction({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final n = AppState.instance.carrito.length;
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: badges.Badge(
            showBadge: n > 0,
            position: badges.BadgePosition.topEnd(top: -6, end: -4),
            badgeStyle: const badges.BadgeStyle(badgeColor: Pal.magenta),
            badgeContent: Text('$n',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            child: CircleIconButton(
              icon: Icons.shopping_cart_outlined,
              tooltip: 'Lista de compras',
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const CartScreen())),
            ),
          ),
        );
      },
    );
  }
}

class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      validator: (_) =>
          required && value == null ? 'Selecciona una fecha' : null,
      builder: (st) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now().add(const Duration(days: 30)),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (d != null) {
            st.didChange(d);
            onChanged(d);
          }
        },
        child: InputDecorator(
          decoration:
              deco(label, icon: Icons.event).copyWith(errorText: st.errorText),
          child: Text(value == null ? 'Seleccionar fecha' : fmtFecha(value!)),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(
      {super.key, required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 72, color: t.colorScheme.outline),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center, style: t.textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!,
                textAlign: TextAlign.center,
                style: t.textTheme.bodyMedium
                    ?.copyWith(color: t.colorScheme.outline)),
          ],
        ]),
      ),
    );
  }
}
