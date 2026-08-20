import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
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
  bool _isSubmitting = false;

  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  final _sicilController = TextEditingController();
  final _departmanController = TextEditingController();
  String _selectedStation = 'Istasyon-1';

  void _showAddWorkerDialog(BuildContext context) {
    _adController.clear();
    _soyadController.clear();
    _sicilController.text = 'EMP-${DateTime.now().millisecond}';
    _departmanController.text = 'Üretim';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Row(
          children: const [
            Icon(Icons.person_add_alt_1_rounded, color: AppColors.cyanAccent),
            SizedBox(width: 8),
            Text('Yeni İşçi Ekle', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _adController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'İşçi Adı',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _soyadController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'İşçi Soyadı',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _sicilController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Sicil No',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _departmanController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Departman / Birim',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedStation,
                dropdownColor: AppColors.cardDark,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Atanacağı İstasyon',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(),
                ),
                items: ['Istasyon-1', 'Istasyon-2', 'Istasyon-3', 'Istasyon-4'].map((st) {
                  return DropdownMenuItem(value: st, child: Text(st));
                }).toList(),
                onChanged: (val) {
                  if (val != null) _selectedStation = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final ad = _adController.text.trim();
              final soyad = _soyadController.text.trim();
              if (ad.isNotEmpty && soyad.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() => _isSubmitting = true);
                final success = await ApiClient.addWorker(
                  ad: ad,
                  soyad: soyad,
                  sicilNo: _sicilController.text.trim(),
                  departman: _departmanController.text.trim(),
                  istasyonAdi: _selectedStation,
                );
                setState(() => _isSubmitting = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '"$ad $soyad" sisteme eklendi.' : 'İşçi eklenemedi. İstasyon dolu veya hata oluştu.'),
                      backgroundColor: success ? AppColors.working : AppColors.alarm,
                    ),
                  );
                  context.read<AppProvider>().refreshData();
                }
              }
            },
            child: const Text('Ekle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggleAktif(BuildContext context, int workerId, String name, bool currentAktif) async {
    setState(() => _isSubmitting = true);
    final ok = await ApiClient.toggleWorkerAktif(workerId);
    setState(() => _isSubmitting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '"$name" durumu ${!currentAktif ? "Aktif" : "Pasif"} yapıldı.' : 'Durum değiştirilemedi.'),
          backgroundColor: ok ? AppColors.working : AppColors.alarm,
        ),
      );
      context.read<AppProvider>().refreshData();
    }
  }

  Future<void> _handleDeleteWorker(BuildContext context, int workerId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('İşçiyi Sil', style: TextStyle(color: Colors.white)),
        content: Text('"$name" kaydını kaldırmak istediğinize emin misiniz?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alarm),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSubmitting = true);
      final ok = await ApiClient.deleteWorker(workerId);
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '"$name" silindi.' : 'Silme işlemi başarısız.'),
            backgroundColor: ok ? AppColors.working : AppColors.alarm,
          ),
        );
        context.read<AppProvider>().refreshData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final isAdmin = provider.isAdmin;
        final workers = provider.workers.where((worker) {
          final matchesSearch = worker.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (worker.sicilNo?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
              (worker.lastStation?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

          if (!matchesSearch) return false;

          if (_filterStatus == 'Tümü') return true;
          if (_filterStatus == 'Aktif Çalışanlar') return worker.isAktif;
          if (_filterStatus == 'Pasif Çalışanlar') return !worker.isAktif;
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: const Text('İşçi Listesi & Saha Durumları', style: TextStyle(color: AppColors.textPrimary)),
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.person_add_rounded, color: Colors.white),
                  onPressed: () => _showAddWorkerDialog(context),
                  tooltip: 'Yeni İşçi Ekle',
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: provider.refreshData,
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // Search & Filter
                  Container(
                    color: AppColors.cardDark,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'İşçi Adı veya Sicil No ile Ara...',
                            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.bgDark,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.cardBorder),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildChip('Tümü'),
                              const SizedBox(width: 8),
                              _buildChip('Aktif Çalışanlar'),
                              const SizedBox(width: 8),
                              _buildChip('Pasif Çalışanlar'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // List Body
                  Expanded(
                    child: workers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.people_outline_rounded, size: 54, color: AppColors.textSecondary),
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
                            itemCount: workers.length,
                            itemBuilder: (context, index) {
                              final worker = workers[index];
                              return _buildWorkerCard(context, worker, isAdmin);
                            },
                          ),
                  ),
                ],
              ),
              if (_isSubmitting)
                Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(String label) {
    final isSelected = _filterStatus == label;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.bgDark,
      side: BorderSide(color: isSelected ? AppColors.cyanAccent : AppColors.cardBorder),
      onSelected: (selected) {
        if (selected) setState(() => _filterStatus = label);
      },
    );
  }

  Widget _buildWorkerCard(BuildContext context, WorkerModel worker, bool isAdmin) {
    final isAktif = worker.isAktif;
    final badgeColor = isAktif ? AppColors.working : AppColors.textSecondary;
    final badgeText = isAktif ? '🟢 Aktif Çalışan' : '🔴 Pasif Çalışan';

    return Card(
      color: AppColors.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isAktif ? AppColors.cardBorder : AppColors.alarm.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: badgeColor.withValues(alpha: 0.2),
                  child: Text(
                    worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sicil No: ${worker.sicilNo ?? "Belirtilmedi"} • ${worker.department ?? "Üretim"}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isAdmin) ...[
                  IconButton(
                    icon: Icon(
                      isAktif ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                      color: isAktif ? AppColors.working : AppColors.textSecondary,
                      size: 28,
                    ),
                    onPressed: () => _handleToggleAktif(context, worker.id, worker.name, isAktif),
                    tooltip: isAktif ? 'Pasife Al' : 'Aktife Al',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.alarm, size: 20),
                    onPressed: () => _handleDeleteWorker(context, worker.id, worker.name),
                    tooltip: 'İşçiyi Sil',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.videocam_rounded, color: AppColors.cyanAccent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Atandığı İstasyon: ${worker.lastStation ?? "Istasyon-1"}',
                      style: const TextStyle(
                        color: AppColors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10),
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
