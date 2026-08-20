class SystemStatus {
  final int totalWorkers;
  final int workingCount;
  final int idleCount;
  final int weldingCount;
  final int activeAlarmsCount;
  final int activeCamerasCount;
  final String statusText;

  SystemStatus({
    required this.totalWorkers,
    required this.workingCount,
    required this.idleCount,
    required this.weldingCount,
    required this.activeAlarmsCount,
    required this.activeCamerasCount,
    required this.statusText,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    
    return SystemStatus(
      totalWorkers: summary['toplam_isci'] ?? summary['total_workers'] ?? json['total_workers'] ?? 0,
      workingCount: summary['calisan_sayisi'] ?? summary['working'] ?? json['working_count'] ?? 0,
      idleCount: summary['durusta_sayisi'] ?? summary['idle'] ?? json['idle_count'] ?? 0,
      weldingCount: summary['kaynak_yapan'] ?? summary['welding'] ?? json['welding_count'] ?? 0,
      activeAlarmsCount: json['active_alarms'] ?? json['alarm_count'] ?? 0,
      activeCamerasCount: json['active_cameras'] ?? json['camera_count'] ?? 0,
      statusText: json['system_status'] ?? 'Aktif',
    );
  }

  factory SystemStatus.initial() {
    return SystemStatus(
      totalWorkers: 0,
      workingCount: 0,
      idleCount: 0,
      weldingCount: 0,
      activeAlarmsCount: 0,
      activeCamerasCount: 0,
      statusText: 'Bağlanıyor...',
    );
  }
}
