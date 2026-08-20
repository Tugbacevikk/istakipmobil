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

  static Future<List<AlarmModel>> fetchAlarms() async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.get('/api/alarms');
      final data = _parseResponseData(response.data);

      if (response.statusCode == 200) {
        if (data is List) {
          return data.map((x) => AlarmModel.fromJson(Map<String, dynamic>.from(x))).toList();
        } else if (data is Map) {
          final list = data['alarms'] ?? data['data'];
          if (list is List) {
            return list.map((x) => AlarmModel.fromJson(Map<String, dynamic>.from(x))).toList();
          }
        }
      }
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
            return list.map((x) => CameraModel.fromJson(x)).toList();
          }
        }
      }
    } catch (_) {}
    return [];
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
        await SettingsStorage.setSession(isLoggedIn: true, username: username, role: 'admin');
        return true;
      }

      final testResponse = await dio.get(
        '/api/camera/status',
        options: Options(extra: {'withCredentials': true}),
      );

      if (testResponse.statusCode == 200) {
        await SettingsStorage.setSession(isLoggedIn: true, username: username, role: 'admin');
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
