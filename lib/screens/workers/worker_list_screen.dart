import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/worker.dart';
import '../../providers/app_provider.dart';

class WorkerListScreen extends StatefulWidget {
  const WorkerListScreen({super.key});

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  String _searchQuery = '';
  String _filterStatus = 'Tümü';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final workers = provider.workers.where((worker) {
          final matchesSearch = worker.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (worker.sicilNo?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
              (worker.lastStation?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

          if (_filterStatus == 'Tümü') return matchesSearch;
          if (_filterStatus == 'Çalışıyor') {
            return matchesSearch && (worker.status.contains('Çalış') || worker.status.contains('Calis'));
          }
          if (_filterStatus == 'Duruşta') {
            return matchesSearch && (worker.status.contains('Duruş') || worker.status.contains('Durus'));
          }
          if (_filterStatus == 'Kaynak Yapıyor') {
            return matchesSearch && worker.status.contains('Kaynak');
          }
          return matchesSearch;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: const Text('İşçi Listesi & Saha Durumları', style: TextStyle(color: AppColors.textPrimary)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => provider.refreshData(),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search & Filter Header
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.cardDark,
                child: Column(
                  children: [
                    TextField(
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'İşçi Adı, Sicil No veya İstasyon ile Ara...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.bgDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Tümü', 'Çalışıyor', 'Duruşta', 'Kaynak Yapıyor'].map((filter) {
                          final isSelected = _filterStatus == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                filter,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.bgDark,
                              onSelected: (selected) {
                                if (selected) setState(() => _filterStatus = filter);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Worker List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : workers.isEmpty
                        ? const Center(
                            child: Text(
                              'Kayıtlı işçi bulunamadı.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: workers.length,
                            itemBuilder: (context, index) {
                              return _buildWorkerCard(workers[index]);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkerCard(WorkerModel worker) {
    Color statusColor;
    IconData statusIcon;

    if (worker.status.toLowerCase().contains('calis') || worker.status.toLowerCase().contains('çalış')) {
      statusColor = AppColors.working;
      statusIcon = Icons.engineering_rounded;
    } else if (worker.status.toLowerCase().contains('kaynak')) {
      statusColor = AppColors.welding;
      statusIcon = Icons.local_fire_department_rounded;
    } else {
      statusColor = AppColors.idle;
      statusIcon = Icons.timer_rounded;
    }

    final stationName = (worker.lastStation != null && worker.lastStation!.trim().isNotEmpty)
        ? worker.lastStation!.trim()
        : 'İstasyon Atanmadı';

    return Card(
      color: AppColors.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: statusColor.withValues(alpha: 0.2),
                  child: Text(
                    worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sicil No: ${worker.sicilNo ?? '-'} • ${worker.department ?? 'Üretim'}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        worker.status,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 10),

            // Assigned Station Badge (İstasyon Bilgisi)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.videocam_rounded, color: AppColors.cyanAccent, size: 16),
                    const SizedBox(width: 6),
                    const Text('Atandığı İstasyon:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cyanAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    stationName,
                    style: const TextStyle(color: AppColors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
