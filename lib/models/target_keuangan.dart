class TargetKeuangan {
  final String id;
  final String nama;
  final double targetNominal;
  final double terkumpulNominal;
  final String deadline;
  final String? catatan;

  TargetKeuangan({
    required this.id,
    required this.nama,
    required this.targetNominal,
    this.terkumpulNominal = 0,
    required this.deadline,
    this.catatan,
  });

  /// Konversi ke Map untuk disimpan di Hive Box
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'targetNominal': targetNominal,
      'terkumpulNominal': terkumpulNominal,
      'deadline': deadline,
      'catatan': catatan ?? '',
    };
  }

  /// Membaca dari Map di Hive Box
  factory TargetKeuangan.fromMap(Map<dynamic, dynamic> map) {
    return TargetKeuangan(
      id: map['id'] as String,
      nama: map['nama'] as String,
      targetNominal: (map['targetNominal'] as num).toDouble(),
      terkumpulNominal: (map['terkumpulNominal'] as num?)?.toDouble() ?? 0,
      deadline: map['deadline'] as String,
      catatan: map['catatan'] as String?,
    );
  }

  TargetKeuangan copyWith({
    String? id,
    String? nama,
    double? targetNominal,
    double? terkumpulNominal,
    String? deadline,
    String? catatan,
  }) {
    return TargetKeuangan(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      targetNominal: targetNominal ?? this.targetNominal,
      terkumpulNominal: terkumpulNominal ?? this.terkumpulNominal,
      deadline: deadline ?? this.deadline,
      catatan: catatan ?? this.catatan,
    );
  }

  double get persentase {
    if (targetNominal <= 0) return 0;
    final p = terkumpulNominal / targetNominal;
    return p > 1.0 ? 1.0 : p;
  }
}

