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
  String _selectedStatusFilter = 'Tümü';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final allWorkers = provider.workers;

        final filteredWorkers = allWorkers.where((w) {
          final matchesSearch = w.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (w.sicilNo != null && w.sicilNo!.contains(_searchQuery));
          if (_selectedStatusFilter == 'Tümü') return matchesSearch;
          return matchesSearch && w.status == _selectedStatusFilter;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: const Text('İşçi Listesi & Saha Durumları', style: TextStyle(color: AppColors.textPrimary)),
          ),
          body: Column(
            children: [
              // Search & Filter Bar
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.cardDark,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'İşçi Adı veya Sicil No ile Ara...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.bgDark,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Tümü', 'Calisiyor', 'Durusta', 'Kaynak Yapıyor']
                            .map((filter) => Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: Text(
                                      filter == 'Calisiyor'
                                          ? 'Çalışıyor'
                                          : filter == 'Durusta'
                                              ? 'Duruşta'
                                              : filter,
                                    ),
                                    selected: _selectedStatusFilter == filter,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _selectedStatusFilter = filter);
                                      }
                                    },
                                    selectedColor: AppColors.accent,
                                    backgroundColor: AppColors.bgDark,
                                    labelStyle: TextStyle(
                                      color: _selectedStatusFilter == filter
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Workers List
              Expanded(
                child: filteredWorkers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.badge_outlined, size: 54, color: AppColors.textSecondary),
                            SizedBox(height: 12),
                            Text(
                              'Kayıtlı işçi bulunamadı.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredWorkers.length,
                        itemBuilder: (context, index) {
                          final worker = filteredWorkers[index];
                          return _buildWorkerCard(worker);
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

    return Card(
      color: AppColors.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: statusColor.withOpacity(0.2),
          child: Text(
            worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        title: Text(
          worker.name,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Sicil No: ${worker.sicilNo ?? '-'} • ${worker.department ?? 'Üretim'}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            if (worker.lastStation != null)
              Text(
                'İstasyon: ${worker.lastStation}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withOpacity(0.5)),
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
      ),
    );
  }
}
