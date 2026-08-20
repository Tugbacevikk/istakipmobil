import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CameraRoiSettingsScreen extends StatefulWidget {
  const CameraRoiSettingsScreen({super.key});

  @override
  State<CameraRoiSettingsScreen> createState() => _CameraRoiSettingsScreenState();
}

class _CameraRoiSettingsScreenState extends State<CameraRoiSettingsScreen> {
  double _roiX = 0.10;
  double _roiY = 0.15;
  double _roiWidth = 0.80;
  double _roiHeight = 0.70;
  double _alarmThresholdSeconds = 10;
  bool _weldingDetectionEnabled = true;
  bool _poseEstimationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Kamera & ROI Bölge Ayarları', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bölge (ROI - Region of Interest) Ayarları',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kameraların takip edeceği istasyon çalışma sınırlarını ve ihlal alarm eşiklerini özelleştirin.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Visual ROI Box Preview
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.videocam_rounded, color: Colors.white24, size: 64),
                  ),
                  Positioned(
                    left: 200 * _roiX,
                    top: 200 * _roiY,
                    width: 300 * _roiWidth,
                    height: 200 * _roiHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cyanAccent.withOpacity(0.2),
                        border: Border.all(color: AppColors.cyanAccent, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          'ROI İstasyon Bölgesi',
                          style: TextStyle(color: AppColors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ROI Sliders
            _buildSlider('İstasyon X Konumu', _roiX, (v) => setState(() => _roiX = v)),
            _buildSlider('İstasyon Y Konumu', _roiY, (v) => setState(() => _roiY = v)),
            _buildSlider('Duruş Alarm Eşiği (${_alarmThresholdSeconds.toInt()} sn)', _alarmThresholdSeconds / 60, (v) {
              setState(() => _alarmThresholdSeconds = (v * 60).clamp(5, 60));
            }),
            const SizedBox(height: 16),

            // AI Model Switches
            SwitchListTile(
              title: const Text('YOLOv8 Kaynak (Welding) Tespiti', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Kıvılcım ve kaynak işlemlerini otomatik algıla', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              value: _weldingDetectionEnabled,
              activeColor: AppColors.cyanAccent,
              onChanged: (v) => setState(() => _weldingDetectionEnabled = v),
            ),
            SwitchListTile(
              title: const Text('YOLOv8 Pose Estimation (Duruş Takibi)', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('İskelet ve pozisyon takibi yap', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              value: _poseEstimationEnabled,
              activeColor: AppColors.cyanAccent,
              onChanged: (v) => setState(() => _poseEstimationEnabled = v),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ROI ve Yapay Zeka ayarları kaydedildi.'), backgroundColor: AppColors.working),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: const Text('AYARLARI KAYDET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandRedLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String title, double val, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Slider(
          value: val,
          onChanged: onChanged,
          activeColor: AppColors.cyanAccent,
          inactiveColor: AppColors.cardBorder,
        ),
      ],
    );
  }
}
