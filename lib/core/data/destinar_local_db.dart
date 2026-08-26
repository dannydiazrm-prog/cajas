// ============================================================================
// destinar_local_db.dart
//
// Base de datos SQLite TOTALMENTE INDEPENDIENTE del esquema principal.
// - No usa el schema versión 5 de data_master.dart
// - No sincroniza con Firestore
// - No modifica cantidadActual ni ninguna tabla existente (productos,
//   recepciones, retiros, ajustes, destinos, config)
// - Vive en su propio archivo .db, en su propia clase singleton
//
// Funciona en Android y Windows porque usa el mismo databaseFactory que ya
// está configurado en tu main.dart (sqflite_common_ffi para desktop).
// Si tu main.dart configura sqfliteFfiInit()/databaseFactoryFfi ANTES de
// abrir cualquier base, esta clase lo hereda automáticamente sin cambios.
// ============================================================================

import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DestinarApartado {
  final int? id;
  final String codigoProducto;
  final String nombreProducto;
  final String destino;
  final int cantidad;
  final String fecha; // ISO 8601 string

  DestinarApartado({
    this.id,
    required this.codigoProducto,
    required this.nombreProducto,
    required this.destino,
    required this.cantidad,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigoProducto': codigoProducto,
      'nombreProducto': nombreProducto,
      'destino': destino,
      'cantidad': cantidad,
      'fecha': fecha,
    };
  }

  factory DestinarApartado.fromMap(Map<String, dynamic> map) {
    return DestinarApartado(
      id: map['id'] as int?,
      codigoProducto: map['codigoProducto'] as String,
      nombreProducto: map['nombreProducto'] as String,
      destino: map['destino'] as String,
      cantidad: (map['cantidad'] as num).toInt(),
      fecha: map['fecha'] as String,
    );
  }
}

class DestinarLocalDb {
  DestinarLocalDb._internal();
  static final DestinarLocalDb instance = DestinarLocalDb._internal();

  static Database? _database;

  static const String _dbFileName = 'destinar_local.db';
  static const String _table = 'destinar_apartados';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath;

    if (Platform.isAndroid || Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      dbPath = join(directory.path, _dbFileName);
    } else {
      // Windows / desktop: misma carpeta de documentos de la app,
      // usando el databaseFactory ffi ya inicializado en main.dart.
      final directory = await getApplicationDocumentsDirectory();
      dbPath = join(directory.path, _dbFileName);
    }

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            codigoProducto TEXT NOT NULL,
            nombreProducto TEXT NOT NULL,
            destino TEXT NOT NULL,
            cantidad INTEGER NOT NULL,
            fecha TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Inserta un nuevo apartado. Devuelve el id generado.
  Future<int> insertarApartado(DestinarApartado apartado) async {
    final db = await database;
    return db.insert(_table, apartado.toMap()..remove('id'));
  }

  /// Devuelve todos los apartados, ordenados por producto y fecha.
  Future<List<DestinarApartado>> obtenerTodos() async {
    final db = await database;
    final result = await db.query(
      _table,
      orderBy: 'nombreProducto ASC, fecha DESC',
    );
    return result.map((m) => DestinarApartado.fromMap(m)).toList();
  }

  /// Devuelve los apartados de un código de producto específico.
  Future<List<DestinarApartado>> obtenerPorCodigo(String codigo) async {
    final db = await database;
    final result = await db.query(
      _table,
      where: 'codigoProducto = ?',
      whereArgs: [codigo],
      orderBy: 'fecha DESC',
    );
    return result.map((m) => DestinarApartado.fromMap(m)).toList();
  }

  /// Suma total apartada actualmente para un código de producto.
  /// Si se pasa [excluirId], ese registro no se cuenta en la suma
  /// (útil al editar un apartado existente, aunque hoy no se edita,
  /// solo se crea o se borra).
  Future<int> totalApartadoPorCodigo(String codigo, {int? excluirId}) async {
    final apartados = await obtenerPorCodigo(codigo);
    int total = 0;
    for (final a in apartados) {
      if (excluirId != null && a.id == excluirId) continue;
      total += a.cantidad;
    }
    return total;
  }

  /// Elimina un apartado por id (esto es lo que dispara el checkbox).
  /// Borra el registro por completo de la base local, sin dejar rastro
  /// y sin tocar Firestore ni el stock real.
  Future<void> eliminarApartado(int id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
