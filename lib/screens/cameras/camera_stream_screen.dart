import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/camera.dart';
import '../../providers/app_provider.dart';
import '../settings/camera_roi_settings_screen.dart';

class CameraStreamScreen extends StatelessWidget {
  const CameraStreamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final cameras = provider.cameras;
        final serverUrl = provider.serverUrl;

        return Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: const Text('Canlı Saha Kameraları', style: TextStyle(color: AppColors.textPrimary)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: provider.refreshData,
              ),
            ],
          ),
          body: SingleChildScrollView(
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
                              'Saha Kameraları (${cameras.length} Aktif Kanal)',
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Fabrika canlı kamera akışlarını 7/24 izleyebilirsiniz.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (cameras.isEmpty)
                  _buildNoCameraWidget(serverUrl)
                else
                  ...cameras.map((camera) {
                    final streamUrl = '$serverUrl/api/video_feed?cam_id=${camera.id}';
                    return _buildCameraCard(context, camera, streamUrl, provider.isAdmin);
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoCameraWidget(String serverUrl) {
    final defaultCameras = [
      {'name': 'Istasyon-1 (Kaynak Alanı)', 'id': 1},
      {'name': 'Istasyon-2 (Montaj Hattı)', 'id': 2},
      {'name': 'Istasyon-3 (Paketleme & Sevkiyat)', 'id': 3},
    ];

    return Column(
      children: defaultCameras.map((cam) {
        final streamUrl = '$serverUrl/api/video_feed?cam_id=${cam['id']}';
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
                          cam['name'].toString(),
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.working.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('CANLI', style: TextStyle(color: AppColors.working, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
              ),
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.black,
                child: Image.network(
                  streamUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF0F172A),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.videocam_off_rounded, color: AppColors.alarm, size: 42),
                          const SizedBox(height: 10),
                          Text(
                            '${cam['name']} Bağlantısı Hazırlanıyor...',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sunucu: $streamUrl',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
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
      }).toList(),
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
                      camera.name,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (isAdmin)
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_rounded, color: AppColors.alarm, size: 42),
                      const SizedBox(height: 10),
                      Text(
                        '${camera.name} Yayını Bekleniyor...',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        streamUrl,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
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
