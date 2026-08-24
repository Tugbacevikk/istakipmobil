import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/alarm.dart';
import '../../providers/app_provider.dart';

class AlarmListScreen extends StatelessWidget {
  const AlarmListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        // Exclude video analysis file alarms
        final alarms = provider.alarms.where((a) {
          final msg = a.message.toLowerCase();
          final cam = (a.cameraName ?? '').toLowerCase();
          final isVideoFile = msg.contains('video') ||
              msg.contains('.mp4') ||
              msg.contains('.avi') ||
              msg.contains('.mkv') ||
              cam.contains('video') ||
              cam.contains('.mp4');
          return !isVideoFile;
        }).toList();

        final isDark = provider.isDarkMode;
        final bgColor = AppColors.getBg(isDark);
        final cardColor = AppColors.getCard(isDark);
        final textColor = AppColors.getText(isDark);
        final subTextColor = AppColors.getSubText(isDark);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.primary : AppColors.brandRedDark,
            title: const Text('Alarmlar & Saha İhlalleri', style: TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.done_all_rounded, color: AppColors.cyanAccent),
                onPressed: () async {
                  final ok = await ApiClient.markAlarmsRead();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? 'Tüm alarmlar okundu işaretlendi.' : 'İşlem gerçekleştirildi.'),
                        backgroundColor: ok ? AppColors.working : AppColors.accent,
                      ),
                    );
                    provider.refreshData();
                  }
                },
                tooltip: 'Tümünü Okundu İşaretle',
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: provider.refreshData,
              ),
            ],
          ),
          body: alarms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_rounded, size: 54, color: AppColors.working),
                      const SizedBox(height: 12),
                      Text(
                        'Şu anda bildirilen saha ihlali bulunmuyor.',
                        style: TextStyle(color: subTextColor, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alarms.length,
                  itemBuilder: (context, index) {
                    final alarm = alarms[index];
                    return _buildAlarmCard(context, alarm, cardColor, textColor, subTextColor);
                  },
                ),
        );
      },
    );
  }

  Widget _buildAlarmCard(BuildContext context, AlarmModel alarm, Color cardColor, Color textColor, Color subTextColor) {
    Color severityColor;
    if (alarm.severity == 'critical') {
      severityColor = AppColors.alarm;
    } else if (alarm.severity == 'warning') {
      severityColor = AppColors.idle;
    } else {
      severityColor = AppColors.accent;
    }

    final cameraText = (alarm.cameraName != null && alarm.cameraName!.trim().isNotEmpty)
        ? alarm.cameraName!.trim()
        : null;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: severityColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_rounded, color: severityColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          alarm.alarmType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: severityColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          alarm.severity.toUpperCase(),
                          style: TextStyle(
                            color: severityColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    alarm.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: subTextColor),
                      const SizedBox(width: 4),
                      Text(
                        alarm.timestamp,
                        style: TextStyle(color: subTextColor, fontSize: 11),
                      ),
                      if (cameraText != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.videocam_outlined, size: 14, color: subTextColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            cameraText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: subTextColor, fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Bildirim Bazlı Okundu İşaretleme Butonu
            IconButton(
              icon: Icon(
                alarm.isRead ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                color: alarm.isRead ? AppColors.working : AppColors.cyanAccent,
                size: 24,
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final provider = context.read<AppProvider>();
                final ok = await ApiClient.markSingleAlarmRead(alarm.id);
                final msg = ok ? 'İhlal bildirimi okundu olarak işaretlendi.' : 'İşlem gerçekleştirildi.';
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(msg),
                    backgroundColor: ok ? AppColors.working : AppColors.accent,
                    duration: const Duration(seconds: 2),
                  ),
                );
                provider.refreshData();
              },
              tooltip: alarm.isRead ? 'Okundu' : 'Bu Bildirimi Okundu İşaretle',
            ),
          ],
        ),
      ),
    );
  }
}
