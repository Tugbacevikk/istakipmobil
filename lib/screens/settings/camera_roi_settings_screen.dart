import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CameraRoiSettingsScreen extends StatefulWidget {
  final String? cameraName;
  final String? streamUrl;

  const CameraRoiSettingsScreen({
    super.key,
    this.cameraName,
    this.streamUrl,
  });

  @override
  State<CameraRoiSettingsScreen> createState() => _CameraRoiSettingsScreenState();
}

class _CameraRoiSettingsScreenState extends State<CameraRoiSettingsScreen> {
  final double _roiX = 0.10;
  final double _roiY = 0.15;
  final double _roiWidth = 0.80;
  final double _roiHeight = 0.70;
  double _alarmThresholdSeconds = 10;
  bool _weldingDetectionEnabled = true;
  bool _poseEstimationEnabled = true;

  @override
  Widget build(BuildContext context) {
    final titleName = widget.cameraName ?? 'Kamera ROI & Bölge';

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(titleName, style: const TextStyle(color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam_rounded, size: 48, color: AppColors.cyanAccent),
                        const SizedBox(height: 8),
                        Text(
                          'Kamera Görüntü Önizleme (${widget.cameraName ?? "Istasyon-1"})',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: _roiX * 300,
                    top: _roiY * 180,
                    width: _roiWidth * 300,
                    height: _roiHeight * 180,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.redAccent, width: 2),
                        color: Colors.redAccent.withValues(alpha: 0.2),
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          color: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: const Text(
                            'ROI BÖLGESİ (Tehlikeli Alan)',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Yapay Zeka Tespiti & Alarm Ayarları',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Kaynak Yapma Algılama AI', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Görüntüdeki kaynak alevi ve kaskını tespit eder', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              value: _weldingDetectionEnabled,
              activeThumbColor: AppColors.primary,
              onChanged: (val) => setState(() => _weldingDetectionEnabled = val),
            ),
            SwitchListTile(
              title: const Text('İnsan İskelet & Duruş Analizi (Pose Estimation)', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Yatarak veya hareketsiz duruşlarda alarm üretir', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              value: _poseEstimationEnabled,
              activeThumbColor: AppColors.primary,
              onChanged: (val) => setState(() => _poseEstimationEnabled = val),
            ),
            const SizedBox(height: 12),

            Text(
              'Hareketsizlik Alarm Eşiği: ${_alarmThresholdSeconds.toInt()} Saniye',
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _alarmThresholdSeconds,
              min: 5,
              max: 60,
              divisions: 11,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _alarmThresholdSeconds = val),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: const Text('Bölge Ayarlarını Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bölge ayarları kaydedildi.'),
                      backgroundColor: AppColors.working,
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
