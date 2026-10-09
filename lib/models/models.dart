import 'package:flutter/material.dart';

DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

String isoFecha(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

int diasHasta(DateTime d) {
  final h = DateTime.now();
  return DateTime.utc(d.year, d.month, d.day)
      .difference(DateTime.utc(h.year, h.month, h.day))
      .inDays;
}

enum EstadoProducto { caducado, agotado, porCaducar, porAgotarse, ok }

extension EstadoProductoX on EstadoProducto {
  String get label => switch (this) {
        EstadoProducto.caducado => 'Caducado',
        EstadoProducto.agotado => 'Agotado',
        EstadoProducto.porCaducar => 'Por caducar',
        EstadoProducto.porAgotarse => 'Por agotarse',
        EstadoProducto.ok => 'Vigente',
      };

  Color get color => switch (this) {
        EstadoProducto.caducado => const Color(0xFFEF4444),
        EstadoProducto.agotado => const Color(0xFF94A3B8),
        EstadoProducto.porCaducar => const Color(0xFFF59E0B),
        EstadoProducto.porAgotarse => const Color(0xFFD946EF),
        EstadoProducto.ok => const Color(0xFF22C55E),
      };

  IconData get icon => switch (this) {
        EstadoProducto.caducado => Icons.event_busy,
        EstadoProducto.agotado => Icons.remove_shopping_cart,
        EstadoProducto.porCaducar => Icons.hourglass_bottom,
        EstadoProducto.porAgotarse => Icons.trending_down,
        EstadoProducto.ok => Icons.check_circle,
      };
}

class Categoria {
  final int? id;
  final String nombre;
  final String icono;
  const Categoria({this.id, required this.nombre, required this.icono});

  factory Categoria.fromMap(Map<String, Object?> m) => Categoria(
      id: m['id'] as int,
      nombre: m['nombre'] as String,
      icono: m['icono'] as String);
}

class Tienda {
  final int? id;
  final String nombre;
  final String? direccion;
  const Tienda({this.id, required this.nombre, this.direccion});

  factory Tienda.fromMap(Map<String, Object?> m) => Tienda(
      id: m['id'] as int,
      nombre: m['nombre'] as String,
      direccion: m['direccion'] as String?);
}

class Lote {
  final int? id;
  final int productoId;
  final int cantidad;
  final DateTime fechaCaducidad;
  final DateTime fechaIngreso;
  const Lote({
    this.id,
    required this.productoId,
    required this.cantidad,
    required this.fechaCaducidad,
    required this.fechaIngreso,
  });

  factory Lote.fromMap(Map<String, Object?> m) => Lote(
        id: m['id'] as int,
        productoId: m['producto_id'] as int,
        cantidad: m['cantidad'] as int,
        fechaCaducidad:
            soloFecha(DateTime.parse(m['fecha_caducidad'] as String)),
        fechaIngreso: DateTime.parse(m['fecha_ingreso'] as String),
      );
}

class Producto {
  final int? id;
  final String nombre;
  final int categoriaId;
  final String? categoriaNombre;
  final String? categoriaIcono;
  final String? imagenPath;
  final String unidad;
  final int stockMinimo;
  final int? ultimaTiendaId;
  final String? ultimaTiendaNombre;
  final int diasAlerta;

  final bool alarmaActiva;
  final List<Lote> lotes;

  const Producto({
    this.id,
    required this.nombre,
    required this.categoriaId,
    this.categoriaNombre,
    this.categoriaIcono,
    this.imagenPath,
    this.unidad = 'pzas',
    this.stockMinimo = 1,
    this.ultimaTiendaId,
    this.ultimaTiendaNombre,
    this.diasAlerta = 3,
    this.alarmaActiva = true,
    this.lotes = const [],
  });

  List<Lote> get lotesActivos => lotes.where((l) => l.cantidad > 0).toList();

  int get stockTotal => lotesActivos.fold(0, (s, l) => s + l.cantidad);

  DateTime? get proximaCaducidad {
    final a = lotesActivos;
    return a.isEmpty ? null : a.first.fechaCaducidad;
  }

  EstadoProducto get estado {
    if (stockTotal == 0) return EstadoProducto.agotado;
    final d = diasHasta(proximaCaducidad!);
    if (d < 0) return EstadoProducto.caducado;
    if (d <= diasAlerta) return EstadoProducto.porCaducar;
    if (stockTotal <= stockMinimo) return EstadoProducto.porAgotarse;
    return EstadoProducto.ok;
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'nombre': nombre.trim(),
        'categoria_id': categoriaId,
        'imagen_path': imagenPath,
        'unidad': unidad,
        'stock_minimo': stockMinimo,
        'ultima_tienda_id': ultimaTiendaId,
        'dias_alerta': diasAlerta,
        'alarma_activa': alarmaActiva ? 1 : 0,
      };

  factory Producto.fromMap(Map<String, Object?> m, List<Lote> lotes) =>
      Producto(
        id: m['id'] as int,
        nombre: m['nombre'] as String,
        categoriaId: m['categoria_id'] as int,
        categoriaNombre: m['categoria_nombre'] as String?,
        categoriaIcono: m['categoria_icono'] as String?,
        imagenPath: m['imagen_path'] as String?,
        unidad: m['unidad'] as String,
        stockMinimo: m['stock_minimo'] as int,
        ultimaTiendaId: m['ultima_tienda_id'] as int?,
        ultimaTiendaNombre: m['ultima_tienda_nombre'] as String?,
        diasAlerta: m['dias_alerta'] as int,
        alarmaActiva: (m['alarma_activa'] as int) == 1,
        lotes: lotes,
      );
}

class Evento {
  final Producto producto;
  final Lote lote;
  const Evento(this.producto, this.lote);

  EstadoProducto get estado {
    final d = diasHasta(lote.fechaCaducidad);
    if (d < 0) return EstadoProducto.caducado;
    if (d <= producto.diasAlerta) return EstadoProducto.porCaducar;
    return EstadoProducto.ok;
  }
}

class Compra {
  final int id;
  final int productoId;
  final int tiendaId;
  final String tiendaNombre;
  final int cantidad;
  final double precio;
  final DateTime fecha;
  const Compra({
    required this.id,
    required this.productoId,
    required this.tiendaId,
    required this.tiendaNombre,
    required this.cantidad,
    required this.precio,
    required this.fecha,
  });

  factory Compra.fromMap(Map<String, Object?> m) => Compra(
        id: m['id'] as int,
        productoId: m['producto_id'] as int,
        tiendaId: m['tienda_id'] as int,
        tiendaNombre: m['tienda_nombre'] as String,
        cantidad: m['cantidad'] as int,
        precio: (m['precio'] as num).toDouble(),
        fecha: DateTime.parse(m['fecha'] as String),
      );
}

class TiendaResumen {
  final Tienda tienda;
  final int compras;
  final double total;
  final DateTime? ultima;
  const TiendaResumen(this.tienda, this.compras, this.total, this.ultima);

  factory TiendaResumen.fromMap(Map<String, Object?> m) => TiendaResumen(
        Tienda.fromMap(m),
        (m['compras'] as num?)?.toInt() ?? 0,
        (m['total'] as num?)?.toDouble() ?? 0,
        m['ultima'] == null ? null : DateTime.parse(m['ultima'] as String),
      );
}

class ItemCarrito {
  final int productoId;
  final String nombre;
  final String? imagenPath;
  final String? categoriaIcono;
  final String unidad;
  final int cantidad;
  const ItemCarrito({
    required this.productoId,
    required this.nombre,
    this.imagenPath,
    this.categoriaIcono,
    required this.unidad,
    required this.cantidad,
  });

  factory ItemCarrito.fromMap(Map<String, Object?> m) => ItemCarrito(
        productoId: m['producto_id'] as int,
        nombre: m['nombre'] as String,
        imagenPath: m['imagen_path'] as String?,
        categoriaIcono: m['categoria_icono'] as String?,
        unidad: m['unidad'] as String,
        cantidad: m['cantidad'] as int,
      );
}
