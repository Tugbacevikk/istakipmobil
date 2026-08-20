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

    int personCount = 0;
    if (json.containsKey('kisi_sayisi')) {
      personCount = (json['kisi_sayisi'] is int)
          ? json['kisi_sayisi']
          : int.tryParse(json['kisi_sayisi'].toString()) ?? 0;
    } else if (json.containsKey('person_count')) {
      personCount = (json['person_count'] is int)
          ? json['person_count']
          : int.tryParse(json['person_count'].toString()) ?? 0;
    }

    String durum = (json['durum'] ?? json['status'] ?? summary['status'] ?? '').toString();
    bool isRunning = json['running'] == true || json['camera_status'] == 'Kamera Çalışıyor';
    bool isWelding = durum.toLowerCase().contains('kaynak');
    bool isWorking = (durum.toLowerCase().contains('çalış') || durum.toLowerCase().contains('calis') || isWelding) && personCount > 0;

    int totalInDb = summary['toplam_isci'] ?? summary['total_workers'] ?? 4;
    int working = isWorking ? personCount : (summary['calisan_sayisi'] ?? 0);
    int welding = (isWelding && personCount > 0) ? personCount : (summary['kaynak_yapan'] ?? 0);
    int idle = totalInDb > working ? (totalInDb - working) : 0;

    return SystemStatus(
      totalWorkers: totalInDb,
      workingCount: working,
      idleCount: idle,
      weldingCount: welding,
      activeAlarmsCount: json['active_alarms'] ?? json['alarm_count'] ?? 0,
      activeCamerasCount: isRunning ? 1 : (json['active_cameras'] ?? 0),
      statusText: json['camera_status'] ?? json['system_status'] ?? (isRunning ? 'Kamera Çalışıyor' : 'Kamera Kapalı'),
      activeStation: json['istasyon'] ?? json['station'] ?? 'Istasyon-1',
      activeWorkerName: json['worker_name'],
    );
  }

  factory SystemStatus.initial() {
    return SystemStatus(
      totalWorkers: 4,
      workingCount: 0,
      idleCount: 4,
      weldingCount: 0,
      activeAlarmsCount: 0,
      activeCamerasCount: 0,
      statusText: 'Bağlanıyor...',
    );
  }
}
