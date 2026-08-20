import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'cameras/camera_stream_screen.dart';
import 'workers/worker_list_screen.dart';
import 'alarms/alarm_list_screen.dart';
import 'reports/reports_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    CameraStreamScreen(),
    WorkerListScreen(),
    AlarmListScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // Clean unread alarms count excluding video test files and already read alarms
    final cleanUnreadAlarms = provider.alarms.where((a) {
      final msg = a.message.toLowerCase();
      final cam = (a.cameraName ?? '').toLowerCase();
      return !a.isResolved &&
          !msg.contains('video:') &&
          !msg.contains('.mp4') &&
          !msg.contains('.avi') &&
          !cam.contains('video:') &&
          !cam.contains('.mp4');
    }).toList();

    final alarmCount = cleanUnreadAlarms.length;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Global Floating Top Notification Banner
          if (provider.latestAlarmMessage != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(14),
                color: AppColors.alarm,
                child: InkWell(
                  onTap: () {
                    setState(() => _currentIndex = 3);
                    provider.clearLatestAlarm();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '🚨 YENİ BİLDİRİM / İHLAL ALARMI!',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                provider.latestAlarmMessage!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'GÖRÜNTÜLE',
                            style: TextStyle(color: AppColors.alarm, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: provider.clearLatestAlarm,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 3 && provider.latestAlarmMessage != null) {
            provider.clearLatestAlarm();
          }
        },
        backgroundColor: AppColors.primary,
        selectedItemColor: AppColors.cyanAccent,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Özet'),
          const BottomNavigationBarItem(icon: Icon(Icons.videocam_rounded), label: 'Kameralar'),
          const BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'İşçiler'),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_rounded),
                if (alarmCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary, width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        alarmCount > 99 ? '99+' : '$alarmCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Alarmlar',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.insert_chart_rounded), label: 'Raporlar'),
        ],
      ),
    );
  }
}
