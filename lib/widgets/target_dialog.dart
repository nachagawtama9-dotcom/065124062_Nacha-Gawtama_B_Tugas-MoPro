import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/target_keuangan.dart';

class TargetDialog extends StatefulWidget {
  final TargetKeuangan? target;
  final Function(TargetKeuangan) onSave;

  const TargetDialog({
    super.key,
    this.target,
    required this.onSave,
  });

  @override
  State<TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<TargetDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _targetNominalController;
  late TextEditingController _terkumpulController;
  late TextEditingController _catatanController;
  late DateTime _deadline;

  @override
  void initState() {
    super.initState();
    final t = widget.target;
    _namaController = TextEditingController(text: t?.nama ?? '');
    _targetNominalController = TextEditingController(
      text: t != null ? t.targetNominal.toStringAsFixed(0) : '',
    );
    _terkumpulController = TextEditingController(
      text: t != null ? t.terkumpulNominal.toStringAsFixed(0) : '0',
    );
    _catatanController = TextEditingController(text: t?.catatan ?? '');

    if (t != null && t.deadline.isNotEmpty) {
      try {
        _deadline = DateTime.parse(t.deadline);
      } catch (_) {
        _deadline = DateTime.now().add(const Duration(days: 90));
      }
    } else {
      _deadline = DateTime.now().add(const Duration(days: 90));
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _targetNominalController.dispose();
    _terkumpulController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _pilihDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  void _simpan() {
    if (_formKey.currentState!.validate()) {
      final targetNominal = double.tryParse(_targetNominalController.text) ?? 0.0;
      final terkumpul = double.tryParse(_terkumpulController.text) ?? 0.0;
      final deadlineStr = DateFormat('yyyy-MM-dd').format(_deadline);

      final baru = TargetKeuangan(
        id: widget.target?.id ?? 'goal_${DateTime.now().millisecondsSinceEpoch}',
        nama: _namaController.text.trim(),
        targetNominal: targetNominal,
        terkumpulNominal: terkumpul,
        deadline: deadlineStr,
        catatan: _catatanController.text.trim(),
      );

      widget.onSave(baru);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.target != null;

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
                      isEdit ? 'Edit Target (Hive NoSQL)' : 'Tambah Target (Hive NoSQL)',
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
                const SizedBox(height: 16),

                // Nama Target
                TextFormField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Target / Impian',
                    hintText: 'Contoh: Beli Laptop Baru, Liburan',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Nama target tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),

                // Target Nominal
                TextFormField(
                  controller: _targetNominalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Dana (Rp)',
                    hintText: 'Contoh: 10000000',
                    prefixIcon: Icon(Icons.savings_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Target dana tidak boleh kosong';
                    }
                    final n = double.tryParse(val);
                    if (n == null || n <= 0) {
                      return 'Masukkan nominal target yang valid (> 0)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Terkumpul Saat Ini
                TextFormField(
                  controller: _terkumpulController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sudah Terkumpul Saat Ini (Rp)',
                    hintText: 'Contoh: 2000000',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nominal terkumpul tidak boleh kosong';
                    }
                    final n = double.tryParse(val);
                    if (n == null || n < 0) {
                      return 'Masukkan nominal yang valid (>= 0)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Deadline
                InkWell(
                  onTap: _pilihDeadline,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Target Tanggal Tercapai (Deadline)',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(DateFormat('dd MMMM yyyy').format(_deadline)),
                  ),
                ),
                const SizedBox(height: 12),

                // Catatan
                TextFormField(
                  controller: _catatanController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan / Alasan',
                    hintText: 'Contoh: Sisihkan 500rb per bulan...',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol Simpan
                ElevatedButton.icon(
                  onPressed: _simpan,
                  icon: const Icon(Icons.save),
                  label: Text(isEdit ? 'Perbarui Target di Hive' : 'Simpan Target ke Hive'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
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

