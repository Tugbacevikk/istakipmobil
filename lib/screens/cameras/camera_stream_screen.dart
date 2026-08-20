import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/camera.dart';
import '../../providers/app_provider.dart';
import '../settings/camera_roi_settings_screen.dart';

class CameraStreamScreen extends StatefulWidget {
  const CameraStreamScreen({super.key});

  @override
  State<CameraStreamScreen> createState() => _CameraStreamScreenState();
}

class _CameraStreamScreenState extends State<CameraStreamScreen> {
  final _stationController = TextEditingController();
  final _ipController = TextEditingController();
  bool _isSubmitting = false;

  void _showAddCameraDialog(BuildContext context) {
    _stationController.text = 'Istasyon-${DateTime.now().second}';
    _ipController.text = '127.0.0.1';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Row(
          children: const [
            Icon(Icons.add_a_photo_rounded, color: AppColors.cyanAccent),
            SizedBox(width: 8),
            Text('Yeni Kamera / Yayın Ekle', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _stationController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'İstasyon / Kamera Adı',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ipController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Kamera IP veya Yerel Adres (Örn: 127.0.0.1)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final name = _stationController.text.trim();
              final ip = _ipController.text.trim();
              if (name.isNotEmpty && ip.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() => _isSubmitting = true);
                final success = await ApiClient.addCamera(name, ip);
                setState(() => _isSubmitting = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '"$name" kamerasını başarıyla eklendi.' : 'Kamera eklenirken bir hata oluştu.'),
                      backgroundColor: success ? AppColors.working : AppColors.alarm,
                    ),
                  );
                  context.read<AppProvider>().refreshData();
                }
              }
            },
            child: const Text('Ekle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteCamera(BuildContext context, int camId, String camName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Kamerayı Sil', style: TextStyle(color: Colors.white)),
        content: Text('"$camName" kamerasını kaldırmak istiyor musunuz?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alarm),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSubmitting = true);
      final success = await ApiClient.deleteCamera(camId);
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '"$camName" silindi.' : 'Kamera silinemedi.'),
            backgroundColor: success ? AppColors.working : AppColors.alarm,
          ),
        );
        context.read<AppProvider>().refreshData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final cameras = provider.cameras;
        final serverUrl = provider.serverUrl;
        final isAdmin = provider.isAdmin;

        return Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: const Text('Canlı Saha Kameraları', style: TextStyle(color: AppColors.textPrimary)),
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.add_circle_rounded, color: Colors.white),
                  onPressed: () => _showAddCameraDialog(context),
                  tooltip: 'Kamera / Yayın Ekle',
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: provider.refreshData,
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cyanAccent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.videocam_rounded, color: AppColors.cyanAccent, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saha Kameraları (${cameras.length} Kanal Bağlı)',
                                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isAdmin ? 'Yerel veya IP kameraların canlı akışını izleyin ve yönetin.' : 'Yetkili olduğunuz kameraların 7/24 canlı akışı.',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Default Localhost Camera (Ana Sunucu / Webcam Akışı)
                    _buildLocalhostWebcamCard(context, serverUrl, isAdmin),
                    const SizedBox(height: 16),

                    if (cameras.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Kayıtlı diğer ek kameralar yükleniyor...',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...cameras.map((camera) {
                        final proxyUrl = '$serverUrl/api/proxy_feed/${camera.id}';
                        return _buildCameraCard(context, camera, proxyUrl, isAdmin);
                      }),
                  ],
                ),
              ),
              if (_isSubmitting)
                Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocalhostWebcamCard(BuildContext context, String serverUrl, bool isAdmin) {
    final streamUrl = '$serverUrl/video_feed';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.camera_front_rounded, color: AppColors.cyanAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Ana Sunucu Kamera Yayını (Localhost)',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.working.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('CANLI YAYIN', style: TextStyle(color: AppColors.working, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),
          Container(
            height: 220,
            width: double.infinity,
            color: Colors.black,
            child: Image.network(
              streamUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF0F172A),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_rounded, color: AppColors.cyanAccent, size: 42),
                      const SizedBox(height: 10),
                      const Text(
                        'Ana Sunucu Görüntü Yayını Hazır',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Yayın Adresi: $streamUrl',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraCard(BuildContext context, CameraModel camera, String streamUrl, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.videocam_rounded, color: AppColors.cyanAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${camera.name} (${camera.ipAddress ?? "Yerel IP"})',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (isAdmin) ...[
                      IconButton(
                        icon: const Icon(Icons.tune_rounded, color: AppColors.cyanAccent, size: 20),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CameraRoiSettingsScreen(
                                cameraName: camera.name,
                                streamUrl: streamUrl,
                              ),
                            ),
                          );
                        },
                        tooltip: 'ROI / Bölge Ayarları',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.alarm, size: 20),
                        onPressed: () => _handleDeleteCamera(context, camera.id, camera.name),
                        tooltip: 'Kamerayı Sil',
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: camera.isActive ? AppColors.working.withValues(alpha: 0.15) : AppColors.alarm.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        camera.isActive ? 'CANLI' : 'KAPALI',
                        style: TextStyle(
                          color: camera.isActive ? AppColors.working : AppColors.alarm,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 220,
            width: double.infinity,
            color: Colors.black,
            child: Image.network(
              streamUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF0F172A),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_rounded, color: AppColors.textSecondary, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        '${camera.name} Yayını (${camera.ipAddress ?? "Yerel Ağ"})',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        streamUrl,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
