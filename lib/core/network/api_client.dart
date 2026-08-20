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

  static Future<Dio> _getSharedDio() async {
    if (_dio != null) return _dio!;

    final baseUrl = await SettingsStorage.getServerUrl();

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      followRedirects: false,
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
      if (response.statusCode == 200 && response.data != null) {
        return SystemStatus.fromJson(response.data);
      }
    } catch (_) {}
    return SystemStatus.initial();
  }

  static Future<List<WorkerModel>> fetchWorkers() async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.get('/api/workers');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((x) => WorkerModel.fromJson(x)).toList();
      } else if (response.statusCode == 200 && response.data is Map && response.data['workers'] != null) {
        return (response.data['workers'] as List).map((x) => WorkerModel.fromJson(x)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<AlarmModel>> fetchAlarms() async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.get('/api/alarms');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((x) => AlarmModel.fromJson(x)).toList();
      } else if (response.statusCode == 200 && response.data is Map && response.data['alarms'] != null) {
        return (response.data['alarms'] as List).map((x) => AlarmModel.fromJson(x)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<UserModel>> fetchUsers() async {
    final dio = await _getSharedDio();
    try {
      final response = await dio.get('/api/users');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((x) => UserModel.fromJson(x)).toList();
      } else if (response.statusCode == 200 && response.data is Map && response.data['users'] != null) {
        return (response.data['users'] as List).map((x) => UserModel.fromJson(x)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<CameraModel>> fetchCameras() async {
    try {
      final dio = await _getSharedDio();
      final response = await dio.get('/api/cameras/manage');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((x) => CameraModel.fromJson(x)).toList();
      } else if (response.statusCode == 200 && response.data is Map && response.data['cameras'] != null) {
        return (response.data['cameras'] as List).map((x) => CameraModel.fromJson(x)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> login(String username, String password) async {
    final dio = await _getSharedDio();
    try {
      await dio.post(
        '/login',
        data: FormData.fromMap({
          'username': username,
          'password': password,
        }),
      );
      final testResponse = await dio.get('/api/camera/status');
      if (testResponse.statusCode == 200) {
        await SettingsStorage.setSession(isLoggedIn: true, username: username, role: '');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
