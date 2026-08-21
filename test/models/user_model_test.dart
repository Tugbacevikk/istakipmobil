import 'package:flutter_test/flutter_test.dart';
import 'package:istakipmobil/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    test('fromJson parses complete valid user JSON correctly', () {
      final json = {
        'id': 12,
        'kullanici_adi': 'patron1',
        'ad_soyad': 'Patron Mehmet',
        'email': 'patron@ucge.com',
        'rol': 'patron',
        'durum': 'onaylandi',
        'firma_adi': 'ÜÇGE A.Ş.',
        'istasyonlar': 'Istasyon-1,Istasyon-2',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 12);
      expect(user.kullaniciAdi, 'patron1');
      expect(user.adSoyad, 'Patron Mehmet');
      expect(user.email, 'patron@ucge.com');
      expect(user.rol, 'patron');
      expect(user.durum, 'onaylandi');
      expect(user.firmaAdi, 'ÜÇGE A.Ş.');
      expect(user.istasyonlar, 'Istasyon-1,Istasyon-2');
    });

    test('fromJson handles missing fields with default values', () {
      final json = <String, dynamic>{
        'id': '99',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 99);
      expect(user.kullaniciAdi, 'kullanici');
      expect(user.adSoyad, 'Kullanıcı');
      expect(user.email, isNull);
      expect(user.rol, 'patron');
      expect(user.durum, 'bekliyor');
      expect(user.firmaAdi, isNull);
      expect(user.istasyonlar, isNull);
    });

    test('toJson serializes UserModel correctly', () {
      final user = UserModel(
        id: 1,
        kullaniciAdi: 'admin',
        adSoyad: 'Sistem Yöneticisi',
        email: 'admin@ucge.com',
        rol: 'admin',
        durum: 'onaylandi',
        firmaAdi: 'ÜÇGE',
        istasyonlar: 'Istasyon-1,Istasyon-2,Istasyon-3,Istasyon-4',
      );

      final json = user.toJson();

      expect(json['id'], 1);
      expect(json['kullanici_adi'], 'admin');
      expect(json['ad_soyad'], 'Sistem Yöneticisi');
      expect(json['email'], 'admin@ucge.com');
      expect(json['rol'], 'admin');
      expect(json['durum'], 'onaylandi');
      expect(json['firma_adi'], 'ÜÇGE');
      expect(json['istasyonlar'], 'Istasyon-1,Istasyon-2,Istasyon-3,Istasyon-4');
    });
  });
}
