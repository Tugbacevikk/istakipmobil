import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_provider.dart';

class CameraStreamScreen extends StatefulWidget {
  const CameraStreamScreen({super.key});

  @override
  State<CameraStreamScreen> createState() => _CameraStreamScreenState();
}

class _CameraStreamScreenState extends State<CameraStreamScreen> {
  int _selectedMode = 0; // 0 = Canlı Kamera, 1 = Video Analiz Et
  bool _isAnalyzing = false;
  String? _selectedVideo;
  final List<String> _uploadedVideos = [
    'ornek_kaynak_video.mp4',
    'saha_kamera_test.mp4',
  ];

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
            title: const Text('Kamera & Video Analizi', style: TextStyle(color: AppColors.textPrimary)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mode Tabs (Canlı Kamera vs Video Analiz - Matching Web Dashboard)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMode = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedMode == 0 ? AppColors.brandRedLight : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam_rounded,
                                  size: 18,
                                  color: _selectedMode == 0 ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Canlı Kamera',
                                  style: TextStyle(
                                    color: _selectedMode == 0 ? Colors.white : AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMode = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedMode == 1 ? AppColors.cyanAccent : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.video_file_rounded,
                                  size: 18,
                                  color: _selectedMode == 1 ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Video Analiz Et',
                                  style: TextStyle(
                                    color: _selectedMode == 1 ? Colors.white : AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Mode 0: Canlı Kamera
                if (_selectedMode == 0) ...[
                  if (cameras.isEmpty)
                    _buildNoCameraWidget(serverUrl)
                  else
                    ...cameras.map((camera) {
                      final streamUrl = '$serverUrl/api/video_feed?cam_id=${camera.id}';
                      return _buildCameraCard(camera.name, camera.source, streamUrl, camera.isActive);
                    }).toList(),
                ]

                // Mode 1: Video Analiz Et
                else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.smart_toy_rounded, color: AppColors.cyanAccent),
                            const SizedBox(width: 8),
                            const Text(
                              'Yapay Zeka Video Analiz Modu',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Saha kayıt videosu yükleyin veya kayıtlı videolardan seçerek YOLOv8 & Kaynak AI analizini başlatın.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 16),

                        // Dropdown for selecting uploaded video
                        DropdownButtonFormField<String>(
                          value: _selectedVideo,
                          dropdownColor: AppColors.cardDark,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Yüklenen Videolar',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.primary,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: _uploadedVideos
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedVideo = val),
                        ),
                        const SizedBox(height: 16),

                        // Action Buttons: Video Yükle & Analiz Et
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Video yükleme penceresi açıldı.'),
                                      backgroundColor: AppColors.cyanAccent,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.upload_file_rounded, color: AppColors.cyanAccent),
                                label: const Text('Video Yükle', style: TextStyle(color: AppColors.cyanAccent)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.cyanAccent),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() => _isAnalyzing = !_isAnalyzing);
                                },
                                icon: Icon(
                                  _isAnalyzing ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  _isAnalyzing ? 'Durdur' : 'Analizi Başlat',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isAnalyzing ? AppColors.alarm : AppColors.cyanAccent,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Video Stream Container
                  _buildCameraCard(
                    'Video AI Analiz Akışı',
                    _selectedVideo ?? 'Seçilen Video',
                    '$serverUrl/api/video_feed',
                    _isAnalyzing,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoCameraWidget(String serverUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.videocam_off_rounded, size: 52, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          const Text(
            'Kayıtlı aktif kamera bulunamadı.',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Sunucu: $serverUrl',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraCard(String name, String source, String streamUrl, bool isActive) {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.primary,
            child: Row(
              children: [
                const Icon(Icons.videocam_rounded, color: AppColors.brandRedLight),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.working.withOpacity(0.2) : AppColors.idle.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isActive ? 'CANLI / AKTİF' : 'PASİF',
                    style: TextStyle(
                      color: isActive ? AppColors.working : AppColors.idle,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                        'Kamera Görüntüsü Bekleniyor...',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kaynak: $source', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const Text('YOLOv8 Pose & Kaynak AI', style: TextStyle(color: AppColors.cyanAccent, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
