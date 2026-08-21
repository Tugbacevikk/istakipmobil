import 'package:flutter_test/flutter_test.dart';
import 'package:istakipmobil/models/camera.dart';

void main() {
  group('CameraModel Tests', () {
    test('fromJson parses valid camera JSON correctly', () {
      final json = {
        'id': 1,
        'istasyon_adi': 'Montaj Kamera 1',
        'ip_adresi': 'http://192.168.1.100:5000/video_feed',
        'aktif': 1,
        'konum': 'Montaj Alanı',
      };

      final camera = CameraModel.fromJson(json);

      expect(camera.id, 1);
      expect(camera.name, 'Montaj Kamera 1');
      expect(camera.source, 'http://192.168.1.100:5000/video_feed');
      expect(camera.ipAddress, 'http://192.168.1.100:5000/video_feed');
      expect(camera.isActive, isTrue);
      expect(camera.location, 'Montaj Alanı');
    });

    test('fromJson handles null and missing fields with fallback values', () {
      final json = <String, dynamic>{
        'id': 5,
      };

      final camera = CameraModel.fromJson(json);

      expect(camera.id, 5);
      expect(camera.name, 'Kamera 5');
      expect(camera.source, '0');
      expect(camera.isActive, isFalse);
      expect(camera.location, 'Fabrika Sahası');
      expect(camera.ipAddress, isNull);
    });

    test('toJson serializes CameraModel correctly', () {
      final camera = CameraModel(
        id: 2,
        name: 'Kaynak Kamera 2',
        source: 'http://192.168.1.102:5000/video_feed',
        isActive: true,
        location: 'Kaynak Atölyesi',
        ipAddress: 'http://192.168.1.102:5000/video_feed',
      );

      final json = camera.toJson();

      expect(json['id'], 2);
      expect(json['istasyon_adi'], 'Kaynak Kamera 2');
      expect(json['ip_adresi'], 'http://192.168.1.102:5000/video_feed');
      expect(json['aktif'], 1);
      expect(json['konum'], 'Kaynak Atölyesi');
    });
  });
}
