import 'package:flutter/material.dart';
import '../models/system_status.dart';
import '../models/worker.dart';
import '../models/alarm.dart';
import '../models/camera.dart';
import '../models/user_model.dart';
import '../core/network/api_client.dart';
import '../core/network/socket_service.dart';
import '../core/storage/settings_storage.dart';

class AppProvider extends ChangeNotifier {
  SystemStatus _status = SystemStatus.initial();
  List<WorkerModel> _workers = [];
  List<AlarmModel> _alarms = [];
  List<CameraModel> _cameras = [];
  List<UserModel> _users = [];

  bool _isLoading = false;
  bool _isConnected = false;
  String _serverUrl = SettingsStorage.defaultServerUrl;

  String _userRole = 'user';
  String _username = '';

  SystemStatus get status => _status;
  List<WorkerModel> get workers => _workers;
  List<AlarmModel> get alarms => _alarms;
  List<CameraModel> get cameras => _cameras;
  List<UserModel> get users => _users;

  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String get serverUrl => _serverUrl;

  String get userRole => _userRole;
  String get username => _username;
  bool get isAdmin => _userRole == 'admin' || _username == 'admin';
  bool get isPatron => _userRole == 'patron' || _userRole == 'user';

  AppProvider() {
    init();
  }

  Future<void> init() async {
    _serverUrl = await SettingsStorage.getServerUrl();
    _username = (await SettingsStorage.getUsername()) ?? '';
    _userRole = (await SettingsStorage.getUserRole()) ?? (_username == 'admin' ? 'admin' : 'patron');
    await checkConnectionAndFetch();
    _initSocket();
  }

  Future<void> updateServerUrl(String newUrl) async {
    await SettingsStorage.setServerUrl(newUrl);
    _serverUrl = await SettingsStorage.getServerUrl();
    notifyListeners();
    await checkConnectionAndFetch();
    _initSocket();
  }

  Future<void> checkConnectionAndFetch() async {
    _isLoading = true;
    notifyListeners();

    _isConnected = await ApiClient.testConnection(_serverUrl);
    if (_isConnected) {
      await refreshData();
    } else {
      _status = SystemStatus.initial();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshData() async {
    _username = (await SettingsStorage.getUsername()) ?? '';
    _userRole = (await SettingsStorage.getUserRole()) ?? (_username == 'admin' ? 'admin' : 'patron');

    final results = await Future.wait([
      ApiClient.fetchWorkers(),
      ApiClient.fetchAlarms(),
      ApiClient.fetchCameras(),
      ApiClient.fetchSystemStatus(),
      if (isAdmin) ApiClient.fetchUsers(),
    ]);

    _workers = results[0] as List<WorkerModel>;
    _alarms = results[1] as List<AlarmModel>;
    _cameras = results[2] as List<CameraModel>;
    _status = results[3] as SystemStatus;
    if (isAdmin && results.length > 4) {
      _users = results[4] as List<UserModel>;
    }

    notifyListeners();
  }

  void _initSocket() {
    SocketService.init(_serverUrl);
  }
}
