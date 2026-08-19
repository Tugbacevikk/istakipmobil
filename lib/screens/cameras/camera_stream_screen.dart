import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_provider.dart';

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
            title: const Text('Canlı İstasyon & Kamera Akışı', style: TextStyle(color: AppColors.textPrimary)),
          ),
          body: cameras.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_outlined, size: 54, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      const Text(
                        'Kayıtlı aktif kamera bulunamadı.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sunucu: $serverUrl',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cameras.length,
                  itemBuilder: (context, index) {
                    final camera = cameras[index];
                    final streamUrl = '$serverUrl/api/video_feed?cam_id=${camera.id}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stream Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            color: AppColors.primary,
                            child: Row(
                              children: [
                                const Icon(Icons.videocam_rounded, color: AppColors.accent),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    camera.name,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: camera.isActive
                                        ? AppColors.working.withOpacity(0.2)
                                        : AppColors.idle.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    camera.isActive ? 'CANLI' : 'PASİF',
                                    style: TextStyle(
                                      color: camera.isActive ? AppColors.working : AppColors.idle,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Stream Preview / Image Frame
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              streamUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.black,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.videocam_off_rounded, color: AppColors.alarm, size: 42),
                                      SizedBox(height: 8),
                                      Text(
                                        'Canlı Görüntü Akışı Bekleniyor...',
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          // Stream Footer Info
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Kaynak: ${camera.source}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                                Text(
                                  'Konum: ${camera.location ?? 'Saha'}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
