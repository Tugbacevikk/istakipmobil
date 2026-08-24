import 'dart:async';
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
  bool _isDarkMode = true;
  String _serverUrl = SettingsStorage.defaultServerUrl;

  String _userRole = 'user';
  String _username = '';
  String? _latestAlarmMessage;
  Timer? _syncTimer;

  SystemStatus get status => _status;
  List<WorkerModel> get workers => _workers;
  List<AlarmModel> get alarms => _alarms;
  List<CameraModel> get cameras => _cameras;
  List<UserModel> get users => _users;

  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  bool get isDarkMode => _isDarkMode;
  String get serverUrl => _serverUrl;

  String get userRole => _userRole;
  String get username => _username;
  String? get latestAlarmMessage => _latestAlarmMessage;
  bool get isAdmin => _userRole == 'admin' || _username == 'admin';
  bool get isPatron => _userRole == 'patron' || _userRole == 'user';

  void clearLatestAlarm() {
    _latestAlarmMessage = null;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await SettingsStorage.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  AppProvider() {
    init();
  }

  Future<void> init() async {
    _isDarkMode = await SettingsStorage.isDarkMode();
    _serverUrl = await SettingsStorage.getServerUrl();
    _username = (await SettingsStorage.getUsername()) ?? '';
    _userRole = (await SettingsStorage.getUserRole()) ?? (_username == 'admin' ? 'admin' : 'patron');
    await checkConnectionAndFetch();
    _initSocket();
    _startSyncTimer();
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_isConnected) {
        refreshDataSilent();
      }
    });
  }

  String? _lastApiError;
  ApiErrorType _lastApiErrorType = ApiErrorType.none;

  String? get lastApiError => _lastApiError;
  ApiErrorType get lastApiErrorType => _lastApiErrorType;

  Future<void> updateServerUrl(String newUrl) async {
    await SettingsStorage.setServerUrl(newUrl);
    _serverUrl = await SettingsStorage.getServerUrl();
    notifyListeners();
    await checkConnectionAndFetch();
    _initSocket();
    _startSyncTimer();
  }

  Future<void> checkConnectionAndFetch() async {
    _isLoading = true;
    _lastApiError = null;
    _lastApiErrorType = ApiErrorType.none;
    notifyListeners();

    await refreshData();

    if (ApiClient.lastErrorType != ApiErrorType.none && _workers.isEmpty && _cameras.isEmpty) {
      _isConnected = false;
      _status = SystemStatus.initial();
      _lastApiErrorType = ApiClient.lastErrorType;
      _lastApiError = ApiClient.lastErrorMessage.isNotEmpty
          ? ApiClient.lastErrorMessage
          : 'Sunucuya ulaşılamadı. Lütfen sunucu IP adresini ve Wi-Fi bağlantınızı kontrol edin.';
    } else {
      _isConnected = true;
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
    final fetchedStatus = results[3] as SystemStatus;
    if (isAdmin && results.length > 4) {
      _users = results[4] as List<UserModel>;
    }

    _recalculateSystemStatus(fetchedStatus);
    notifyListeners();
  }

  void _recalculateSystemStatus(SystemStatus fetchedStatus) {
    final totalW = _workers.isNotEmpty ? _workers.length : fetchedStatus.totalWorkers;
    final int activeCamsCount = fetchedStatus.activeCamerasCount > 0
        ? fetchedStatus.activeCamerasCount
        : (_cameras.isNotEmpty ? _cameras.where((c) => c.isActive).length : (fetchedStatus.statusText.contains('Aktif') ? 1 : 0));

    final int liveWorking = fetchedStatus.workingCount;
    final int liveWelding = fetchedStatus.weldingCount;
    final int liveIdle = totalW >= liveWorking ? (totalW - liveWorking) : 0;

    final String statusText = activeCamsCount > 0
        ? '$activeCamsCount İstasyon / Kamera Aktif'
        : 'Kameralar Kapalı';

    _status = SystemStatus(
      totalWorkers: totalW,
      workingCount: liveWorking,
      idleCount: liveIdle,
      weldingCount: liveWelding,
      activeAlarmsCount: _alarms.length,
      activeCamerasCount: activeCamsCount,
      statusText: statusText,
      activeStation: fetchedStatus.activeStation,
      activeWorkerName: fetchedStatus.activeWorkerName,
    );
  }

  Future<void> refreshDataSilent() async {
    try {
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
      final fetchedStatus = results[3] as SystemStatus;
      if (isAdmin && results.length > 4) {
        _users = results[4] as List<UserModel>;
      }

      _recalculateSystemStatus(fetchedStatus);
      notifyListeners();
    } catch (_) {}
  }

  void _initSocket() {
    SocketService.connect(
      onNewAlarm: (data) {
        String msg = '🚨 YENİ ALARM TESPİT EDİLDİ!';
        if (data is Map && data.containsKey('aciklama')) {
          msg = '🚨 ${data['aciklama']}';
        } else if (data is Map && data.containsKey('message')) {
          msg = '🚨 ${data['message']}';
        }
        _latestAlarmMessage = msg;
        refreshDataSilent();
      },
    );
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
