import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaksi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('catatan_keuangan.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    if (kIsWeb) {
      path = filePath;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        await _createDB(db, 1);
        await seedSampleDataIfEmpty(db);
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Skema Tabel SQFlite (IF NOT EXISTS untuk keamanan di browser Web)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        judul TEXT NOT NULL,
        nominal REAL NOT NULL,
        tipe TEXT NOT NULL,
        kategori TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        catatan TEXT
      )
    ''');
  }

  Future<void> seedSampleDataIfEmpty([Database? dbInstance]) async {
    final db = dbInstance ?? await database;
    try {
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM transaksi'));
      if (count == null || count == 0) {
        await seedSampleData(db);
      }
    } catch (_) {
      // Table might not exist yet, recreate
      await _createDB(db, 1);
      await seedSampleData(db);
    }
  }

  Future<void> seedSampleData([Database? dbInstance]) async {
    final db = dbInstance ?? await database;
    final now = DateTime.now();
    String fmt(DateTime d) =>
        "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

    final initialData = [
      {
        'judul': 'Gaji bulanan',
        'nominal': 4500000.0,
        'tipe': 'pemasukan',
        'kategori': 'Gaji',
        'tanggal': fmt(now.subtract(const Duration(days: 4))),
        'catatan': 'Gaji masuk',
      },
      {
        'judul': 'Buku kuliah',
        'nominal': 120000.0,
        'tipe': 'pengeluaran',
        'kategori': 'Pendidikan',
        'tanggal': fmt(now.subtract(const Duration(days: 2))),
        'catatan': 'Referensi praktikum',
      },
      {
        'judul': 'Ojek ke kampus',
        'nominal': 15000.0,
        'tipe': 'pengeluaran',
        'kategori': 'Transportasi',
        'tanggal': fmt(now.subtract(const Duration(days: 1))),
        'catatan': 'Transport harian',
      },
      {
        'judul': 'Kopi',
        'nominal': 22000.0,
        'tipe': 'pengeluaran',
        'kategori': 'Makanan',
        'tanggal': fmt(now),
        'catatan': 'Kopi susu',
      },
      {
        'judul': 'Makan siang',
        'nominal': 28000.0,
        'tipe': 'pengeluaran',
        'kategori': 'Makanan',
        'tanggal': fmt(now),
        'catatan': 'Nasi rames',
      },
      {
        'judul': 'Bensin motor',
        'nominal': 35000.0,
        'tipe': 'pengeluaran',
        'kategori': 'Transportasi',
        'tanggal': fmt(now),
        'catatan': 'Pertalite',
      },
    ];

    for (var item in initialData) {
      await db.insert('transaksi', item);
    }
  }

  // ==========================================
  // OPERASI CRUD (CREATE, READ, UPDATE, DELETE)
  // ==========================================

  /// [CREATE] Menambah transaksi baru ke tabel
  Future<int> insertTransaksi(Transaksi transaksi) async {
    final db = await database;
    return await db.insert(
      'transaksi',
      transaksi.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// [READ] Mengambil seluruh data transaksi diurutkan dari yang terbaru
  Future<List<Transaksi>> getAllTransaksi({String? filterKategori, String? searchQuery}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (filterKategori != null && filterKategori != 'Semua') {
      whereClause += 'kategori = ?';
      whereArgs.add(filterKategori);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'judul LIKE ?';
      whereArgs.add('%$searchQuery%');
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'transaksi',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'id DESC',
    );

    return maps.map((item) => Transaksi.fromMap(item)).toList();
  }

  /// [UPDATE] Mengubah data transaksi berdasarkan ID
  Future<int> updateTransaksi(Transaksi transaksi) async {
    final db = await database;
    return await db.update(
      'transaksi',
      transaksi.toMap(),
      where: 'id = ?',
      whereArgs: [transaksi.id],
    );
  }

  /// [DELETE] Menghapus data transaksi berdasarkan ID
  Future<int> deleteTransaksi(int id) async {
    final db = await database;
    return await db.delete(
      'transaksi',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // FUNGSI AGREGASI (Ringkasan Keuangan)
  // ==========================================

  Future<Map<String, double>> getSummary() async {
    final db = await database;
    final pemResult = await db.rawQuery(
      "SELECT SUM(nominal) as total FROM transaksi WHERE tipe = 'pemasukan'",
    );
    final pengResult = await db.rawQuery(
      "SELECT SUM(nominal) as total FROM transaksi WHERE tipe = 'pengeluaran'",
    );

    final totalPemasukan = (pemResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final totalPengeluaran = (pengResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final saldo = totalPemasukan - totalPengeluaran;

    return {
      'pemasukan': totalPemasukan,
      'pengeluaran': totalPengeluaran,
      'saldo': saldo,
    };
  }

  // ==========================================
  // BENCHMARK UJI COBA (Poin 5)
  // ==========================================

  /// Benchmark insert sejumlah record ke SQFlite (menggunakan Batch)
  Future<int> benchmarkBatchInsert(int count) async {
    final db = await database;
    final stopwatch = Stopwatch()..start();

    final batch = db.batch();
    for (int i = 0; i < count; i++) {
      batch.insert('transaksi', {
        'judul': 'Benchmark Item $i',
        'nominal': (i + 1) * 1000.0,
        'tipe': i % 2 == 0 ? 'pengeluaran' : 'pemasukan',
        'kategori': 'Lainnya',
        'tanggal': '2026-11-01',
        'catatan': 'Data uji coba benchmark',
      });
    }
    await batch.commit(noResult: true);

    stopwatch.stop();

    // Bersihkan kembali data benchmark
    await db.delete('transaksi', where: "judul LIKE 'Benchmark Item%'");

    return stopwatch.elapsedMilliseconds;
  }
}

