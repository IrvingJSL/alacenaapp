import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

const Map<String, IconData> iconosCategoria = {
  'lacteos': Icons.egg_alt,
  'frutas': Icons.eco,
  'carnes': Icons.set_meal,
  'panaderia': Icons.bakery_dining,
  'bebidas': Icons.local_drink,
  'despensa': Icons.kitchen,
  'limpieza': Icons.cleaning_services,
  'higiene': Icons.clean_hands,
  'snacks': Icons.cookie,
  'comida': Icons.lunch_dining,
  'cafe': Icons.local_cafe,
  'medicina': Icons.medication,
  'mascotas': Icons.pets,
  'otros': Icons.category,
};

IconData iconoDe(String? key) => iconosCategoria[key] ?? Icons.category;

String fmtFecha(DateTime d) => DateFormat('dd MMM yyyy', 'es_MX').format(d);

String fmtFechaLarga(DateTime d) {
  final s = DateFormat("EEEE d 'de' MMMM 'de' yyyy", 'es_MX').format(d);
  return s[0].toUpperCase() + s.substring(1);
}

String fmtMoneda(double v) =>
    NumberFormat.currency(locale: 'es_MX', symbol: r'$').format(v);

InputDecoration deco(String label, {IconData? icon, String? hint}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon),
    filled: true,
    fillColor: Pal.card2,
    border: b(Pal.border),
    enabledBorder: b(Pal.border),
    focusedBorder: b(Pal.magenta, 1.5),
  );
}

void snack(BuildContext context, String msg) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
}

String textoDias(DateTime fecha) {
  final d = diasHasta(fecha);
  if (d < 0) return 'Caducó hace ${-d} día${d == -1 ? '' : 's'}';
  if (d == 0) return 'Caduca hoy';
  if (d == 1) return 'Caduca mañana';
  return 'Caduca en $d días';
}

String textoCaducidad(Producto p) {
  if (p.stockTotal == 0) return 'Sin existencia';
  return textoDias(p.proximaCaducidad!);
}

String fmtMonedaCorto(double v) =>
    NumberFormat.currency(locale: 'es_MX', symbol: r'$', decimalDigits: 0)
        .format(v);
