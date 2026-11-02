import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tugas_sqflite/database/db_helper.dart';
import 'package:tugas_sqflite/models/transaksi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Test insert and get transactions', () async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.seedSampleDataIfEmpty();
    final initialList = await dbHelper.getAllTransaksi();

    final newTx = Transaksi(
      judul: 'Test Transaksi Baru',
      nominal: 50000,
      tipe: 'pengeluaran',
      kategori: 'Makanan',
      tanggal: '2026-11-01',
      catatan: 'Testing',
    );

    final id = await dbHelper.insertTransaksi(newTx);
    expect(id, isPositive);

    final updatedList = await dbHelper.getAllTransaksi();
    expect(updatedList.length, initialList.length + 1);
  });
}
