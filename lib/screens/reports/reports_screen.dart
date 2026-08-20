import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final status = provider.status;
        final totalWorkers = status.totalWorkers > 0 ? status.totalWorkers : provider.workers.length;
        final workingCount = status.totalWorkers > 0 
            ? status.workingCount 
            : provider.workers.where((w) => w.status == 'Çalışıyor' || w.status == 'aktif' || w.status == '1').length;
        final idleCount = status.totalWorkers > 0 
            ? status.idleCount 
            : provider.workers.where((w) => w.status == 'Duruşta' || w.status == '0').length;
        final weldingCount = status.totalWorkers > 0 
            ? status.weldingCount 
            : provider.workers.where((w) => w.status.contains('Kaynak')).length;

        final total = totalWorkers > 0 ? totalWorkers : 1;
        final workingPct = (workingCount / total * 100).toStringAsFixed(1);
        final idlePct = (idleCount / total * 100).toStringAsFixed(1);
        final weldingPct = (weldingCount / total * 100).toStringAsFixed(1);

        return Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: const Text('Raporlar & Saha Analitiği', style: TextStyle(color: AppColors.textPrimary)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aktivite & Durum Dağılımı',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Pie Chart
                Container(
                  height: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: totalWorkers == 0
                      ? const Center(
                          child: Text(
                            'Grafik için henüz yeterli veri yok.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(
                                color: AppColors.working,
                                value: (workingCount > 0 ? workingCount : 1).toDouble(),
                                title: '%$workingPct',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              PieChartSectionData(
                                color: AppColors.idle,
                                value: idleCount.toDouble(),
                                title: '%$idlePct',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              PieChartSectionData(
                                color: AppColors.welding,
                                value: weldingCount.toDouble(),
                                title: '%$weldingPct',
                                radius: 50,
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
                const SizedBox(height: 20),

                // Summary Stats Card List
                _buildReportStatTile('Çalışan İşçiler', '$workingCount Kişi (%$workingPct)', AppColors.working),
                const SizedBox(height: 10),
                _buildReportStatTile('Duruştaki İşçiler', '$idleCount Kişi (%$idlePct)', AppColors.idle),
                const SizedBox(height: 10),
                _buildReportStatTile('Kaynak İşlemi Yapanlar', '$weldingCount Kişi (%$weldingPct)', AppColors.welding),
              ],
            ),
          ),
        );
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
