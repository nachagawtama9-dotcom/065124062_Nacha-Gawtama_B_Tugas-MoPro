import 'package:hive_flutter/hive_flutter.dart';
import '../models/target_keuangan.dart';

class HiveService {
  static const String boxName = 'financial_goals_box';
  static final HiveService instance = HiveService._init();

  HiveService._init();

  Box? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(boxName);
    await _seedInitialGoals();
  }

  Box get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception("Hive Box belum diinisialisasi. Panggil init() terlebih dahulu.");
    }
    return _box!;
  }

  Future<void> _seedInitialGoals() async {
    if (box.isEmpty) {
      final initialGoals = [
        TargetKeuangan(
          id: 'goal_1',
          nama: 'Beli Laptop Baru',
          targetNominal: 12000000,
          terkumpulNominal: 4500000,
          deadline: '2026-12-31',
          catatan: 'Untuk kebutuhan kuliah & skripsi',
        ),
        TargetKeuangan(
          id: 'goal_2',
          nama: 'Dana Darurat 3 Bulan',
          targetNominal: 5000000,
          terkumpulNominal: 2800000,
          deadline: '2027-03-01',
          catatan: 'Disimpan di tabungan khusus',
        ),
        TargetKeuangan(
          id: 'goal_3',
          nama: 'Liburan Semesteran ke Bali',
          targetNominal: 2500000,
          terkumpulNominal: 900000,
          deadline: '2026-08-15',
          catatan: 'Tiket pesawat & penginapan',
        ),
      ];

      for (var goal in initialGoals) {
        await box.put(goal.id, goal.toMap());
      }
    }
  }

  // ==========================================
  // OPERASI CRUD HIVE (NoSQL Key-Value Box)
  // ==========================================

  /// [CREATE] Menambah target baru ke Hive Box menggunakan key ID
  Future<void> addTarget(TargetKeuangan target) async {
    await box.put(target.id, target.toMap());
  }

  /// [READ] Mengambil seluruh data target tabungan dari Hive Box
  List<TargetKeuangan> getAllTargets() {
    final List<TargetKeuangan> targets = [];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null && data is Map) {
        targets.add(TargetKeuangan.fromMap(data));
      }
    }
    return targets;
  }

  /// [UPDATE] Memperbarui data target di Hive
  Future<void> updateTarget(TargetKeuangan target) async {
    await box.put(target.id, target.toMap());
  }

  /// [UPDATE KHUSUS] Tambah setoran tabungan ke target tertentu
  Future<void> tambahTabungan(String id, double nominal) async {
    final data = box.get(id);
    if (data != null && data is Map) {
      final target = TargetKeuangan.fromMap(data);
      final updated = target.copyWith(
        terkumpulNominal: target.terkumpulNominal + nominal,
      );
      await box.put(id, updated.toMap());
    }
  }

  /// [DELETE] Menghapus target tabungan dari Hive Box
  Future<void> deleteTarget(String id) async {
    await box.delete(id);
  }

  // ==========================================
  // BENCHMARK UJI COBA (Poin 5)
  // ==========================================

  /// Benchmark insert sejumlah record ke Hive Box
  Future<int> benchmarkBatchInsert(int count) async {
    final benchmarkBox = await Hive.openBox('benchmark_temp_box');
    final stopwatch = Stopwatch()..start();

    final Map<String, dynamic> batchData = {};
    for (int i = 0; i < count; i++) {
      batchData['key_$i'] = {
        'id': 'bench_$i',
        'nama': 'Benchmark Item $i',
        'targetNominal': (i + 1) * 1000.0,
        'terkumpulNominal': 500.0,
        'deadline': '2026-11-01',
        'catatan': 'Data uji coba benchmark',
      };
    }
    await benchmarkBox.putAll(batchData);

    stopwatch.stop();

    // Bersihkan temporary box
    await benchmarkBox.clear();
    await benchmarkBox.close();

    return stopwatch.elapsedMilliseconds;
  }
}

