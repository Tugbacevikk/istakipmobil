import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../providers/app_provider.dart';

enum ReportFilterPeriod { today, yesterday, thisWeek, thisMonth, allTime }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  ReportFilterPeriod _selectedPeriod = ReportFilterPeriod.allTime;
  String _selectedStation = 'Tüm İstasyonlar';
  String _selectedWorker = 'Tüm Çalışanlar';

  double _workingMin = 0;
  double _idleMin = 0;
  double _weldingMin = 0;
  double _verimlilik = 0;
  int _totalAlarms = 0;
  int _totalWorkers = 0;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  (String, String) _getDateRange(ReportFilterPeriod period) {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');
    final todayStr = formatter.format(now);

    switch (period) {
      case ReportFilterPeriod.today:
        return (todayStr, todayStr);
      case ReportFilterPeriod.yesterday:
        final yest = now.subtract(const Duration(days: 1));
        final yestStr = formatter.format(yest);
        return (yestStr, yestStr);
      case ReportFilterPeriod.thisWeek:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return (formatter.format(monday), todayStr);
      case ReportFilterPeriod.thisMonth:
        final firstOfMonth = DateTime(now.year, now.month, 1);
        return (formatter.format(firstOfMonth), todayStr);
      case ReportFilterPeriod.allTime:
        return ('', '');
    }
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    final (start, end) = _getDateRange(_selectedPeriod);

    final istasyonParam = _selectedStation == 'Tüm İstasyonlar' ? '' : _selectedStation;
    final workerParam = _selectedWorker == 'Tüm Çalışanlar' ? '' : _selectedWorker;

    final data = await ApiClient.fetchReportSummary(
      start: start,
      end: end,
      istasyon: istasyonParam,
      worker: workerParam,
    );

    if (mounted) {
      setState(() {
        _workingMin = (data['aktif_sure_dk'] ?? 0).toDouble();
        _idleMin = (data['inaktif_sure_dk'] ?? 0).toDouble();
        _weldingMin = (data['kaynak_sure_dk'] ?? 0).toDouble();
        _verimlilik = (data['verimlilik_orani'] ?? 0).toDouble();
        _totalAlarms = (data['toplam_alarm'] ?? 0) is int
            ? data['toplam_alarm']
            : int.tryParse(data['toplam_alarm'].toString()) ?? 0;
        _totalWorkers = (data['toplam_calisan'] ?? 0) is int
            ? data['toplam_calisan']
            : int.tryParse(data['toplam_calisan'].toString()) ?? 0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // Build station dropdown options from cameras
    final stationOptions = <String>['Tüm İstasyonlar'];
    for (final cam in provider.cameras) {
      final sName = cam.name.trim();
      if (sName.isNotEmpty && !stationOptions.contains(sName)) {
        stationOptions.add(sName);
      }
    }
    if (!stationOptions.contains('Istasyon-1')) stationOptions.add('Istasyon-1');
    if (!stationOptions.contains('Istasyon-2')) stationOptions.add('Istasyon-2');
    if (!stationOptions.contains('Istasyon-3')) stationOptions.add('Istasyon-3');

    // Build worker dropdown options
    final workerOptions = <String>['Tüm Çalışanlar'];
    for (final w in provider.workers) {
      final wName = w.name.trim();
      if (wName.isNotEmpty && !workerOptions.contains(wName)) {
        workerOptions.add(wName);
      }
    }

    final totalMin = (_workingMin + _idleMin + _weldingMin) > 0 ? (_workingMin + _idleMin + _weldingMin) : 1.0;
    final workingPct = (_workingMin / totalMin * 100).toStringAsFixed(1);
    final idlePct = (_idleMin / totalMin * 100).toStringAsFixed(1);
    final weldingPct = (_weldingMin / totalMin * 100).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Raporlar & Saha Analitiği', style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadReportData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section (Tarih, İstasyon, Kişi)
          Container(
            color: AppColors.cardDark,
            padding: const EdgeInsets.only(top: 8, bottom: 12, left: 12, right: 12),
            child: Column(
              children: [
                // Tarih Filtresi Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tüm Zamanlar', ReportFilterPeriod.allTime),
                      const SizedBox(width: 6),
                      _buildFilterChip('Bugün', ReportFilterPeriod.today),
                      const SizedBox(width: 6),
                      _buildFilterChip('Dün', ReportFilterPeriod.yesterday),
                      const SizedBox(width: 6),
                      _buildFilterChip('Bu Hafta', ReportFilterPeriod.thisWeek),
                      const SizedBox(width: 6),
                      _buildFilterChip('Bu Ay', ReportFilterPeriod.thisMonth),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Dropdown Filters Row (İstasyon & Kişi Bazlı)
                Row(
                  children: [
                    // İstasyon Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.bgDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: stationOptions.contains(_selectedStation) ? _selectedStation : stationOptions.first,
                            isExpanded: true,
                            dropdownColor: AppColors.cardDark,
                            icon: const Icon(Icons.videocam_rounded, color: AppColors.cyanAccent, size: 18),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            items: stationOptions.map((String val) {
                              return DropdownMenuItem<String>(
                                value: val,
                                child: Text(val, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (newVal) {
                              if (newVal != null) {
                                setState(() => _selectedStation = newVal);
                                _loadReportData();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Kişi / Çalışan Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.bgDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: workerOptions.contains(_selectedWorker) ? _selectedWorker : workerOptions.first,
                            isExpanded: true,
                            dropdownColor: AppColors.cardDark,
                            icon: const Icon(Icons.person_rounded, color: Colors.orangeAccent, size: 18),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            items: workerOptions.map((String val) {
                              return DropdownMenuItem<String>(
                                value: val,
                                child: Text(val, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (newVal) {
                              if (newVal != null) {
                                setState(() => _selectedWorker = newVal);
                                _loadReportData();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Body Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _loadReportData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Aktivite & Süre Analitiği',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${_selectedStation != "Tüm İstasyonlar" ? _selectedStation : "Tüm Saha"} • ${_selectedWorker != "Tüm Çalışanlar" ? _selectedWorker : "Tüm İşçiler"}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Pie Chart Card
                          Container(
                            height: 220,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardDark,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: (_workingMin + _idleMin + _weldingMin) == 0
                                ? const Center(
                                    child: Text(
                                      'Seçilen filtreler için henüz veri kaydı bulunmuyor.',
                                      style: TextStyle(color: AppColors.textSecondary),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : PieChart(
                                    PieChartData(
                                      sectionsSpace: 4,
                                      centerSpaceRadius: 40,
                                      sections: [
                                        PieChartSectionData(
                                          color: AppColors.working,
                                          value: _workingMin > 0 ? _workingMin : 0.1,
                                          title: '%$workingPct',
                                          radius: 55,
                                          titleStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        PieChartSectionData(
                                          color: AppColors.idle,
                                          value: _idleMin > 0 ? _idleMin : 0.1,
                                          title: '%$idlePct',
                                          radius: 55,
                                          titleStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        PieChartSectionData(
                                          color: AppColors.welding,
                                          value: _weldingMin > 0 ? _weldingMin : 0.1,
                                          title: '%$weldingPct',
                                          radius: 55,
                                          titleStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 18),

                          // Verimlilik Kartı
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.8),
                                  const Color(0xFF1E293B),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Filtreli Verimlilik Oranı', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text('%$_verimlilik', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Kapsanan İşçi', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text('$_totalWorkers Kişi', style: const TextStyle(color: AppColors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Summary Stats Card List
                          _buildReportStatTile('Çalışma Süresi', '${_workingMin.toStringAsFixed(1)} dk (%$workingPct)', AppColors.working),
                          const SizedBox(height: 10),
                          _buildReportStatTile('Duruş Süresi', '${_idleMin.toStringAsFixed(1)} dk (%$idlePct)', AppColors.idle),
                          const SizedBox(height: 10),
                          _buildReportStatTile('Kaynak İşlemi Süresi', '${_weldingMin.toStringAsFixed(1)} dk (%$weldingPct)', AppColors.welding),
                          const SizedBox(height: 10),
                          _buildReportStatTile('Toplam İhlal / Alarm', '$_totalAlarms Kayıt', Colors.redAccent),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ReportFilterPeriod period) {
    final isSelected = _selectedPeriod == period;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.cardDark,
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.cardBorder),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPeriod = period);
          _loadReportData();
        }
      },
    );
  }

  Widget _buildReportStatTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
