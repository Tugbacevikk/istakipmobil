import 'package:flutter_test/flutter_test.dart';
import 'package:istakipmobil/models/worker.dart';

void main() {
  group('WorkerModel Tests', () {
    test('fromJson parses complete valid JSON correctly', () {
      final json = {
        'id': 10,
        'ad': 'Ahmet',
        'soyad': 'Yılmaz',
        'sicil_no': 'SICIL-001',
        'departman': 'Montaj',
        'fotograf_yolu': '/images/ahmet.jpg',
        'son_durum': 'Çalışıyor',
        'aktif': 1,
        'son_gorulme': '2026-08-21 09:00:00',
        'istasyon_adi': 'Istasyon-1',
      };

      final worker = WorkerModel.fromJson(json);

      expect(worker.id, 10);
      expect(worker.name, 'Ahmet Yılmaz');
      expect(worker.sicilNo, 'SICIL-001');
      expect(worker.department, 'Montaj');
      expect(worker.photoUrl, '/images/ahmet.jpg');
      expect(worker.status, 'Çalışıyor');
      expect(worker.isAktif, isTrue);
      expect(worker.lastSeen, '2026-08-21 09:00:00');
      expect(worker.lastStation, 'Istasyon-1');
    });

    test('fromJson handles null / missing fields safely with fallbacks', () {
      final json = <String, dynamic>{
        'id': '15', // string id
      };

      final worker = WorkerModel.fromJson(json);

      expect(worker.id, 15);
      expect(worker.name, 'Bilinmeyen İşçi');
      expect(worker.sicilNo, isNull);
      expect(worker.department, 'Genel Üretim');
      expect(worker.photoUrl, isNull);
      expect(worker.isAktif, isTrue);
      expect(worker.status, 'Aktif Çalışan');
    });

    test('toJson serializes model correctly', () {
      final worker = WorkerModel(
        id: 5,
        name: 'Mehmet Öz',
        sicilNo: 'SICIL-002',
        department: 'Kaynak',
        photoUrl: null,
        status: 'Pasif Çalışan',
        isAktif: false,
        lastSeen: '2026-08-20',
        lastStation: 'Istasyon-2',
      );

      final json = worker.toJson();

      expect(json['id'], 5);
      expect(json['ad_soyad'], 'Mehmet Öz');
      expect(json['sicil_no'], 'SICIL-002');
      expect(json['departman'], 'Kaynak');
      expect(json['aktif'], false);
      expect(json['istasyon_adi'], 'Istasyon-2');
    });
  });
}
