import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../services/hive_service.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _isBenchmarking = false;
  int? _sqfliteDurationMs;
  int? _hiveDurationMs;
  final int _benchmarkCount = 300;

  Future<void> _runBenchmark() async {
    setState(() {
      _isBenchmarking = true;
      _sqfliteDurationMs = null;
      _hiveDurationMs = null;
    });

    final sqfTime = await DatabaseHelper.instance.benchmarkBatchInsert(_benchmarkCount);
    final hiveTime = await HiveService.instance.benchmarkBatchInsert(_benchmarkCount);

    setState(() {
      _sqfliteDurationMs = sqfTime;
      _hiveDurationMs = hiveTime;
      _isBenchmarking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ringkasan Pengujian',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Perbandingan Kinerja SQFlite vs Hive NoSQL',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
              ),
              const SizedBox(height: 20),

              // Kartu Live Benchmark
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Uji Coba Kecepatan (Live Benchmark)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111111)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Menulis sekaligus $_benchmarkCount data ke storage lokal.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
                    ),
                    const SizedBox(height: 14),

                    if (_isBenchmarking)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(color: Color(0xFF111111)),
                        ),
                      )
                    else if (_sqfliteDurationMs != null && _hiveDurationMs != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SQFlite (Batch Insert):', style: TextStyle(fontSize: 13)),
                          Text(
                            '$_sqfliteDurationMs ms',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Hive (putAll NoSQL):', style: TextStyle(fontSize: 13)),
                          Text(
                            '$_hiveDurationMs ms',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _hiveDurationMs! <= _sqfliteDurationMs!
                              ? 'Kesimpulan: Hive lebih cepat pada penulisan murni karena binary in-memory.'
                              : 'Kesimpulan: SQFlite batch commit sangat efisien dalam satu transaksi ACID.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF1B5E20)),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isBenchmarking ? null : _runBenchmark,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B2A2F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text(
                          _sqfliteDurationMs == null ? 'Mulai Uji Benchmark' : 'Uji Coba Ulang',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tabel Perbandingan
              const Text(
                'Tabel Perbandingan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111111)),
              ),
              const SizedBox(height: 10),
              Table(
                border: TableBorder.all(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(6)),
                columnWidths: const {
                  0: FlexColumnWidth(1.1),
                  1: FlexColumnWidth(1.4),
                  2: FlexColumnWidth(1.4),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
                    children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('Parameter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(8), child: Text('SQFlite', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(8), child: Text('Hive', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                  ),
                  _buildRow('Model Data', 'Relational (RDBMS)', 'NoSQL (Key-Value)'),
                  _buildRow('Bahasa', 'SQL Query', 'Dart Method murni'),
                  _buildRow('Skema', 'Ketat (Tabel/Kolom)', 'Fleksibel (Box Map)'),
                  _buildRow('Agregasi', 'Kuat (SUM, WHERE)', 'Manual di Memori'),
                  _buildRow('Use Case', 'Transaksi Relasional', 'Target, Preferensi, Cache'),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildRow(String col1, String col2, String col3) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(8), child: Text(col1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
        Padding(padding: const EdgeInsets.all(8), child: Text(col2, style: const TextStyle(fontSize: 11))),
        Padding(padding: const EdgeInsets.all(8), child: Text(col3, style: const TextStyle(fontSize: 11))),
      ],
    );
  }
}
