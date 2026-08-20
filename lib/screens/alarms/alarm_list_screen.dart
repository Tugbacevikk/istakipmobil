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
          return !msg.contains('video:') &&
              !msg.contains('.mp4') &&
              !msg.contains('.avi') &&
              !cam.contains('video:') &&
              !cam.contains('.mp4');
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: const Text('Alarmlar & Saha İhlalleri', style: TextStyle(color: AppColors.textPrimary)),
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
                    children: const [
                      Icon(Icons.shield_rounded, size: 54, color: AppColors.working),
                      SizedBox(height: 12),
                      Text(
                        'Aktif alarm veya ihlal bulunmuyor.',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tüm saha güvenlik şartları normal.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alarms.length,
                  itemBuilder: (context, index) {
                    final alarm = alarms[index];
                    return _buildAlarmTile(alarm);
                  },
                ),
        );
      },
    );
  }

  Widget _buildAlarmTile(AlarmModel alarm) {
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
      color: AppColors.cardDark,
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
                          style: const TextStyle(
                            color: AppColors.textPrimary,
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
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        alarm.timestamp,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      if (cameraText != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.videocam_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            cameraText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
