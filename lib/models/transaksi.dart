class Transaksi {
  final int? id;
  final String judul;
  final double nominal;
  final String tipe; // 'pemasukan' atau 'pengeluaran'
  final String kategori;
  final String tanggal;
  final String? catatan;

  Transaksi({
    this.id,
    required this.judul,
    required this.nominal,
    required this.tipe,
    required this.kategori,
    required this.tanggal,
    this.catatan,
  });

  /// Konversi objek Transaksi ke Map untuk disimpan ke SQFlite
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'judul': judul,
      'nominal': nominal,
      'tipe': tipe,
      'kategori': kategori,
      'tanggal': tanggal,
      'catatan': catatan ?? '',
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Buat objek Transaksi dari Map yang didapat dari query SQFlite
  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'] as int?,
      judul: map['judul'] as String,
      nominal: (map['nominal'] as num).toDouble(),
      tipe: map['tipe'] as String,
      kategori: map['kategori'] as String,
      tanggal: map['tanggal'] as String,
      catatan: map['catatan'] as String?,
    );
  }

  Transaksi copyWith({
    int? id,
    String? judul,
    double? nominal,
    String? tipe,
    String? kategori,
    String? tanggal,
    String? catatan,
  }) {
    return Transaksi(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      nominal: nominal ?? this.nominal,
      tipe: tipe ?? this.tipe,
      kategori: kategori ?? this.kategori,
      tanggal: tanggal ?? this.tanggal,
      catatan: catatan ?? this.catatan,
    );
  }
}

