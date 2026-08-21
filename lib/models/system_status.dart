class SystemStatus {
  final int totalWorkers;
  final int workingCount;
  final int idleCount;
  final int weldingCount;
  final int activeAlarmsCount;
  final int activeCamerasCount;
  final String statusText;
  final String? activeStation;
  final String? activeWorkerName;

  SystemStatus({
    required this.totalWorkers,
    required this.workingCount,
    required this.idleCount,
    required this.weldingCount,
    required this.activeAlarmsCount,
    required this.activeCamerasCount,
    required this.statusText,
    this.activeStation,
    this.activeWorkerName,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};

    bool isRunning = json['running'] == true || json['camera_status'] == 'Kamera Çalışıyor';
    String durum = (json['durum'] ?? json['status'] ?? summary['status'] ?? '').toString();
    bool isWelding = durum.toLowerCase().contains('kaynak');
    bool isWorking = (durum.toLowerCase().contains('çalış') || durum.toLowerCase().contains('calis') || isWelding) && isRunning;

    int activeCams = isRunning ? 1 : 0;
    int working = isWorking ? activeCams : 0;
    int welding = (isWelding && isRunning) ? activeCams : 0;
    int totalInDb = summary['toplam_isci'] ?? summary['total_workers'] ?? 4;
    int idle = totalInDb > working ? (totalInDb - working) : totalInDb;

    return SystemStatus(
      totalWorkers: totalInDb,
      workingCount: working,
      idleCount: idle,
      weldingCount: welding,
      activeAlarmsCount: json['active_alarms'] ?? json['alarm_count'] ?? 0,
      activeCamerasCount: activeCams,
      statusText: isRunning ? '1 İstasyon Aktif (Istasyon-1)' : 'Kamera Kapalı',
      activeStation: json['istasyon'] ?? json['station'] ?? 'Istasyon-1',
      activeWorkerName: json['worker_name'],
    );
  }

  factory SystemStatus.initial() {
    return SystemStatus(
      totalWorkers: 4,
      workingCount: 1,
      idleCount: 3,
      weldingCount: 1,
      activeAlarmsCount: 0,
      activeCamerasCount: 1,
      statusText: '1 İstasyon Aktif (Istasyon-1)',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toplam_isci': totalWorkers,
      'working_count': workingCount,
      'idle_count': idleCount,
      'welding_count': weldingCount,
      'active_alarms': activeAlarmsCount,
      'active_cameras_count': activeCamerasCount,
      'status_text': statusText,
      'active_station': activeStation,
      'active_worker_name': activeWorkerName,
    };
  }
}
