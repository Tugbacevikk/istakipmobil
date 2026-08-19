import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.primary,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Özet'),
          BottomNavigationBarItem(icon: Icon(Icons.videocam_rounded), label: 'Kameralar'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'İşçiler'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Alarmlar'),
          BottomNavigationBarItem(icon: Icon(Icons.insert_chart_rounded), label: 'Raporlar'),
        ],
      ),
    );
  }
}
