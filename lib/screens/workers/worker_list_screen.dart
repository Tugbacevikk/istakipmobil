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
  final _customStationController = TextEditingController();
  String _selectedStation = 'Istasyon-1';

  void _showAddWorkerDialog(BuildContext context) {
    _adController.clear();
    _soyadController.clear();
    _sicilController.text = 'EMP-${DateTime.now().millisecond}';
    _departmanController.text = 'Üretim';
    _customStationController.clear();

    final provider = context.read<AppProvider>();
    final Set<String> availableStations = {
      'Istasyon-1',
      'Istasyon-2',
      'Istasyon-3',
      'Istasyon-4',
      'Istasyon-5',
      'Istasyon-6',
      'Istasyon-7',
      'Istasyon-8',
      ...provider.cameras.map((c) => c.name).where((n) => n.isNotEmpty),
      '+ Yeni İstasyon Yaz',
    };

    _selectedStation = availableStations.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
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
                    initialValue: availableStations.contains(_selectedStation) ? _selectedStation : availableStations.first,
                    dropdownColor: AppColors.cardDark,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Atanacağı İstasyon',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(),
                    ),
                    items: availableStations.map((st) {
                      return DropdownMenuItem(value: st, child: Text(st));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          _selectedStation = val;
                        });
                      }
                    },
                  ),
                  if (_selectedStation == '+ Yeni İstasyon Yaz') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _customStationController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Yeni İstasyon Adı (Örn: Istasyon-5)',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        hintText: 'Istasyon-5',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('İptal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  final ad = _adController.text.trim();
                  final soyad = _soyadController.text.trim();
                  String targetStation = _selectedStation;
                  if (_selectedStation == '+ Yeni İstasyon Yaz') {
                    targetStation = _customStationController.text.trim();
                  }

                  if (targetStation.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lütfen geçerli bir istasyon adı seçin veya yazın.'),
                        backgroundColor: AppColors.alarm,
                      ),
                    );
                    return;
                  }

                  if (ad.isNotEmpty && soyad.isNotEmpty) {
                    final messenger = ScaffoldMessenger.of(context);
                    final provider = context.read<AppProvider>();
                    Navigator.pop(dialogCtx);
                    setState(() => _isSubmitting = true);
                    final success = await ApiClient.addWorker(
                      ad: ad,
                      soyad: soyad,
                      sicilNo: _sicilController.text.trim(),
                      departman: _departmanController.text.trim(),
                      istasyonAdi: targetStation,
                    );
                    if (mounted) setState(() => _isSubmitting = false);
                    final msg = success
                        ? '"$ad $soyad" ($targetStation) sisteme eklendi.'
                        : (ApiClient.lastErrorMessage.isNotEmpty ? ApiClient.lastErrorMessage : 'İşçi eklenemedi.');
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        backgroundColor: success ? AppColors.working : AppColors.alarm,
                      ),
                    );
                    provider.refreshData();
                  }
                },
                child: const Text('Ekle', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleToggleAktif(BuildContext context, int workerId, String name, bool currentAktif) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<AppProvider>();
    setState(() => _isSubmitting = true);
    final ok = await ApiClient.toggleWorkerAktif(workerId);
    if (mounted) setState(() => _isSubmitting = false);
    final msg = ok
        ? '"$name" durumu ${!currentAktif ? "Aktif" : "Pasif"} yapıldı.'
        : (ApiClient.lastErrorMessage.isNotEmpty ? ApiClient.lastErrorMessage : 'Durum değiştirilemedi.');
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? AppColors.working : AppColors.alarm,
      ),
    );
    provider.refreshData();
  }

  Future<void> _handleDeleteWorker(BuildContext context, int workerId, String name) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<AppProvider>();
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
      if (mounted) setState(() => _isSubmitting = false);
      final msg = ok
          ? '"$name" silindi.'
          : (ApiClient.lastErrorMessage.isNotEmpty ? ApiClient.lastErrorMessage : 'Silme işlemi başarısız.');
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: ok ? AppColors.working : AppColors.alarm,
        ),
      );
      provider.refreshData();
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
            title: const Text('İşçi Listesi & Saha Durumları', style: TextStyle(color: Colors.white)),
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
                    color: cardColor,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: 'İşçi Adı veya Sicil No ile Ara...',
                            hintStyle: TextStyle(color: subTextColor, fontSize: 14),
                            prefixIcon: Icon(Icons.search_rounded, color: subTextColor),
                            filled: true,
                            fillColor: bgColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: borderColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildChip('Tümü', isDark),
                              const SizedBox(width: 8),
                              _buildChip('Aktif Çalışanlar', isDark),
                              const SizedBox(width: 8),
                              _buildChip('Pasif Çalışanlar', isDark),
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
                              return _buildWorkerCard(context, worker, isAdmin, cardColor, textColor, subTextColor, borderColor);
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

  Widget _buildChip(String label, bool isDark) {
    final isSelected = _filterStatus == label;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.getSubText(isDark),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.getBg(isDark),
      side: BorderSide(color: isSelected ? AppColors.cyanAccent : AppColors.getBorder(isDark)),
      onSelected: (selected) {
        if (selected) setState(() => _filterStatus = label);
      },
    );
  }

  Widget _buildWorkerCard(
    BuildContext context,
    WorkerModel worker,
    bool isAdmin,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    final isAktif = worker.isAktif;
    final badgeColor = isAktif ? AppColors.working : subTextColor;
    final badgeText = isAktif ? '🟢 Aktif Çalışan' : '🔴 Pasif Çalışan';

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isAktif ? borderColor : AppColors.alarm.withValues(alpha: 0.3)),
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
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sicil No: ${worker.sicilNo ?? "Belirtilmedi"} • ${worker.department ?? "Üretim"}',
                        style: TextStyle(color: subTextColor, fontSize: 12),
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
