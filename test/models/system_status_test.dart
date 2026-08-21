import 'package:flutter_test/flutter_test.dart';
import 'package:istakipmobil/models/system_status.dart';

void main() {
  group('SystemStatus Tests', () {
    test('fromJson parses running system status JSON correctly', () {
      final json = {
        'running': true,
        'status': 'Çalışıyor',
        'active_alarms': 3,
        'summary': {
          'toplam_isci': 8,
        },
        'istasyon': 'Istasyon-2',
        'worker_name': 'Hasan Bakır',
      };

      final status = SystemStatus.fromJson(json);

      expect(status.totalWorkers, 8);
      expect(status.workingCount, 1);
      expect(status.activeAlarmsCount, 3);
      expect(status.activeCamerasCount, 1);
      expect(status.statusText, '1 İstasyon Aktif (Istasyon-1)');
      expect(status.activeStation, 'Istasyon-2');
      expect(status.activeWorkerName, 'Hasan Bakır');
    });

    test('SystemStatus.initial returns default object', () {
      final status = SystemStatus.initial();

      expect(status.totalWorkers, 4);
      expect(status.workingCount, 1);
      expect(status.idleCount, 3);
      expect(status.activeAlarmsCount, 0);
      expect(status.activeCamerasCount, 1);
    });

    test('toJson serializes SystemStatus correctly', () {
      final status = SystemStatus(
        totalWorkers: 10,
        workingCount: 4,
        idleCount: 6,
        weldingCount: 2,
        activeAlarmsCount: 1,
        activeCamerasCount: 2,
        statusText: '2 İstasyon Aktif',
        activeStation: 'Istasyon-1',
        activeWorkerName: 'Veli',
      );

      final json = status.toJson();

      expect(json['toplam_isci'], 10);
      expect(json['working_count'], 4);
      expect(json['idle_count'], 6);
      expect(json['welding_count'], 2);
      expect(json['active_alarms'], 1);
      expect(json['active_cameras_count'], 2);
      expect(json['active_station'], 'Istasyon-1');
      expect(json['active_worker_name'], 'Veli');
    });
  });
}
