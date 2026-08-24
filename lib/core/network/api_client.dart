import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import '../storage/settings_storage.dart';
import 'api_response.dart';
import '../../models/system_status.dart';
import '../../models/worker.dart';
import '../../models/alarm.dart';
import '../../models/camera.dart';
import '../../models/user_model.dart';

export 'api_response.dart';

class ApiClient {
  static Dio? _dio;
  static PersistCookieJar? _cookieJar;

  static String lastErrorMessage = '';
  static ApiErrorType lastErrorType = ApiErrorType.none;
  static int? lastStatusCode;

  static void _clearError() {
    lastErrorMessage = '';
    lastErrorType = ApiErrorType.none;
    lastStatusCode = null;
  }

  static void _setError(dynamic e) {
    if (e is DioException) {
      lastStatusCode = e.response?.statusCode;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        lastErrorType = ApiErrorType.connection;
        lastErrorMessage = 'Sunucuya ulaşılamadı. Lütfen Wi-Fi ve IP adresinizi kontrol edin.';
        return;
      }
      final response = e.response;
      if (response != null) {
        final code = response.statusCode;
        if (code == 401) {
          lastErrorType = ApiErrorType.unauthorized;
          lastErrorMessage = 'Oturum süreniz doldu (401). Lütfen tekrar giriş yapın.';
          return;
        } else if (code == 403) {
          lastErrorType = ApiErrorType.unauthorized;
          lastErrorMessage = 'Bu işlem için yetkiniz bulunmuyor (403).';
          return;
        } else if (code == 400) {
          lastErrorType = ApiErrorType.badRequest;
          final data = _parseResponseData(response.data);
          if (data is Map && data.containsKey('error')) {
            lastErrorMessage = data['error'].toString();
          } else {
            lastErrorMessage = 'Geçersiz işlem veya hatalı bilgi (400).';
          }
          return;
        } else if (code != null && code >= 500) {
          lastErrorType = ApiErrorType.server;
          lastErrorMessage = 'Sunucu hatası ($code). Lütfen sistem yöneticisiyle iletişime geçin.';
          return;
        }
      }
      lastErrorType = ApiErrorType.connection;
      lastErrorMessage = 'Ağ/Sunucu bağlantı hatası: ${e.message ?? "Sunucuya ulaşılamadı"}';
      return;
    }
    lastErrorType = ApiErrorType.unknown;
    lastErrorMessage = 'Beklenmeyen bir hata oluştu: ${e.toString()}';
  }

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
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 4),
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
    _clearError();
  }

  static Future<bool> testConnection(String targetUrl) async {
    _clearError();
    try {
      final dio = Dio(BaseOptions(
        baseUrl: targetUrl,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
        extra: {'withCredentials': true},
        validateStatus: (status) => status != null && status < 500,
      ));
      final response = await dio.get('/api/camera/status');
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      _setError(e);
      try {
        final dio = Dio(BaseOptions(
          baseUrl: targetUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          extra: {'withCredentials': true},
          validateStatus: (status) => status != null && status < 500,
        ));
        final response = await dio.get('/');
        if (response.statusCode == 200) {
          _clearError();
          return true;
        }
      } catch (ex) {
        _setError(ex);
        return false;
      }
    }
    lastErrorType = ApiErrorType.connection;
    lastErrorMessage = 'Sunucuya ulaşılamadı. Lütfen sunucu IP adresini kontrol edin.';
    return false;
  }

  static Future<SystemStatus> fetchSystemStatus() async {
    _clearError();
    try {
      final dio = await _getSharedDio();
      final response = await dio.get('/api/camera/status');
      final data = _parseResponseData(response.data);
      if (response.statusCode == 200 && data != null && data is Map) {
        return SystemStatus.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      _setError(e);
    }
    try {
      final dio = await _getSharedDio();
      final response = await dio.get('/api/status');
      final data = _parseResponseData(response.data);
      if (response.statusCode == 200 && data != null && data is Map) {
        _clearError();
        return SystemStatus.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      _setError(e);
    }
    return SystemStatus.initial();
  }

  static Future<List<WorkerModel>> fetchWorkers() async {
    _clearError();
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
            return list.map((x) => Map<String, dynamic>.from(x)).map((x) => WorkerModel.fromJson(x)).toList();
          }
        }
      }
      lastErrorType = ApiErrorType.connection;
      lastErrorMessage = 'Sunucuya ulaşılamadı (${response.statusCode}).';
    } catch (e) {
      _setError(e);
    }
    return [];
  }

  static Future<bool> addWorker({
    required String ad,
    required String soyad,
    required String sicilNo,
    required String departman,
    required String istasyonAdi,
  }) async {
    _clearError();
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
      if (data is Map && data.containsKey('error')) {
        lastErrorMessage = data['error'].toString();
        lastErrorType = ApiErrorType.badRequest;
      }
    } catch (e) {
      _setError(e);
    }
    return false;
  }

  static Future<bool> deleteWorker(int workerId) async {
    _clearError();
    try {
      final dio = await _getSharedDio();
      final response = await dio.post('/api/workers/$workerId/delete');
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      _setError(e);
    }
    return false;
  }

  static Future<bool> toggleWorkerAktif(int workerId) async {
    _clearError();
    try {
      final dio = await _getSharedDio();
      final response = await dio.post('/api/workers/$workerId/toggle-aktif');
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      _setError(e);
    }
    return false;
  }

  static Future<List<AlarmModel>> fetchAlarms() async {
    _clearError();
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
      } else {
        lastErrorType = ApiErrorType.connection;
        lastErrorMessage = 'Sunucuya ulaşılamadı (${response.statusCode}).';
      }

      return rawList.where((a) {
        final msg = a.message.toLowerCase();
        final cam = (a.cameraName ?? '').toLowerCase();
        final isVideoFile = msg.contains('video') ||
            msg.contains('.mp4') ||
            msg.contains('.avi') ||
            msg.contains('.mkv') ||
            cam.contains('video') ||
            cam.contains('.mp4');
        return !isVideoFile;
      }).toList();
    } catch (e) {
      _setError(e);
    }
    return [];
  }

  static Future<List<UserModel>> fetchUsers() async {
    _clearError();
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
    } catch (e) {
      _setError(e);
    }
    return [];
  }

  static Future<bool> approveUser(int userId, {List<String>? selectedStations}) async {
    _clearError();

    List<String> stationsToSubmit = selectedStations != null ? List<String>.from(selectedStations) : [];

    if (stationsToSubmit.isEmpty) {
      final dynamicCameras = await fetchCameras();
      stationsToSubmit = dynamicCameras.map((c) => c.name).where((n) => n.isNotEmpty).toList();
    }

    if (stationsToSubmit.isEmpty) {
      lastErrorType = ApiErrorType.badRequest;
      lastErrorMessage = 'En az bir istasyon seçilmelidir.';
      return false;
    }

    try {
      final dio = await _getSharedDio();
      final response = await dio.post(
        '/api/users/$userId/approve',
        data: {
          'stations': stationsToSubmit,
        },
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      _setError(e);
    }
    return false;
  }

  static Future<bool> rejectUser(int userId) async {
    _clearError();
    try {
      final dio = await _getSharedDio();
      final response = await dio.post('/api/users/$userId/reject');
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      _setError(e);
    }
    return false;
  }

  static Future<bool> deleteUser(int userId) async {
    _clearError();
    try {
      final dio = await _getSharedDio();
      final response = await dio.post('/api/users/$userId/delete');
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      _setError(e);
    }
    return false;
  }

  static Future<List<CameraModel>> fetchCameras() async {
    _clearError();
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
    } catch (e) {
      _setError(e);
    }
    return [];
  }

  static Future<bool> addCamera(String istasyonAdi, String ipAdresi) async {
    _clearError();
    try {
      final dio = await _getSharedDio();
      final response = await dio.post(
        '/api/cameras/manage',
        data: {
          'istasyon_adi': istasyonAdi,
          'ip_adresi': ipAdresi,
        },
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      _setError(e);
    }
    return false;
  }

  static Future<bool> deleteCamera(int camId) async {
    _clearError();
    try {
      final dio = await _getSharedDio();
      final response = await dio.post('/api/cameras/manage/$camId');
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      _setError(e);
    }
    return false;
  }

  static Future<Map<String, dynamic>> fetchReportSummary({
    String? start,
    String? end,
    String? istasyon,
    String? worker,
  }) async {
    _clearError();
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
    } catch (e) {
      _setError(e);
    }
    return {};
  }

  static Future<List<Map<String, dynamic>>> fetchReportDetailStats({
    String? start,
    String? end,
    String? istasyon,
    String? worker,
  }) async {
    _clearError();
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
    } catch (e) {
      _setError(e);
    }
    return [];
  }

  static Future<List<Map<String, String>>> fetchMailRecipients() async {
    _clearError();
    try {
      final dio = await _getSharedDio();
      final response = await dio.get('/api/users/mail_recipients');
      final data = _parseResponseData(response.data);

      if (response.statusCode == 200) {
        if (data is List) {
          return data
              .map((x) => Map<String, String>.from(
                  (x as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))))
              .toList();
        } else if (data is Map && data['recipients'] is List) {
          final list = data['recipients'] as List;
          return list
              .map((x) => Map<String, String>.from(
                  (x as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))))
              .toList();
        }
      }
    } catch (e) {
      _setError(e);
    }
    return [];
  }

  static Future<bool> sendReportEmail({
    required List<String> emails,
    String? start,
    String? end,
    String? istasyon,
    String? worker,
  }) async {
    _clearError();
    try {
      final dio = await _getSharedDio();
      final response = await dio.post(
        '/api/reports/email_pdf',
        data: {
          'emails': emails,
          'start_date': start ?? '',
          'end_date': end ?? '',
          'istasyon': istasyon ?? '',
          'worker': worker ?? '',
        },
      );
      final data = _parseResponseData(response.data);
      if (response.statusCode == 200 && data is Map && data['success'] == true) {
        return true;
      }
      if (data is Map && data.containsKey('message')) {
        lastErrorMessage = data['message'].toString();
      } else if (data is Map && data.containsKey('error')) {
        lastErrorMessage = data['error'].toString();
      }
    } catch (e) {
      _setError(e);
    }
    return false;
  }

  static Future<bool> updateProfileEmail(String email) async {
    _clearError();
    try {
      final dio = await _getSharedDio();
      final response = await dio.post(
        '/api/profile/update_email',
        data: {'email': email},
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      _setError(e);
    }
    return false;
  }

  static Future<bool> changePassword(String currentPassword, String newPassword) async {
    _clearError();
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
      final data = _parseResponseData(response.data);
      if (response.statusCode == 200 && data is Map && data['success'] == true) {
        return true;
      }
      if (data is Map && data.containsKey('error')) {
        lastErrorMessage = data['error'].toString();
        lastErrorType = ApiErrorType.badRequest;
      }
    } catch (e) {
      _setError(e);
    }
    return false;
  }

  static Future<bool> markAlarmsRead() async {
    _clearError();
    try {
      final dio = await _getSharedDio();
      final response = await dio.post('/api/alarms/mark_read');
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      _setError(e);
    }
    return false;
  }

  static Future<bool> markSingleAlarmRead(dynamic alarmId) async {
    _clearError();
    try {
      final dio = await _getSharedDio();
      final response = await dio.post('/api/alarms/$alarmId/mark_read');
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      _setError(e);
    }
    return false;
  }

  static Future<bool> markSingleAlarmUnread(dynamic alarmId) async {
    _clearError();
    try {
      final dio = await _getSharedDio();
      final response = await dio.post('/api/alarms/$alarmId/mark_unread');
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      _setError(e);
    }
    return false;
  }

  static Future<bool> registerUser({
    required String username,
    required String password,
    required String adSoyad,
    required String email,
    required String firmaAdi,
  }) async {
    _clearError();
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
      if (response.statusCode == 200 || text.contains('bekleniyor') || text.contains('Giriş')) {
        return true;
      }
    } catch (e) {
      _setError(e);
    }
    return false;
  }

  static Future<bool> login(String username, String password) async {
    _clearError();
    final dio = await _getSharedDio();

    // 1. Primary approach: Try JSON API Endpoint (/api/login)
    try {
      final res = await dio.post(
        '/api/login',
        data: {
          'username': username,
          'password': password,
          'kullanici_adi': username,
          'sifre': password,
        },
        options: Options(
          extra: {'withCredentials': true},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final data = _parseResponseData(res.data);
      if (res.statusCode == 200 && data is Map && data['success'] == true) {
        final userData = data['user'] as Map?;
        final role = (userData?['rol'] ?? userData?['role'] ?? (username.trim().toLowerCase() == 'admin' ? 'admin' : 'patron')).toString();
        await SettingsStorage.setSession(isLoggedIn: true, username: username, role: role);
        return true;
      } else if (data is Map && data.containsKey('error')) {
        lastErrorType = ApiErrorType.badRequest;
        lastErrorMessage = data['error'].toString();
        return false;
      }
    } catch (_) {}

    // 2. Secondary approach: Form post to /login and verify session via /api/me JSON endpoint
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

      // Verify logged in session via /api/me endpoint
      final sessionRes = await dio.get(
        '/api/me',
        options: Options(
          extra: {'withCredentials': true},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final sessionData = _parseResponseData(sessionRes.data);
      if (sessionRes.statusCode == 200 && sessionData is Map && sessionData['success'] == true) {
        final userData = sessionData['user'] as Map?;
        final role = (userData?['rol'] ?? userData?['role'] ?? (username.trim().toLowerCase() == 'admin' ? 'admin' : 'patron')).toString();
        await SettingsStorage.setSession(isLoggedIn: true, username: username, role: role);
        return true;
      }

      // Check camera status endpoint as final fallback if session cookie was established
      if (loginRes.statusCode == 200) {
        final testResponse = await dio.get(
          '/api/camera/status',
          options: Options(
            extra: {'withCredentials': true},
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (testResponse.statusCode == 200) {
          final role = (username.trim().toLowerCase() == 'admin') ? 'admin' : 'patron';
          await SettingsStorage.setSession(isLoggedIn: true, username: username, role: role);
          return true;
        }
      }

      lastErrorType = ApiErrorType.badRequest;
      lastErrorMessage = 'Giriş başarısız! Kullanıcı adı veya şifre hatalı.';
      return false;
    } catch (e) {
      _setError(e);
      return false;
    }
  }
}
