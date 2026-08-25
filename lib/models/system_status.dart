class StationStatusItem {
  final String id;
  final String name;
  final String worker;
  final String status;
  final bool isOnline;

  StationStatusItem({
    required this.id,
    required this.name,
    required this.worker,
    required this.status,
    required this.isOnline,
  });

  factory StationStatusItem.fromJson(Map<String, dynamic> json) {
    return StationStatusItem(
      id: json['id'] as String? ?? 'Istasyon-1',
      name: json['name'] as String? ?? json['id'] as String? ?? 'İstasyon',
      worker: json['worker'] as String? ?? 'Kayıtlı İşçi',
      status: json['status'] as String? ?? 'Kamera Kapalı (Çevrimdışı)',
      isOnline: json['is_online'] as bool? ?? false,
    );
  }
}

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
  final List<StationStatusItem> stations;

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
    this.stations = const [],
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};

    bool isRunning = json['running'] == true || json['camera_status'] == 'Kamera Çalışıyor';
    String durum = (json['durum'] ?? json['status'] ?? summary['status'] ?? '').toString();
    bool isWelding = durum.toLowerCase().contains('kaynak');
    bool isWorking = (durum.toLowerCase().contains('çalış') || durum.toLowerCase().contains('calis') || isWelding) && isRunning;

    int activeCams = json['active_camera_count'] ?? json['active_cameras_count'] ?? json['active_cameras'] ?? json['total_active_stations'] ?? (isRunning ? 2 : 0);
    int totalInDb = json['toplam_calisan'] ?? summary['toplam_calisan'] ?? summary['toplam_isci'] ?? summary['total_workers'] ?? json['total_workers'] ?? 4;
    int working = json['calisan_sayisi'] ?? json['total_working_count'] ?? json['working_count'] ?? (isWorking ? 1 : 0);
    if (working > totalInDb) {
      working = totalInDb;
    }
    int welding = json['welding_count'] ?? ((isWelding && isRunning) ? 1 : 0);
    int idle = totalInDb > working ? (totalInDb - working) : 0;

    List<StationStatusItem> stationsList = [];
    if (json['stations'] is List) {
      stationsList = (json['stations'] as List)
          .map((item) => StationStatusItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return SystemStatus(
      totalWorkers: totalInDb,
      workingCount: working,
      idleCount: idle,
      weldingCount: welding,
      activeAlarmsCount: json['active_alarms'] ?? json['alarm_count'] ?? 0,
      activeCamerasCount: activeCams,
      statusText: json['status_text'] ?? (activeCams > 0 ? '$activeCams İstasyon / Kamera Aktif' : 'Kameralar Kapalı'),
      activeStation: json['istasyon'] ?? json['station'] ?? 'Istasyon-1',
      activeWorkerName: json['worker_name'],
      stations: stationsList,
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
      statusText: 'Kameralar Kapalı',
      stations: [],
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
