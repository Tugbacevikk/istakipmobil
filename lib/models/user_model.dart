class UserModel {
  final int id;
  final String kullaniciAdi;
  final String adSoyad;
  final String? email;
  final String rol;
  final String durum;
  final String? firmaAdi;
  final String? istasyonlar;

  UserModel({
    required this.id,
    required this.kullaniciAdi,
    required this.adSoyad,
    this.email,
    required this.rol,
    required this.durum,
    this.firmaAdi,
    this.istasyonlar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      kullaniciAdi: json['kullanici_adi'] ?? json['username'] ?? 'kullanici',
      adSoyad: json['ad_soyad'] ?? json['full_name'] ?? 'Kullanıcı',
      email: json['email'],
      rol: json['rol'] ?? json['role'] ?? 'patron',
      durum: json['durum'] ?? json['status'] ?? 'bekliyor',
      firmaAdi: json['firma_adi'] ?? json['company_name'],
      istasyonlar: json['istasyonlar']?.toString() ?? json['stations']?.toString(),
    );
  }
}
