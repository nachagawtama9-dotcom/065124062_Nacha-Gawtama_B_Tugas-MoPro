import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/target_keuangan.dart';
import '../services/hive_service.dart';
import '../widgets/target_dialog.dart';

class HiveScreen extends StatefulWidget {
  const HiveScreen({super.key});

  @override
  State<HiveScreen> createState() => _HiveScreenState();
}

class _HiveScreenState extends State<HiveScreen> {
  final HiveService _hiveService = HiveService.instance;
  List<TargetKeuangan> _listTarget = [];
  bool _isLoading = true;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final numberOnlyFormatter = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() => _isLoading = true);
    final targets = _hiveService.getAllTargets();
    setState(() {
      _listTarget = targets;
      _isLoading = false;
    });
  }

  void _showFormDialog([TargetKeuangan? target]) {
    showDialog(
      context: context,
      builder: (ctx) => TargetDialog(
        target: target,
        onSave: (targetBaru) async {
          if (target == null) {
            await _hiveService.addTarget(targetBaru);
          } else {
            await _hiveService.updateTarget(targetBaru);
          }
          _loadData();
        },
      ),
    );
  }

  void _showSetorDialog(TargetKeuangan target) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tambah Tabungan: ${target.nama}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan nominal yang ingin disisihkan:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nominal (Rp)',
                prefixIcon: Icon(Icons.add),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B2A2F),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final nominal = double.tryParse(controller.text) ?? 0.0;
              if (nominal > 0) {
                Navigator.pop(ctx);
                await _hiveService.tambahTabungan(target.id, nominal);
                _loadData();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _hapusTarget(String id, String nama) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Target?'),
        content: Text('Target "$nama" akan dihapus dari penyimpanan Hive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _hiveService.deleteTarget(id);
              _loadData();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async => _loadData(),
                color: Colors.black,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Target Tabungan',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111111),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Penyimpanan Box Hive (NoSQL)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showFormDialog(),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Tambah'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B2A2F),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (_listTarget.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          alignment: Alignment.center,
                          child: const Text(
                            'Belum ada target tabungan yang dibuat.',
                            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _listTarget.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final item = _listTarget[i];
                            final persentase = item.persentase;
                            final isSelesai = item.terkumpulNominal >= item.targetNominal;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE5E5E5)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.nama,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF111111),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF757575)),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 28),
                                            onPressed: () => _showFormDialog(item),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 16, color: Color(0xFFBDBDBD)),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 28),
                                            onPressed: () => _hapusTarget(item.id, item.nama),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Progres Bar Halus
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: persentase,
                                      minHeight: 6,
                                      backgroundColor: const Color(0xFFE0E0E0),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isSelesai ? const Color(0xFF2E7D32) : const Color(0xFF1B2A2F),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${currencyFormatter.format(item.terkumpulNominal)} / ${currencyFormatter.format(item.targetNominal)}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF444444),
                                        ),
                                      ),
                                      Text(
                                        "${(persentase * 100).toStringAsFixed(0)}%",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSelesai ? const Color(0xFF2E7D32) : const Color(0xFF111111),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Target: ${item.deadline}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                                      ),
                                      InkWell(
                                        onTap: () => _showSetorDialog(item),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          child: Text(
                                            '+ Setor Tabungan',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1B2A2F),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
