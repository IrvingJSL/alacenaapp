import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'alacena.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (d) async => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database d, int version) async {
    await d.execute('''
      CREATE TABLE Categoria(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE CHECK(length(trim(nombre)) > 0),
        icono TEXT NOT NULL DEFAULT 'otros'
      )''');
    await d.execute('''
      CREATE TABLE Tienda(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE CHECK(length(trim(nombre)) > 0),
        direccion TEXT
      )''');
    await d.execute('''
      CREATE TABLE Producto(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL CHECK(length(trim(nombre)) > 0),
        categoria_id INTEGER NOT NULL
          REFERENCES Categoria(id) ON DELETE RESTRICT ON UPDATE CASCADE,
        imagen_path TEXT,
        unidad TEXT NOT NULL DEFAULT 'pzas',
        stock_minimo INTEGER NOT NULL DEFAULT 1 CHECK(stock_minimo >= 0),
        ultima_tienda_id INTEGER
          REFERENCES Tienda(id) ON DELETE SET NULL ON UPDATE CASCADE,
        dias_alerta INTEGER NOT NULL DEFAULT 3 CHECK(dias_alerta >= 0),
        alarma_activa INTEGER NOT NULL DEFAULT 1 CHECK(alarma_activa IN (0,1))
      )''');
    await d.execute('''
      CREATE TABLE Lote(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL
          REFERENCES Producto(id) ON DELETE CASCADE,
        cantidad INTEGER NOT NULL CHECK(cantidad >= 0),
        fecha_caducidad TEXT NOT NULL,
        fecha_ingreso TEXT NOT NULL
      )''');
    await d.execute('''
      CREATE TABLE Historial_Compras(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL
          REFERENCES Producto(id) ON DELETE CASCADE,
        tienda_id INTEGER NOT NULL
          REFERENCES Tienda(id) ON DELETE RESTRICT ON UPDATE CASCADE,
        cantidad INTEGER NOT NULL CHECK(cantidad > 0),
        precio REAL NOT NULL DEFAULT 0 CHECK(precio >= 0),
        fecha TEXT NOT NULL
      )''');
    await d.execute('''
      CREATE TABLE Carrito(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL UNIQUE
          REFERENCES Producto(id) ON DELETE CASCADE,
        cantidad INTEGER NOT NULL DEFAULT 1 CHECK(cantidad > 0)
      )''');
    await d.execute(
        'CREATE INDEX idx_lote_producto ON Lote(producto_id, fecha_caducidad)');

    await d.execute('''
      CREATE TRIGGER trg_ultima_tienda AFTER INSERT ON Historial_Compras
      BEGIN
        UPDATE Producto SET ultima_tienda_id = NEW.tienda_id
        WHERE id = NEW.producto_id;
      END''');

    const cats = [
      ('Lácteos y huevo', 'lacteos'),
      ('Frutas y verduras', 'frutas'),
      ('Carnes y pescado', 'carnes'),
      ('Panadería', 'panaderia'),
      ('Bebidas', 'bebidas'),
      ('Despensa', 'despensa'),
      ('Limpieza', 'limpieza'),
      ('Higiene personal', 'higiene'),
    ];
    for (final c in cats) {
      await d.insert('Categoria', {'nombre': c.$1, 'icono': c.$2});
    }
    for (final t in ['Walmart', 'Soriana', 'Mercado local']) {
      await d.insert('Tienda', {'nombre': t});
    }
  }

  Future<List<Categoria>> categorias() async {
    final d = await db;
    final r = await d.query('Categoria', orderBy: 'nombre COLLATE NOCASE');
    return r.map(Categoria.fromMap).toList();
  }

  Future<void> guardarCategoria(Categoria c) async {
    final d = await db;
    final m = {'nombre': c.nombre, 'icono': c.icono};
    if (c.id == null) {
      await d.insert('Categoria', m);
    } else {
      await d.update('Categoria', m, where: 'id = ?', whereArgs: [c.id]);
    }
  }

  Future<void> eliminarCategoria(int id) async {
    final d = await db;
    await d.delete('Categoria', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Tienda>> tiendas() async {
    final d = await db;
    final r = await d.query('Tienda', orderBy: 'nombre COLLATE NOCASE');
    return r.map(Tienda.fromMap).toList();
  }

  Future<void> guardarTienda(Tienda t) async {
    final d = await db;
    final m = {'nombre': t.nombre, 'direccion': t.direccion};
    if (t.id == null) {
      await d.insert('Tienda', m);
    } else {
      await d.update('Tienda', m, where: 'id = ?', whereArgs: [t.id]);
    }
  }

  Future<void> eliminarTienda(int id) async {
    final d = await db;
    await d.delete('Tienda', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TiendaResumen>> resumenTiendas() async {
    final d = await db;
    final r = await d.rawQuery('''
      SELECT t.id, t.nombre, t.direccion,
             COUNT(h.id) AS compras,
             COALESCE(SUM(h.cantidad * h.precio), 0) AS total,
             MAX(h.fecha) AS ultima
      FROM Tienda t LEFT JOIN Historial_Compras h ON h.tienda_id = t.id
      GROUP BY t.id
      ORDER BY t.nombre COLLATE NOCASE''');
    return r.map(TiendaResumen.fromMap).toList();
  }

  Future<List<TiendaResumen>> tiendasDeProducto(int productoId) async {
    final d = await db;
    final r = await d.rawQuery('''
      SELECT t.id, t.nombre, t.direccion,
             COUNT(h.id) AS compras,
             SUM(h.cantidad * h.precio) AS total,
             MAX(h.fecha) AS ultima
      FROM Historial_Compras h JOIN Tienda t ON t.id = h.tienda_id
      WHERE h.producto_id = ?
      GROUP BY t.id
      ORDER BY ultima DESC''', [productoId]);
    return r.map(TiendaResumen.fromMap).toList();
  }

  Future<List<Compra>> comprasDeProducto(int productoId) async {
    final d = await db;
    final r = await d.rawQuery('''
      SELECT h.*, t.nombre AS tienda_nombre
      FROM Historial_Compras h JOIN Tienda t ON t.id = h.tienda_id
      WHERE h.producto_id = ?
      ORDER BY h.fecha DESC''', [productoId]);
    return r.map(Compra.fromMap).toList();
  }

  Future<List<({DateTime fecha, int cantidad, double precio})>> comprasDesde(
      DateTime desde) async {
    final d = await db;
    final r = await d.rawQuery(
        'SELECT fecha, cantidad, precio FROM Historial_Compras WHERE fecha >= ? ORDER BY fecha',
        [desde.toIso8601String()]);
    return r
        .map((m) => (
              fecha: DateTime.parse(m['fecha'] as String),
              cantidad: m['cantidad'] as int,
              precio: (m['precio'] as num).toDouble(),
            ))
        .toList();
  }

  Future<List<Producto>> productos() async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT p.*, c.nombre AS categoria_nombre, c.icono AS categoria_icono,
             t.nombre AS ultima_tienda_nombre
      FROM Producto p
      JOIN Categoria c ON c.id = p.categoria_id
      LEFT JOIN Tienda t ON t.id = p.ultima_tienda_id
      ORDER BY p.nombre COLLATE NOCASE''');
    final lotesRows = await d.query('Lote',
        where: 'cantidad > 0', orderBy: 'fecha_caducidad ASC, id ASC');
    final porProducto = <int, List<Lote>>{};
    for (final l in lotesRows.map(Lote.fromMap)) {
      porProducto.putIfAbsent(l.productoId, () => []).add(l);
    }
    return rows
        .map((r) => Producto.fromMap(r, porProducto[r['id'] as int] ?? []))
        .toList();
  }

  Future<int> guardarProducto(Producto p) async {
    final d = await db;
    if (p.id == null) {
      final m = p.toMap()..remove('id');
      return d.insert('Producto', m);
    }
    await d.update('Producto', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
    return p.id!;
  }

  Future<void> eliminarProducto(int id) async {
    final d = await db;
    await d.delete('Producto', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> actualizarLote(int id, int cantidad, DateTime caducidad) async {
    final d = await db;
    await d.update(
        'Lote', {'cantidad': cantidad, 'fecha_caducidad': isoFecha(caducidad)},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> eliminarLote(int id) async {
    final d = await db;
    await d.delete('Lote', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> consumir(int productoId, int cantidad) async {
    final d = await db;
    return d.transaction<bool>((txn) async {
      final lotes = await txn.query('Lote',
          where: 'producto_id = ? AND cantidad > 0',
          whereArgs: [productoId],
          orderBy: 'fecha_caducidad ASC, id ASC');
      final total = lotes.fold<int>(0, (s, l) => s + (l['cantidad'] as int));
      if (cantidad <= 0 || cantidad > total) return false;
      var restante = cantidad;
      for (final l in lotes) {
        if (restante == 0) break;
        final disp = l['cantidad'] as int;
        final usar = disp < restante ? disp : restante;
        await txn.update('Lote', {'cantidad': disp - usar},
            where: 'id = ?', whereArgs: [l['id']]);
        restante -= usar;
      }
      return true;
    });
  }

  Future<void> registrarCompra({
    required int productoId,
    required int tiendaId,
    required int cantidad,
    required double precio,
    required DateTime caducidad,
  }) async {
    final d = await db;
    await d.transaction((txn) async {
      final ahora = DateTime.now().toIso8601String();
      await txn.insert('Lote', {
        'producto_id': productoId,
        'cantidad': cantidad,
        'fecha_caducidad': isoFecha(caducidad),
        'fecha_ingreso': ahora,
      });
      await txn.insert('Historial_Compras', {
        'producto_id': productoId,
        'tienda_id': tiendaId,
        'cantidad': cantidad,
        'precio': precio,
        'fecha': ahora,
      });
      await txn
          .delete('Carrito', where: 'producto_id = ?', whereArgs: [productoId]);
    });
  }

  Future<List<ItemCarrito>> carrito() async {
    final d = await db;
    final r = await d.rawQuery('''
      SELECT k.producto_id, k.cantidad, p.nombre, p.imagen_path, p.unidad,
             c.icono AS categoria_icono
      FROM Carrito k
      JOIN Producto p ON p.id = k.producto_id
      JOIN Categoria c ON c.id = p.categoria_id
      ORDER BY k.id DESC''');
    return r.map(ItemCarrito.fromMap).toList();
  }

  Future<void> agregarAlCarrito(int productoId, {int cantidad = 1}) async {
    final d = await db;
    await d.insert('Carrito', {'producto_id': productoId, 'cantidad': cantidad},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> cantidadCarrito(int productoId, int cantidad) async {
    final d = await db;
    await d.update('Carrito', {'cantidad': cantidad},
        where: 'producto_id = ?', whereArgs: [productoId]);
  }

  Future<void> quitarDelCarrito(int productoId) async {
    final d = await db;
    await d
        .delete('Carrito', where: 'producto_id = ?', whereArgs: [productoId]);
  }

  Future<void> vaciarCarrito() async {
    final d = await db;
    await d.delete('Carrito');
  }
}
