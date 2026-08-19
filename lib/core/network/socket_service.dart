import 'package:socket_io_client/socket_io_client.dart' as io;
import '../storage/settings_storage.dart';

typedef SocketEventCallback = void Function(dynamic data);

class SocketService {
  static io.Socket? _socket;
  static bool _isConnected = false;

  static bool get isConnected => _isConnected;

  static Future<void> connect({
    SocketEventCallback? onStatusUpdate,
    SocketEventCallback? onNewAlarm,
  }) async {
    final serverUrl = await SettingsStorage.getServerUrl();

    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
    }

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
    });

    if (onStatusUpdate != null) {
      _socket!.on('status_update', onStatusUpdate);
      _socket!.on('durum_guncelleme', onStatusUpdate);
    }

    if (onNewAlarm != null) {
      _socket!.on('new_alarm', onNewAlarm);
      _socket!.on('yeni_alarm', onNewAlarm);
    }

    _socket!.connect();
  }

  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
    }
  }
}
