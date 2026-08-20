import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import '../storage/settings_storage.dart';
import '../../models/system_status.dart';
import '../../models/worker.dart';
import '../../models/alarm.dart';
import '../../models/camera.dart';
import '../../models/user_model.dart';

class ApiClient {
  static Dio? _dio;
  static PersistCookieJar? _cookieJar;

  static dynamic _parseResponseData(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  static Future<Dio> _getSharedDio() async {
    if (_dio != null) return _dio!;

    final baseUrl = await SettingsStorage.getServerUrl();

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      followRedirects: true,
      extra: {'withCredentials': true},
      validateStatus: (status) => status != null && status < 500,
    ));

    if (!kIsWeb) {
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        _cookieJar = PersistCookieJar(
          storage: FileStorage('${appDocDir.path}/.cookies/'),
        );
        _dio!.interceptors.add(CookieManager(_cookieJar!));
      } catch (_) {}
    }

    return _dio!;
  }

  static Future<void> resetClient() async {
    _dio = null;
    if (_cookieJar != null && !kIsWeb) {
      try {
        await _cookieJar!.deleteAll();
      } catch (_) {}
    }
    _cookieJar = null;
  }

  static Future<bool> testConnection(String targetUrl) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: targetUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        extra: {'withCredentials': true},
        validateStatus: (status) => status != null && status < 500,
      ));
      final response = await dio.get('/api/camera/status');
      return response.statusCode != null && response.statusCode! < 500;
    } catch (_) {
      try {
        final dio = Dio(BaseOptions(
          baseUrl: targetUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          extra: {'withCredentials': true},
          validateStatus: (status) => status != null && status < 500,
        ));
        final response = await dio.get('/');
        return response.statusCode != null && response.statusCode! < 500;
      } catch (_) {
        return false;
      }
    }
  }

  static Future<SystemStatus> fetchSystemStatus() async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.get('/api/camera/status');
      final data = _parseResponseData(response.data);
      if (response.statusCode == 200 && data != null && data is Map) {
        return SystemStatus.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    try {
      final dio = await _getSharedDio();
      final response = await dio.get('/api/status');
      final data = _parseResponseData(response.data);
      if (response.statusCode == 200 && data != null && data is Map) {
        return SystemStatus.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    return SystemStatus.initial();
  }

  static Future<List<WorkerModel>> fetchWorkers() async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.get('/api/workers');
      final data = _parseResponseData(response.data);

      if (response.statusCode == 200) {
        if (data is List) {
          return data.map((x) => WorkerModel.fromJson(Map<String, dynamic>.from(x))).toList();
        } else if (data is Map) {
          final list = data['workers'] ?? data['data'];
          if (list is List) {
            return list.map((x) => WorkerModel.fromJson(Map<String, dynamic>.from(x))).toList();
          }
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> addWorker({
    required String ad,
    required String soyad,
    required String sicilNo,
    required String departman,
    required String istasyonAdi,
  }) async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.post(
        '/api/workers',
        data: {
          'ad': ad,
          'soyad': soyad,
          'sicil_no': sicilNo,
          'departman': departman,
          'istasyon_adi': istasyonAdi,
        },
      );
      final data = _parseResponseData(response.data);
      if (response.statusCode == 200 && data is Map && data['success'] == true) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> deleteWorker(int workerId) async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.post('/api/workers/$workerId/delete');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> toggleWorkerAktif(int workerId) async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.post('/api/workers/$workerId/toggle-aktif');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<AlarmModel>> fetchAlarms() async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.get('/api/alarms');
      final data = _parseResponseData(response.data);

      List<AlarmModel> rawList = [];
      if (response.statusCode == 200) {
        if (data is List) {
          rawList = data.map((x) => AlarmModel.fromJson(Map<String, dynamic>.from(x))).toList();
        } else if (data is Map) {
          final list = data['alarms'] ?? data['data'];
          if (list is List) {
            rawList = list.map((x) => AlarmModel.fromJson(Map<String, dynamic>.from(x))).toList();
          }
        }
      }

      // Exclude video analysis file alarms (only real-time camera/station alarms)
      return rawList.where((a) {
        final msg = a.message.toLowerCase();
        final cam = (a.cameraName ?? '').toLowerCase();
        return !msg.contains('video:') &&
            !msg.contains('.mp4') &&
            !msg.contains('.avi') &&
            !cam.contains('video:') &&
            !cam.contains('.mp4');
      }).toList();
    } catch (_) {}
    return [];
  }

  static Future<List<UserModel>> fetchUsers() async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.get('/api/users');
      final data = _parseResponseData(response.data);

      if (response.statusCode == 200) {
        if (data is List) {
          return data.map((x) => UserModel.fromJson(Map<String, dynamic>.from(x))).toList();
        } else if (data is Map) {
          final list = data['users'] ?? data['data'];
          if (list is List) {
            return list.map((x) => UserModel.fromJson(Map<String, dynamic>.from(x))).toList();
          }
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> approveUser(int userId, {List<String>? selectedStations}) async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.post(
        '/api/users/$userId/approve',
        data: {
          'stations': selectedStations ?? ['Istasyon-1', 'Istasyon-2', 'Istasyon-3', 'Istasyon-4'],
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> rejectUser(int userId) async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.post('/api/users/$userId/reject');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteUser(int userId) async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.post('/api/users/$userId/delete');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<CameraModel>> fetchCameras() async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.get('/api/cameras/manage');
      final data = _parseResponseData(response.data);

      if (response.statusCode == 200) {
        if (data is List) {
          return data.map((x) => CameraModel.fromJson(Map<String, dynamic>.from(x))).toList();
        } else if (data is Map) {
          final list = data['cameras'] ?? data['data'];
          if (list is List) {
            return list.map((x) => CameraModel.fromJson(Map<String, dynamic>.from(x))).toList();
          }
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> addCamera(String istasyonAdi, String ipAdresi) async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.post(
        '/api/cameras/manage',
        data: {
          'istasyon_adi': istasyonAdi,
          'ip_adresi': ipAdresi,
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteCamera(int camId) async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.post('/api/cameras/manage/$camId');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> fetchReportSummary({
    String? start,
    String? end,
    String? istasyon,
    String? worker,
  }) async {
    try {
      final dio = await _getSharedDio();
      final queryParams = <String, dynamic>{};
      if (start != null && start.isNotEmpty) queryParams['start'] = start;
      if (end != null && end.isNotEmpty) queryParams['end'] = end;
      if (istasyon != null && istasyon.isNotEmpty) queryParams['istasyon'] = istasyon;
      if (worker != null && worker.isNotEmpty) queryParams['worker'] = worker;

      final response = await dio.get('/api/reports/summary', queryParameters: queryParams);
      final data = _parseResponseData(response.data);
      if (response.statusCode == 200 && data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {}
    return {};
  }

  static Future<List<Map<String, dynamic>>> fetchReportDetailStats({
    String? start,
    String? end,
    String? istasyon,
    String? worker,
  }) async {
    try {
      final dio = await _getSharedDio();
      final queryParams = <String, dynamic>{};
      if (start != null && start.isNotEmpty) queryParams['start'] = start;
      if (end != null && end.isNotEmpty) queryParams['end'] = end;
      if (istasyon != null && istasyon.isNotEmpty) queryParams['istasyon'] = istasyon;
      if (worker != null && worker.isNotEmpty) queryParams['worker'] = worker;

      final response = await dio.get('/api/reports/worker_stats', queryParameters: queryParams);
      final data = _parseResponseData(response.data);
      if (response.statusCode == 200) {
        if (data is List) {
          return data.map((x) => Map<String, dynamic>.from(x)).toList();
        } else if (data is Map) {
          final list = data['workers'] ?? data['data'];
          if (list is List) {
            return list.map((x) => Map<String, dynamic>.from(x)).toList();
          }
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> updateProfileEmail(String email) async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.post(
        '/api/profile/update_email',
        data: {'email': email},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.post(
        '/api/profile/change_password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirm': newPassword,
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> markAlarmsRead() async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.post('/api/alarms/mark_read');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> registerUser({
    required String username,
    required String password,
    required String adSoyad,
    required String email,
    required String firmaAdi,
  }) async {
    try {
      final dio = await _getSharedDio();
      final formString = 'username=${Uri.encodeQueryComponent(username)}&password=${Uri.encodeQueryComponent(password)}&password_confirm=${Uri.encodeQueryComponent(password)}&ad_soyad=${Uri.encodeQueryComponent(adSoyad)}&email=${Uri.encodeQueryComponent(email)}&firma_adi=${Uri.encodeQueryComponent(firmaAdi)}';

      final response = await dio.post(
        '/register',
        data: formString,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
      final text = response.data?.toString() ?? '';
      return response.statusCode == 200 || text.contains('bekleniyor') || text.contains('Giriş');
    } catch (_) {
      return false;
    }
  }

  static Future<String> _detectRole(Dio dio) async {
    try {
      final res = await dio.get('/api/users', options: Options(validateStatus: (s) => true));
      if (res.statusCode == 200) return 'admin';
    } catch (_) {}
    return 'patron';
  }

  static Future<bool> login(String username, String password) async {
    final dio = await _getSharedDio();
    try {
      final formString = 'username=${Uri.encodeQueryComponent(username)}&password=${Uri.encodeQueryComponent(password)}&kullanici_adi=${Uri.encodeQueryComponent(username)}&sifre=${Uri.encodeQueryComponent(password)}';

      final loginRes = await dio.post(
        '/login',
        data: formString,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          followRedirects: true,
          extra: {'withCredentials': true},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final bodyText = loginRes.data?.toString() ?? '';
      
      if (bodyText.contains('Dashboard') || loginRes.realUri.path.contains('dashboard')) {
        final userRole = await _detectRole(dio);
        await SettingsStorage.setSession(isLoggedIn: true, username: username, role: userRole);
        return true;
      }

      final testResponse = await dio.get(
        '/api/camera/status',
        options: Options(extra: {'withCredentials': true}),
      );

      if (testResponse.statusCode == 200) {
        final userRole = await _detectRole(dio);
        await SettingsStorage.setSession(isLoggedIn: true, username: username, role: userRole);
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
