class AlarmModel {
  final int id;
  final String alarmType;
  final String message;
  final String timestamp;
  final String? cameraName;
  final String? workerName;
  final bool isResolved;
  final String severity;

  AlarmModel({
    required this.id,
    required this.alarmType,
    required this.message,
    required this.timestamp,
    this.cameraName,
    this.workerName,
    required this.isResolved,
    required this.severity,
  });

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      alarmType: json['alarm_turu'] ?? json['type'] ?? 'Genel Alarm',
      message: json['aciklama'] ?? json['mesaj'] ?? json['message'] ?? 'İhlal veya durum uyarısı',
      timestamp: json['zaman'] ?? json['time'] ?? json['created_at'] ?? json['timestamp'] ?? DateTime.now().toString(),
      cameraName: json['istasyon_adi'] ?? json['station'] ?? json['kamera_adi'] ?? json['camera_name'],
      workerName: json['isci_adi'] ?? json['worker_name'],
      isResolved: json['okundu'] == 1 || json['cozuldu'] == true || json['resolved'] == true,
      severity: json['onem_derecesi'] ?? json['severity'] ?? 'warning',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alarm_turu': alarmType,
      'aciklama': message,
      'zaman': timestamp,
      'istasyon_adi': cameraName,
      'isci_adi': workerName,
      'okundu': isResolved ? 1 : 0,
      'onem_derecesi': severity,
    };
  }
}
