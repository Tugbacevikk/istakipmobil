class WorkerModel {
  final int id;
  final String name;
  final String? sicilNo;
  final String? department;
  final String? photoUrl;
  final String status; // 'Calisiyor', 'Durusta', 'Kaynak Yapıyor', 'Bilinmiyor'
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
    return WorkerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['ad_soyad'] ?? json['name'] ?? 'Bilinmeyen İşçi',
      sicilNo: json['sicil_no'] ?? json['employee_id'],
      department: json['departman'] ?? json['department'] ?? 'Genel Üretim',
      photoUrl: json['fotograf_yolu'] ?? json['photo_url'],
      status: json['son_durum'] ?? json['status'] ?? 'Bilinmiyor',
      lastSeen: json['son_gorulme'] ?? json['last_seen'],
      lastStation: json['son_istasyon'] ?? json['last_station'],
    );
  }
}
