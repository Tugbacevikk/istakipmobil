class CameraModel {
  final int id;
  final String name;
  final String source; // RTSP URL, WebCam index, or Video path
  final bool isActive;
  final String? location;

  CameraModel({
    required this.id,
    required this.name,
    required this.source,
    required this.isActive,
    this.location,
  });

  factory CameraModel.fromJson(Map<String, dynamic> json) {
    return CameraModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['kamera_adi'] ?? json['name'] ?? 'Kamera ${json['id']}',
      source: json['kaynak'] ?? json['source'] ?? '0',
      isActive: json['aktif'] ?? json['is_active'] ?? false,
      location: json['konum'] ?? json['location'] ?? 'Fabrika Sahası',
    );
  }
}
