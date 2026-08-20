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
    bool isWelding = durum.contains('Kaynak');
    bool isWorking = durum.contains('Çalış') || durum.contains('Calis') || isWelding || personCount > 0;

    int totalInDb = summary['toplam_isci'] ?? summary['total_workers'] ?? 4;
    int working = isWorking ? (personCount > 0 ? personCount : 1) : (summary['calisan_sayisi'] ?? 0);
    int welding = isWelding ? (personCount > 0 ? personCount : 1) : (summary['kaynak_yapan'] ?? 0);
    int idle = totalInDb > working ? (totalInDb - working) : 0;

    return SystemStatus(
      totalWorkers: totalInDb,
      workingCount: working,
      idleCount: idle,
      weldingCount: welding,
      activeAlarmsCount: json['active_alarms'] ?? json['alarm_count'] ?? 0,
      activeCamerasCount: json['active_cameras'] ?? json['camera_count'] ?? 1,
      statusText: json['camera_status'] ?? json['system_status'] ?? 'Kamera Çalışıyor',
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
      statusText: 'Bağlanıyor...',
    );
  }
}
