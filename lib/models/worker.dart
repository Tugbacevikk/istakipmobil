class WorkerModel {
  final int id;
  final String name;
  final String? sicilNo;
  final String? department;
  final String? photoUrl;
  final String status;
  final String? lastSeen;
  final String? lastStation;

  WorkerModel({
    required this.id,
    required this.name,
    this.sicilNo,
    this.department,
    this.photoUrl,
    required this.status,
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

    return WorkerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: fullName,
      sicilNo: json['sicil_no']?.toString() ?? json['employee_id']?.toString(),
      department: json['departman']?.toString() ?? json['department']?.toString() ?? 'Genel Üretim',
      photoUrl: json['fotograf_yolu']?.toString() ?? json['photo_url']?.toString(),
      status: json['son_durum']?.toString() ?? json['status']?.toString() ?? (json['aktif'] == 1 ? 'Çalışıyor' : 'Duruşta'),
      lastSeen: json['son_gorulme']?.toString() ?? json['last_seen']?.toString() ?? json['kayit_tarihi']?.toString(),
      lastStation: json['istasyon_adi']?.toString() ?? json['son_istasyon']?.toString() ?? json['last_station']?.toString(),
    );
  }
}
