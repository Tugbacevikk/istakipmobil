import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/settings_storage.dart';
import '../../models/alarm.dart';
import '../../providers/app_provider.dart';
import '../auth/login_screen.dart';
import '../profile/profile_settings_screen.dart';
import '../settings/server_settings_screen.dart';
import '../users/user_management_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showConnectionBanner = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isConnected = provider.isConnected;
    final status = provider.status;
    final isDark = provider.isDarkMode;

    final bgColor = AppColors.getBg(isDark);
    final cardColor = AppColors.getCard(isDark);
    final textColor = AppColors.getText(isDark);
    final subTextColor = AppColors.getSubText(isDark);
    final borderColor = AppColors.getBorder(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.primary : AppColors.brandRedDark,
        title: Row(
          children: [
            const Icon(Icons.dashboard_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    provider.isAdmin ? 'Admin' : 'Patron (${provider.username})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Wifi Icon Toggles Sunucu Bağlantı Kartı (Açılır-Kapanır)
          IconButton(
            icon: Icon(
              isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color: isConnected ? AppColors.working : AppColors.alarm,
            ),
            onPressed: () {
              setState(() {
                _showConnectionBanner = !_showConnectionBanner;
              });
            },
            tooltip: _showConnectionBanner ? 'Sunucu Kartını Kapat' : 'Sunucu Kartını Göster',
          ),

          // Yenile İkonu
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: provider.refreshData,
            tooltip: 'Verileri Yenile',
          ),

          // Açılır-Kapanır PopUp Döküm Menüsü
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            color: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()));
              } else if (value == 'users') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen()));
              } else if (value == 'server') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ServerSettingsScreen()));
              } else if (value == 'theme') {
                provider.toggleTheme();
              } else if (value == 'logout') {
                await SettingsStorage.logout();
                await ApiClient.resetClient();
                if (context.mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                      color: isDark ? Colors.amber : AppColors.cyanAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isDark ? '☀️ Aydınlık Tema' : '🌙 Koyu Tema',
                      style: TextStyle(color: textColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, color: AppColors.cyanAccent, size: 20),
                    const SizedBox(width: 10),
                    Text('Profil & Şifre Ayarları', style: TextStyle(color: textColor, fontSize: 13)),
                  ],
                ),
              ),
              if (provider.isAdmin)
                PopupMenuItem(
                  value: 'users',
                  child: Row(
                    children: [
                      const Icon(Icons.manage_accounts_rounded, color: AppColors.working, size: 20),
                      const SizedBox(width: 10),
                      Text('Üye & Patron Onayları', style: TextStyle(color: textColor, fontSize: 13)),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'server',
                child: Row(
                  children: [
                    const Icon(Icons.dns_rounded, color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 10),
                    Text('Sunucu IP / Port Ayarları', style: TextStyle(color: textColor, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout_rounded, color: AppColors.alarm, size: 20),
                    SizedBox(width: 10),
                    Text('Oturumu Kapat', style: TextStyle(color: AppColors.alarm, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.refreshData,
        color: AppColors.accent,
        backgroundColor: cardColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Instant Alarm Banner Notification
              if (provider.latestAlarmMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.alarm.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.alarm, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, color: AppColors.alarm, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⚠️ CANLI SAHA UYARISI',
                              style: TextStyle(color: AppColors.alarm, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              provider.latestAlarmMessage!,
                              style: TextStyle(color: textColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor, size: 18),
                        onPressed: provider.clearLatestAlarm,
                      ),
                    ],
                  ),
                ),

              // Collapsible Connection Banner (Açılır-Kapanır Kart)
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _showConnectionBanner ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _buildConnectionBanner(context, isConnected, provider.serverUrl, provider.lastApiError, cardColor, textColor, subTextColor, borderColor),
                ),
              ),

              // Section Heading: Günlük Saha Analitiği & Performans
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Günlük Saha Analitiği & Performans',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'GÜNCEL METRİKLER',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Daily Analytics Grid (Option 1)
              _buildAnalyticsCards(context, provider, cardColor, textColor, subTextColor, borderColor),
              const SizedBox(height: 20),

              // Alarms Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Son Alarmlar & Saha Uyarıları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  if (provider.alarms.isNotEmpty)
                    Text(
                      '${provider.alarms.length} İhlal',
                      style: const TextStyle(color: AppColors.alarm, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Alarms List
              if (provider.alarms.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: AppColors.working, size: 42),
                      const SizedBox(height: 8),
                      Text(
                        'Sahada aktif alarm bulunmuyor.',
                        style: TextStyle(color: subTextColor, fontSize: 14),
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
                    return _buildAlarmTile(alarm, cardColor, textColor, subTextColor, borderColor);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionBanner(
    BuildContext context,
    bool isConnected,
    String serverUrl,
    String? lastApiError,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isConnected ? AppColors.working.withValues(alpha: 0.12) : AppColors.alarm.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? AppColors.working.withValues(alpha: 0.4) : AppColors.alarm.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isConnected ? AppColors.working.withValues(alpha: 0.2) : AppColors.alarm.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: isConnected ? AppColors.working : AppColors.alarm,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected
                      ? 'Sunucu Bağlantısı Aktif'
                      : (lastApiError ?? 'Sunucuya Bağlanılamadı'),
                  style: TextStyle(
                    color: isConnected ? AppColors.working : AppColors.alarm,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  serverUrl,
                  style: TextStyle(color: subTextColor, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 30)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServerSettingsScreen()),
              );
            },
            child: const Text('Değiştir', style: TextStyle(color: AppColors.alarm, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCards(
    BuildContext context,
    AppProvider provider,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    final status = provider.status;
    final int totalWorkers = status.totalWorkers > 0 ? status.totalWorkers : provider.workers.length;
    final int workingCount = status.workingCount;
    final int idleCount = status.idleCount;
    final int activeAlarms = provider.alarms.length;
    final int activeCams = status.activeCamerasCount;
    final int totalCams = provider.cameras.isNotEmpty ? provider.cameras.length : 2;

    final double efficiency = totalWorkers > 0 ? ((workingCount / totalWorkers) * 100) : 0.0;
    final String efficiencyText = '%${efficiency.toStringAsFixed(0)} ${efficiency >= 50 ? "Yüksek" : "Normal"}';

    return Column(
      children: [
        // Analytics Card 1: Toplam Çalışan & Vardiya Metriği
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saha Çalışan Durumu',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kayıtlı İşçi & Vardiya Dağılımı',
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$workingCount / $totalWorkers Aktif',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '$idleCount Çalışan Boşta',
                    style: TextStyle(color: subTextColor, fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Analytics Card 2: Saha Verimlilik Oranı
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.working.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.working.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.insights_rounded, color: AppColors.working, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saha Verimlilik Oranı',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Anlık Operasyon Başarı Oranı',
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    efficiencyText,
                    style: const TextStyle(color: AppColors.working, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    workingCount > 0 ? 'Aktif Operasyon Var' : 'Saha Beklemede',
                    style: TextStyle(color: subTextColor, fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Analytics Card 3: Saha Kameraları
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cyanAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: AppColors.cyanAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saha Kameraları',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '7/24 Kesintisiz AI Takibi',
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$activeCams / $totalCams Kamera CANLI',
                    style: const TextStyle(color: AppColors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    activeCams > 0 ? 'Yayınlar Aktif' : 'Kameralar Kapalı',
                    style: TextStyle(
                      color: activeCams > 0 ? AppColors.working : subTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildSecondaryKpiCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmTile(
    AlarmModel alarm,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    final stationName = alarm.cameraName ?? 'Istasyon-1';
    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.alarm.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded, color: AppColors.alarm, size: 20),
        ),
        title: Text(
          alarm.alarmType,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${alarm.message} ($stationName) • ${alarm.timestamp}',
          style: TextStyle(color: subTextColor, fontSize: 11),
        ),
      ),
    );
  }
}
