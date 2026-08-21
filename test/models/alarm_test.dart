import 'package:flutter_test/flutter_test.dart';
import 'package:istakipmobil/models/alarm.dart';

void main() {
  group('AlarmModel Tests', () {
    test('fromJson parses complete valid JSON correctly', () {
      final json = {
        'id': 101,
        'alarm_turu': 'Telefon Kullanımı',
        'aciklama': 'Kaynak istasyonunda telefon kullanımı tespit edildi',
        'zaman': '2026-08-21 09:15:00',
        'istasyon_adi': 'Istasyon-1',
        'isci_adi': 'Ali Kaya',
        'okundu': 1,
        'onem_derecesi': 'critical',
      };

      final alarm = AlarmModel.fromJson(json);

      expect(alarm.id, 101);
      expect(alarm.alarmType, 'Telefon Kullanımı');
      expect(alarm.message, 'Kaynak istasyonunda telefon kullanımı tespit edildi');
      expect(alarm.timestamp, '2026-08-21 09:15:00');
      expect(alarm.cameraName, 'Istasyon-1');
      expect(alarm.workerName, 'Ali Kaya');
      expect(alarm.isResolved, isTrue);
      expect(alarm.severity, 'critical');
    });

    test('fromJson handles missing fields with default values', () {
      final json = <String, dynamic>{
        'id': '202',
      };

      final alarm = AlarmModel.fromJson(json);

      expect(alarm.id, 202);
      expect(alarm.alarmType, 'Genel Alarm');
      expect(alarm.message, 'İhlal veya durum uyarısı');
      expect(alarm.cameraName, isNull);
      expect(alarm.workerName, isNull);
      expect(alarm.isResolved, isFalse);
      expect(alarm.severity, 'warning');
    });

    test('toJson serializes AlarmModel correctly', () {
      final alarm = AlarmModel(
        id: 303,
        alarmType: 'Baret İhlali',
        message: 'Baretsiz alan girişi',
        timestamp: '2026-08-21 08:00',
        cameraName: 'Istasyon-3',
        workerName: 'Can Demir',
        isResolved: false,
        severity: 'high',
      );

      final json = alarm.toJson();

      expect(json['id'], 303);
      expect(json['alarm_turu'], 'Baret İhlali');
      expect(json['aciklama'], 'Baretsiz alan girişi');
      expect(json['istasyon_adi'], 'Istasyon-3');
      expect(json['isci_adi'], 'Can Demir');
      expect(json['okundu'], 0);
      expect(json['onem_derecesi'], 'high');
    });
  });
}
