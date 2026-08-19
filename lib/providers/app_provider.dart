import 'package:flutter/material.dart';
import '../models/system_status.dart';
import '../models/worker.dart';
import '../models/alarm.dart';
import '../models/camera.dart';
import '../core/network/api_client.dart';
import '../core/network/socket_service.dart';
import '../core/storage/settings_storage.dart';

class AppProvider extends ChangeNotifier {
  SystemStatus _status = SystemStatus.initial();
  List<WorkerModel> _workers = [];
  List<AlarmModel> _alarms = [];
  List<CameraModel> _cameras = [];

  bool _isLoading = false;
  bool _isConnected = false;
  String _serverUrl = SettingsStorage.defaultServerUrl;

  SystemStatus get status => _status;
  List<WorkerModel> get workers => _workers;
  List<AlarmModel> get alarms => _alarms;
  List<CameraModel> get cameras => _cameras;

  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String get serverUrl => _serverUrl;

  AppProvider() {
    init();
  }

  Future<void> init() async {
    _serverUrl = await SettingsStorage.getServerUrl();
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
    _status = await ApiClient.fetchSystemStatus();
    _workers = await ApiClient.fetchWorkers();
    _alarms = await ApiClient.fetchAlarms();
    _cameras = await ApiClient.fetchCameras();
    notifyListeners();
  }

  void _initSocket() {
    SocketService.connect(
      onStatusUpdate: (data) {
        refreshData();
      },
      onNewAlarm: (data) {
        refreshData();
      },
    );
  }

  @override
  void dispose() {
    SocketService.disconnect();
    super.dispose();
  }
}
