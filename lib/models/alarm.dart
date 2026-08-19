class AlarmModel {
  final int id;
  final String alarmType;
  final String message;
  final String timestamp;
  final String? cameraName;
  final String? workerName;
  final bool isResolved;
  final String severity; // 'critical', 'warning', 'info'

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
      message: json['mesaj'] ?? json['message'] ?? 'İhlal veya durum uyarısı',
      timestamp: json['zaman'] ?? json['timestamp'] ?? DateTime.now().toString(),
      cameraName: json['kamera_adi'] ?? json['camera_name'],
      workerName: json['isci_adi'] ?? json['worker_name'],
      isResolved: json['cozuldu'] ?? json['resolved'] ?? false,
      severity: json['onem_derecesi'] ?? json['severity'] ?? 'warning',
    );
  }
}
