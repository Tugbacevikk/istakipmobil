class WorkerModel {
  final int id;
  final String name;
  final String? sicilNo;
  final String? department;
  final String? photoUrl;
  final String status;
  final bool isAktif;
  final String? lastSeen;
  final String? lastStation;

  WorkerModel({
    required this.id,
    required this.name,
    this.sicilNo,
    this.department,
    this.photoUrl,
    required this.status,
    required this.isAktif,
    this.lastSeen,
    this.lastStation,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    String fullName = '';
    final ad = json['ad'] ?? json['first_name'] ?? '';
    final soyad = json['soyad'] ?? json['last_name'] ?? '';
    if (ad.toString().isNotEmpty || soyad.toString().isNotEmpty) {
      fullName = '$ad $soyad'.trim();
    }
    if (fullName.isEmpty) {
      fullName = (json['ad_soyad'] ?? json['name'] ?? 'Bilinmeyen İşçi').toString().trim();
    }

    final rawAktif = json['aktif'];
    final bool isAktif = rawAktif == null || rawAktif == 1 || rawAktif == true || rawAktif.toString() == '1';

    return WorkerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: fullName,
      sicilNo: json['sicil_no']?.toString() ?? json['employee_id']?.toString(),
      department: json['departman']?.toString() ?? json['department']?.toString() ?? 'Genel Üretim',
      photoUrl: json['fotograf_yolu']?.toString() ?? json['photo_url']?.toString(),
      status: json['son_durum']?.toString() ?? json['status']?.toString() ?? (isAktif ? 'Aktif Çalışan' : 'Pasif Çalışan'),
      isAktif: isAktif,
      lastSeen: json['son_gorulme']?.toString() ?? json['last_seen']?.toString() ?? json['kayit_tarihi']?.toString(),
      lastStation: json['istasyon_adi']?.toString() ?? json['station']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ad_soyad': name,
      'sicil_no': sicilNo,
      'departman': department,
      'fotograf_yolu': photoUrl,
      'son_durum': status,
      'aktif': isAktif,
      'son_gorulme': lastSeen,
      'istasyon_adi': lastStation,
    };
  }
}
