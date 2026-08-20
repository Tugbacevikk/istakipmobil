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
    String fullName = json['ad_soyad'] ?? json['name'] ?? '';
    if (fullName.isEmpty && json['ad'] != null) {
      fullName = '${json['ad']} ${json['soyad'] ?? ''}'.trim();
    }
    if (fullName.isEmpty) fullName = 'Bilinmeyen İşçi';

    return WorkerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: fullName,
      sicilNo: json['sicil_no'] ?? json['employee_id'],
      department: json['departman'] ?? json['department'] ?? 'Genel Üretim',
      photoUrl: json['fotograf_yolu'] ?? json['photo_url'],
      status: json['son_durum'] ?? json['status'] ?? (json['aktif'] == 1 ? 'Çalışıyor' : 'Duruşta'),
      lastSeen: json['son_gorulme'] ?? json['last_seen'] ?? json['kayit_tarihi'],
      lastStation: json['istasyon_adi'] ?? json['son_istasyon'] ?? json['last_station'],
    );
  }
}
