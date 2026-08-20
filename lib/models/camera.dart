class CameraModel {
  final int id;
  final String name;
  final String source; // RTSP URL, WebCam index, or Video path
  final bool isActive;
  final String? location;
  final String? ipAddress;

  CameraModel({
    required this.id,
    required this.name,
    required this.source,
    required this.isActive,
    this.location,
    this.ipAddress,
  });

  factory CameraModel.fromJson(Map<String, dynamic> json) {
    return CameraModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['istasyon_adi'] ?? json['kamera_adi'] ?? json['name'] ?? 'Kamera ${json['id']}',
      source: json['ip_adresi'] ?? json['kaynak'] ?? json['source'] ?? '0',
      isActive: json['aktif'] == 1 || json['aktif'] == true || json['is_active'] == true,
      location: json['konum'] ?? json['location'] ?? 'Fabrika Sahası',
      ipAddress: json['ip_adresi']?.toString(),
    );
  }
}
