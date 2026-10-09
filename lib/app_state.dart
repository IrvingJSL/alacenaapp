import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' show DatabaseException;
import 'db/database_helper.dart';
import 'models/models.dart';
import 'services/notification_service.dart';

class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  bool cargando = true;
  List<Producto> productos = [];
  List<Categoria> categorias = [];
  List<Tienda> tiendas = [];
  List<ItemCarrito> carrito = [];
  final Map<String, List<Evento>> _eventos = {};

  Future<void> cargar() async {
    productos = await _db.productos();
    categorias = await _db.categorias();
    tiendas = await _db.tiendas();
    carrito = await _db.carrito();

    _eventos.clear();
    for (final p in productos) {
      for (final l in p.lotesActivos) {
        _eventos
            .putIfAbsent(isoFecha(l.fechaCaducidad), () => [])
            .add(Evento(p, l));
      }
    }
    cargando = false;
    notifyListeners();
    NotificationService.instance.reprogramar(productos);
  }

  Producto? porId(int id) {
    for (final p in productos) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool enCarrito(int productoId) =>
      carrito.any((c) => c.productoId == productoId);

  List<Evento> eventosDelDia(DateTime d) => _eventos[isoFecha(d)] ?? const [];

  int conteo(EstadoProducto e) => productos.where((p) => p.estado == e).length;

  List<Producto> get alertas {
    final l = productos.where((p) => p.estado != EstadoProducto.ok).toList();
    l.sort((a, b) {
      final c = a.estado.index.compareTo(b.estado.index);
      if (c != 0) return c;
      final da = a.proximaCaducidad;
      final dbb = b.proximaCaducidad;
      if (da == null || dbb == null) return a.nombre.compareTo(b.nombre);
      return da.compareTo(dbb);
    });
    return l;
  }

  Future<String?> guardarCategoria(Categoria c) async {
    try {
      await _db.guardarCategoria(c);
      await cargar();
      return null;
    } on DatabaseException {
      return 'Ya existe una categoría con ese nombre.';
    }
  }

  Future<String?> eliminarCategoria(int id) async {
    try {
      await _db.eliminarCategoria(id);
      await cargar();
      return null;
    } on DatabaseException {
      return 'No se puede eliminar: hay artículos en esta categoría.';
    }
  }

  Future<String?> guardarTienda(Tienda t) async {
    try {
      await _db.guardarTienda(t);
      await cargar();
      return null;
    } on DatabaseException {
      return 'Ya existe una tienda con ese nombre.';
    }
  }

  Future<String?> eliminarTienda(int id) async {
    try {
      await _db.eliminarTienda(id);
      await cargar();
      return null;
    } on DatabaseException {
      return 'No se puede eliminar: la tienda tiene compras registradas.';
    }
  }

  Future<int> guardarProducto(Producto p) async {
    final id = await _db.guardarProducto(p);
    await cargar();
    return id;
  }

  Future<void> eliminarProducto(int id) async {
    await _db.eliminarProducto(id);
    await cargar();
  }

  Future<bool> consumir(Producto p, int cantidad) async {
    final ok = await _db.consumir(p.id!, cantidad);
    if (ok) {
      if (p.stockTotal - cantidad <= 0) {
        await _db.agregarAlCarrito(p.id!);
      }
      await cargar();
    }
    return ok;
  }

  Future<void> registrarCompra({
    required int productoId,
    required int tiendaId,
    required int cantidad,
    required double precio,
    required DateTime caducidad,
  }) async {
    await _db.registrarCompra(
      productoId: productoId,
      tiendaId: tiendaId,
      cantidad: cantidad,
      precio: precio,
      caducidad: caducidad,
    );
    await cargar();
  }

  Future<void> actualizarLote(int id, int cantidad, DateTime caducidad) async {
    await _db.actualizarLote(id, cantidad, caducidad);
    await cargar();
  }

  Future<void> eliminarLote(int id) async {
    await _db.eliminarLote(id);
    await cargar();
  }

  Future<void> agregarAlCarrito(Producto p, {int cantidad = 1}) async {
    await _db.agregarAlCarrito(p.id!, cantidad: cantidad);
    await cargar();
  }

  Future<void> quitarDelCarrito(int productoId) async {
    carrito = carrito.where((c) => c.productoId != productoId).toList();
    notifyListeners();
    await _db.quitarDelCarrito(productoId);
    await cargar();
  }

  Future<void> cambiarCantidadCarrito(int productoId, int cantidad) async {
    if (cantidad < 1) return;
    await _db.cantidadCarrito(productoId, cantidad);
    await cargar();
  }

  Future<void> vaciarCarrito() async {
    await _db.vaciarCarrito();
    await cargar();
  }
}
