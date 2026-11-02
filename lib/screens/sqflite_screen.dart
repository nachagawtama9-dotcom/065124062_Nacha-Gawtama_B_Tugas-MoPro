import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/transaksi.dart';
import '../widgets/transaksi_dialog.dart';

class SqfliteScreen extends StatefulWidget {
  const SqfliteScreen({super.key});

  @override
  State<SqfliteScreen> createState() => _SqfliteScreenState();
}

class _SqfliteScreenState extends State<SqfliteScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Transaksi> _listTransaksi = [];
  Map<String, double> _summary = {'pemasukan': 0, 'pengeluaran': 0, 'saldo': 0};
  bool _isLoading = true;

  String _filterKategori = 'Semua';
  final List<String> _kategoriList = [
    'Semua',
    'Makanan',
    'Transportasi',
    'Pendidikan',
    'Hiburan',
    'Gaji',
    'Tagihan',
    'Lainnya',
  ];

  // Controller untuk baris isian cepat (Quick Add)
  final TextEditingController _quickJudulController = TextEditingController();
  final TextEditingController _quickNominalController = TextEditingController();
  String _quickTipe = 'pengeluaran';
  String _quickKategori = 'Makanan';

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final numberOnlyFormatter = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    _quickJudulController.dispose();
    _quickNominalController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      await _dbHelper.seedSampleDataIfEmpty();
      final data = await _dbHelper.getAllTransaksi(
        filterKategori: _filterKategori,
      );
      final summary = await _dbHelper.getSummary();

      if (mounted) {
        setState(() {
          _listTransaksi = data;
          _summary = summary;
        });
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Tambah transaksi langsung dari baris isian atas (Quick Add)
  Future<void> _catatQuick() async {
    final judul = _quickJudulController.text.trim();
    final nominalText = _quickNominalController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final nominal = double.tryParse(nominalText) ?? 0.0;

    if (judul.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keterangan transaksi harus diisi')),
      );
      return;
    }

    if (nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0')),
      );
      return;
    }

    final now = DateTime.now();
    final tanggalStr = DateFormat('yyyy-MM-dd').format(now);

    final baru = Transaksi(
      judul: judul,
      nominal: nominal,
      tipe: _quickTipe,
      kategori: _quickKategori,
      tanggal: tanggalStr,
      catatan: '',
    );

    try {
      await _dbHelper.insertTransaksi(baru);
      _quickJudulController.clear();
      _quickNominalController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
        setState(() => _filterKategori = 'Semua');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Berhasil menambahkan "$judul" ke SQLite!'),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      await _refreshData();
    } catch (e) {
      debugPrint('Error inserting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambah transaksi: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    }
  }

  void _showFormDialog([Transaksi? transaksi]) {
    showDialog(
      context: context,
      builder: (ctx) => TransaksiDialog(
        transaksi: transaksi,
        onSave: (transaksiBaru) async {
          try {
            if (transaksi == null) {
              await _dbHelper.insertTransaksi(transaksiBaru);
            } else {
              await _dbHelper.updateTransaksi(transaksiBaru);
            }
            if (mounted) {
              setState(() => _filterKategori = 'Semua');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(transaksi == null
                      ? '✓ Berhasil menambahkan "${transaksiBaru.judul}"!'
                      : '✓ Berhasil memperbarui "${transaksiBaru.judul}"!'),
                  backgroundColor: const Color(0xFF2E7D32),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            await _refreshData();
          } catch (e) {
            debugPrint('Error on save: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal menyimpan transaksi: $e'),
                  backgroundColor: const Color(0xFFC62828),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _hapusTransaksi(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text('Catatan ini akan dihapus permanen dari buku kas.'),
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
              await _dbHelper.deleteTransaksi(id);
              _refreshData();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  String _formatTanggalSingkat(String tanggalStr) {
    try {
      final dt = DateTime.parse(tanggalStr);
      return DateFormat('dd/MM').format(dt);
    } catch (_) {
      return tanggalStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final saldo = _summary['saldo'] ?? 0;
    final masuk = _summary['pemasukan'] ?? 0;
    final keluar = _summary['pengeluaran'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: Colors.black,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==========================================
                      // 1. HEADER POLOS GAYA BUKU KAS
                      // ==========================================
                      const Text(
                        'Saldo saat ini',
                        style: TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormatter.format(saldo),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'masuk ${numberOnlyFormatter.format(masuk)} · keluar ${numberOnlyFormatter.format(keluar)}',
                        style: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ==========================================
                      // 2. BARIS ISIAN CEPAT (QUICK ADD BAR)
                      // ==========================================
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E5E5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pilihan Tipe & Kategori Ringkas
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _quickTipe = _quickTipe == 'pengeluaran' ? 'pemasukan' : 'pengeluaran';
                                      _quickKategori = _quickTipe == 'pengeluaran' ? 'Makanan' : 'Gaji';
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _quickTipe == 'pengeluaran'
                                          ? const Color(0xFFFFEBEE)
                                          : const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _quickTipe == 'pengeluaran'
                                            ? const Color(0xFFFFCDD2)
                                            : const Color(0xFFC8E6C9),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _quickTipe == 'pengeluaran'
                                              ? Icons.arrow_downward
                                              : Icons.arrow_upward,
                                          size: 13,
                                          color: _quickTipe == 'pengeluaran'
                                              ? const Color(0xFFC62828)
                                              : const Color(0xFF2E7D32),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _quickTipe == 'pengeluaran' ? 'Keluar' : 'Masuk',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _quickTipe == 'pengeluaran'
                                                ? const Color(0xFFC62828)
                                                : const Color(0xFF2E7D32),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _quickKategori,
                                    isDense: true,
                                    style: const TextStyle(
                                      color: Color(0xFF555555),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    items: [
                                      'Makanan',
                                      'Transportasi',
                                      'Pendidikan',
                                      'Hiburan',
                                      'Gaji',
                                      'Tagihan',
                                      'Lainnya',
                                    ].map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _quickKategori = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Input Keterangan, Nominal, dan Tombol [Catat]
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Kolom Keterangan
                                Expanded(
                                  flex: 4,
                                  child: SizedBox(
                                    height: 38,
                                    child: TextField(
                                      controller: _quickJudulController,
                                      onSubmitted: (_) => _catatQuick(),
                                      style: const TextStyle(fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText: 'Contoh: bensin',
                                        hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: const BorderSide(color: Color(0xFFDCDCDC)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: const BorderSide(color: Color(0xFFDCDCDC)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: const BorderSide(color: Color(0xFF111111)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Kolom Nominal
                                Expanded(
                                  flex: 3,
                                  child: SizedBox(
                                    height: 38,
                                    child: TextField(
                                      controller: _quickNominalController,
                                      keyboardType: TextInputType.number,
                                      onSubmitted: (_) => _catatQuick(),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      decoration: InputDecoration(
                                        hintText: 'Rp',
                                        hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: const BorderSide(color: Color(0xFFDCDCDC)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: const BorderSide(color: Color(0xFFDCDCDC)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: const BorderSide(color: Color(0xFF111111)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Tombol Catat (Hitam Tegas)
                                SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    onPressed: _catatQuick,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B2A2F),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: const Text(
                                      'Catat',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ==========================================
                      // 3. FILTER KATEGORI MINIMALIS
                      // ==========================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _filterKategori,
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF666666)),
                              style: const TextStyle(
                                color: Color(0xFF555555),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              items: _kategoriList.map((kat) {
                                return DropdownMenuItem(
                                  value: kat,
                                  child: Text('Kategori: $kat'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _filterKategori = val);
                                  _refreshData();
                                }
                              },
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showFormDialog(),
                            icon: const Icon(Icons.add, size: 16, color: Color(0xFF444444)),
                            label: const Text(
                              'Form Rinci',
                              style: TextStyle(color: Color(0xFF444444), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFFEEEEEE), height: 1),
                      const SizedBox(height: 6),

                      // ==========================================
                      // 4. DAFTAR TRANSAKSI GAYA BUKU KAS
                      // ==========================================
                      if (_listTransaksi.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              const Text(
                                'Belum ada catatan transaksi.',
                                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await _dbHelper.seedSampleData();
                                  _refreshData();
                                },
                                icon: const Icon(Icons.dataset_outlined, size: 16),
                                label: const Text('Isi Data Contoh (Dummy)'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1B2A2F),
                                  side: const BorderSide(color: Color(0xFFCCCCCC)),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _listTransaksi.length,
                          separatorBuilder: (ctx, i) =>
                              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F3F3)),
                          itemBuilder: (ctx, i) {
                            final item = _listTransaksi[i];
                            final isPengeluaran = item.tipe == 'pengeluaran';
                            final nominalText =
                                "${isPengeluaran ? '-' : '+'}${numberOnlyFormatter.format(item.nominal)}";

                            return InkWell(
                              onTap: () => _showFormDialog(item),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Tanggal (dd/MM)
                                    SizedBox(
                                      width: 44,
                                      child: Text(
                                        _formatTanggalSingkat(item.tanggal),
                                        style: const TextStyle(
                                          color: Color(0xFF888888),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Judul & Kategori
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.judul,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF111111),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.kategori,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF888888),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Nominal Rata Kanan (Merah bata / Hijau tua)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          nominalText,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'monospace',
                                            color: isPengeluaran
                                                ? const Color(0xFFC62828) // Merah bata
                                                : const Color(0xFF2E7D32), // Hijau tua
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Color(0xFFBDBDBD),
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 28),
                                          onPressed: () {
                                            if (item.id != null) _hapusTransaksi(item.id!);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 40), // Padding bawah aman dari navbar
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
