import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_provider.dart';
import '../settings/server_settings_screen.dart';
import '../users/user_management_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final status = provider.status;
        final isConnected = provider.isConnected;

        return Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: Row(
              children: [
                const Icon(Icons.precision_manufacturing_rounded, color: AppColors.accent),
                const SizedBox(width: 10),
                const Text(
                  'İş Takip Sahası',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.manage_accounts_rounded, color: AppColors.textPrimary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                  );
                },
                tooltip: 'Kullanıcı & Yönetici Hesapları',
              ),
              IconButton(
                icon: Icon(
                  isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: isConnected ? AppColors.working : AppColors.alarm,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ServerSettingsScreen()),
                  );
                },
                tooltip: 'Sunucu Bağlantı Durumu',
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
                onPressed: provider.refreshData,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: provider.refreshData,
            color: AppColors.accent,
            backgroundColor: AppColors.cardDark,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connection Banner
                  _buildConnectionBanner(context, isConnected, provider.serverUrl),
                  const SizedBox(height: 16),

                  // Overview Heading
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Canlı Saha Özet Bilgileri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Toplam: ${status.totalWorkers} İşçi',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3 KPI Cards: Working, Idle, Welding
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Çalışıyor',
                          count: status.workingCount,
                          color: AppColors.working,
                          icon: Icons.engineering_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Duruşta',
                          count: status.idleCount,
                          color: AppColors.idle,
                          icon: Icons.timer_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Kaynak',
                          count: status.weldingCount,
                          color: AppColors.welding,
                          icon: Icons.local_fire_department_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Alarms & Cameras Summary Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryTile(
                          title: 'Aktif Alarmlar',
                          value: '${provider.alarms.length}',
                          icon: Icons.notifications_active_rounded,
                          color: provider.alarms.isEmpty ? AppColors.working : AppColors.alarm,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryTile(
                          title: 'İstasyon / Kamera',
                          value: '${provider.cameras.length}',
                          icon: Icons.videocam_rounded,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent Alarms Feed
                  const Text(
                    'Son Alarmlar & Saha Uyarıları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (provider.alarms.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.check_circle_outline_rounded, color: AppColors.working, size: 44),
                          SizedBox(height: 8),
                          Text(
                            'Saha Güvenli. Aktif alarm veya ihlal bulunmuyor.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.alarms.length > 5 ? 5 : provider.alarms.length,
                      itemBuilder: (context, index) {
                        final alarm = provider.alarms[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.alarm.withOpacity(0.4)),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.alarm.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.warning_amber_rounded, color: AppColors.alarm),
                            ),
                            title: Text(
                              alarm.alarmType,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${alarm.message} • ${alarm.timestamp}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionBanner(BuildContext context, bool isConnected, String serverUrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isConnected ? AppColors.working.withOpacity(0.12) : AppColors.alarm.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isConnected ? AppColors.working : AppColors.alarm),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: isConnected ? AppColors.working : AppColors.alarm,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Sunucu Bağlantısı Aktif' : 'Sunucuya Bağlanılamadı',
                  style: TextStyle(
                    color: isConnected ? AppColors.working : AppColors.alarm,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  serverUrl,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServerSettingsScreen()),
              );
            },
            child: const Text('Değiştir', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                title,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
