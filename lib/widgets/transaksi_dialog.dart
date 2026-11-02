import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaksi.dart';

class TransaksiDialog extends StatefulWidget {
  final Transaksi? transaksi;
  final Function(Transaksi) onSave;

  const TransaksiDialog({
    super.key,
    this.transaksi,
    required this.onSave,
  });

  @override
  State<TransaksiDialog> createState() => _TransaksiDialogState();
}

class _TransaksiDialogState extends State<TransaksiDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulController;
  late TextEditingController _nominalController;
  late TextEditingController _catatanController;
  late String _tipe;
  late String _kategori;
  late DateTime _tanggal;

  final List<String> _kategoriPengeluaran = [
    'Makanan',
    'Transportasi',
    'Pendidikan',
    'Hiburan',
    'Tagihan',
    'Kesehatan',
    'Lainnya',
  ];

  final List<String> _kategoriPemasukan = [
    'Gaji',
    'Uang Saku',
    'Freelance',
    'Bonus',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.transaksi;
    _judulController = TextEditingController(text: t?.judul ?? '');
    _nominalController = TextEditingController(
      text: t != null ? t.nominal.toStringAsFixed(0) : '',
    );
    _catatanController = TextEditingController(text: t?.catatan ?? '');
    _tipe = t?.tipe ?? 'pengeluaran';
    _kategori = t?.kategori ?? (_tipe == 'pengeluaran' ? 'Makanan' : 'Gaji');

    if (t != null && t.tanggal.isNotEmpty) {
      try {
        _tanggal = DateTime.parse(t.tanggal);
      } catch (_) {
        _tanggal = DateTime.now();
      }
    } else {
      _tanggal = DateTime.now();
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _nominalController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _tanggal = picked);
    }
  }

  void _simpan() {
    if (_formKey.currentState!.validate()) {
      final cleanNominal = _nominalController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final nominal = double.tryParse(cleanNominal) ?? 0.0;
      final tanggalStr = DateFormat('yyyy-MM-dd').format(_tanggal);

      final baru = Transaksi(
        id: widget.transaksi?.id,
        judul: _judulController.text.trim(),
        nominal: nominal,
        tipe: _tipe,
        kategori: _kategori,
        tanggal: tanggalStr,
        catatan: _catatanController.text.trim(),
      );

      Navigator.of(context).pop();
      widget.onSave(baru);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transaksi != null;
    final currentKategoriList =
        _tipe == 'pengeluaran' ? _kategoriPengeluaran : _kategoriPemasukan;

    // Pastikan kategori saat ini ada di list kategori tipe yang dipilih
    if (!currentKategoriList.contains(_kategori)) {
      _kategori = currentKategoriList.first;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Transaksi (SQFlite)' : 'Tambah Transaksi (SQFlite)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Pilihan Tipe: Pemasukan / Pengeluaran
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_downward, size: 16, color: Colors.red),
                            SizedBox(width: 4),
                            Text('Pengeluaran'),
                          ],
                        ),
                        selected: _tipe == 'pengeluaran',
                        selectedColor: Colors.red.shade100,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _tipe = 'pengeluaran';
                              _kategori = _kategoriPengeluaran.first;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_upward, size: 16, color: Colors.green),
                            SizedBox(width: 4),
                            Text('Pemasukan'),
                          ],
                        ),
                        selected: _tipe == 'pemasukan',
                        selectedColor: Colors.green.shade100,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _tipe = 'pemasukan';
                              _kategori = _kategoriPemasukan.first;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Field Judul
                TextFormField(
                  controller: _judulController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Transaksi',
                    hintText: 'Contoh: Beli Makan Siang / Gaji',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Judul tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),

                // Field Nominal
                TextFormField(
                  controller: _nominalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nominal (Rp)',
                    hintText: 'Contoh: 50000',
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nominal tidak boleh kosong';
                    }
                    final cleanVal = val.replaceAll(RegExp(r'[^0-9]'), '');
                    final n = double.tryParse(cleanVal);
                    if (n == null || n <= 0) {
                      return 'Masukkan nominal angka yang valid (> 0)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Dropdown Kategori
                DropdownButtonFormField<String>(
                  initialValue: _kategori,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: currentKategoriList.map((kat) {
                    return DropdownMenuItem(
                      value: kat,
                      child: Text(kat),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _kategori = val);
                  },
                ),
                const SizedBox(height: 12),

                // Tanggal Picker
                InkWell(
                  onTap: _pilihTanggal,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(DateFormat('dd MMMM yyyy').format(_tanggal)),
                  ),
                ),
                const SizedBox(height: 12),

                // Catatan Tambahan (Opsional)
                TextFormField(
                  controller: _catatanController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Tambahan (Opsional)',
                    hintText: 'Keterangan lebih lanjut...',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol Simpan
                ElevatedButton.icon(
                  onPressed: _simpan,
                  icon: const Icon(Icons.save),
                  label: Text(isEdit ? 'Perbarui Transaksi' : 'Simpan Transaksi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

