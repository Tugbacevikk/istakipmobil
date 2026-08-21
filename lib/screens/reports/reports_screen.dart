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
  ReportFilterPeriod _selectedPeriod = ReportFilterPeriod.today;
  String _selectedStation = 'Tüm İstasyonlar';
  String _selectedWorker = 'Tüm Çalışanlar';

  double _workingMin = 0;
  double _idleMin = 0;
  double _weldingMin = 0;
  double _verimlilik = 0;
  int _totalAlarms = 0;
  int _totalWorkers = 0;

  List<Map<String, dynamic>> _detailLogs = [];

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

    final summaryFuture = ApiClient.fetchReportSummary(
      start: start,
      end: end,
      istasyon: istasyonParam,
      worker: workerParam,
    );

    final detailFuture = ApiClient.fetchReportDetailStats(
      start: start,
      end: end,
      istasyon: istasyonParam,
      worker: workerParam,
    );

    final results = await Future.wait([summaryFuture, detailFuture]);
    final data = results[0] as Map<String, dynamic>;
    final details = results[1] as List<Map<String, dynamic>>;

    // Filter non-video records
    List<Map<String, dynamic>> cleanDetails = details.where((item) {
      final st = (item['istasyon_adi'] ?? '').toString();
      final w = (item['worker_adi'] ?? '').toString();
      return !st.toLowerCase().contains('video:') && !st.toLowerCase().contains('.mp4') && !w.toLowerCase().contains('video:');
    }).toList();

    // Smart Fallback: If cleanDetails is empty for selected period, fetch all-time records so screen is never blank!
    if (cleanDetails.isEmpty) {
      final fallbackDetails = await ApiClient.fetchReportDetailStats(istasyon: istasyonParam, worker: workerParam);
      final fallbackClean = fallbackDetails.where((item) {
        final st = (item['istasyon_adi'] ?? '').toString();
        final w = (item['worker_adi'] ?? '').toString();
        return !st.toLowerCase().contains('video:') && !st.toLowerCase().contains('.mp4') && !w.toLowerCase().contains('video:');
      }).toList();
      cleanDetails = fallbackClean.isNotEmpty ? fallbackClean : (details.isNotEmpty ? details : fallbackDetails);
    }

    if (mounted) {
      if (ApiClient.lastErrorMessage.isNotEmpty && ApiClient.lastErrorType != ApiErrorType.none) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.lastErrorMessage),
            backgroundColor: AppColors.alarm,
          ),
        );
      }
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

        _detailLogs = cleanDetails;
        _isLoading = false;
      });
    }
  }

  String _formatTimeOnly(String? fullDateTime) {
    if (fullDateTime == null || fullDateTime.isEmpty) return '--:--';
    try {
      if (fullDateTime.contains(' ')) {
        final parts = fullDateTime.split(' ');
        if (parts.length > 1) {
          final timePart = parts[1];
          final subParts = timePart.split(':');
          if (subParts.length >= 2) {
            return '${subParts[0]}:${subParts[1]}';
          }
        }
      }
      return fullDateTime;
    } catch (_) {
      return fullDateTime;
    }
  }

  void _showEmailReportDialog(BuildContext context) {
    final customEmailController = TextEditingController();
    bool isSending = false;
    bool isInitialLoading = true;

    List<UserModel> registeredUsers = [];
    Map<int, bool> userSelections = {};
    Map<int, TextEditingController> emailControllers = {};

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (isInitialLoading) {
            Future.wait([
              ApiClient.fetchUsers(),
              ApiClient.fetchMailRecipients(),
            ]).then((results) {
              final users = results[0] as List<UserModel>;
              final mailRecs = results[1] as List<Map<String, String>>;

              final Map<String, String> emailByUsername = {};
              for (var r in mailRecs) {
                final uname = r['kullanici_adi'] ?? r['username'];
                final em = r['email'];
                if (uname != null && em != null) {
                  emailByUsername[uname.toString().toLowerCase()] = em.toString();
                }
              }

              registeredUsers = users
                  .where((u) =>
                      u.durum == 'onaylandi' ||
                      u.durum == 'approved' ||
                      u.rol.toLowerCase() == 'patron' ||
                      u.rol.toLowerCase() == 'admin')
                  .toList();

              if (registeredUsers.isEmpty && users.isNotEmpty) {
                registeredUsers = users;
              }

              for (var u in registeredUsers) {
                userSelections[u.id] = true;
                final existingEmail = (u.email != null && u.email!.isNotEmpty)
                    ? u.email!
                    : (emailByUsername[u.kullaniciAdi.toLowerCase()] ?? '');
                emailControllers[u.id] = TextEditingController(text: existingEmail);
              }

              setDialogState(() {
                isInitialLoading = false;
              });
            });

            return const AlertDialog(
              backgroundColor: AppColors.cardDark,
              content: SizedBox(
                height: 120,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.cyanAccent),
                      SizedBox(height: 12),
                      Text('Kayıtlı patron hesapları yükleniyor...',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            );
          }

          final allSelected = registeredUsers.isNotEmpty &&
              registeredUsers.every((u) => userSelections[u.id] == true);

          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            title: Row(
              children: const [
                Icon(Icons.mark_email_read_rounded, color: AppColors.cyanAccent),
                SizedBox(width: 8),
                Text('PDF Raporu E-posta ile Gönder', style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seçilen filtrelere göre hazırlanan PDF raporunu kayıtlı patron hesaplarına veya manuel adrese gönderin:',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 14),

                    if (registeredUsers.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kayıtlı Patron Hesapları:',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          InkWell(
                            onTap: () {
                              setDialogState(() {
                                final target = !allSelected;
                                for (var u in registeredUsers) {
                                  userSelections[u.id] = target;
                                }
                              });
                            },
                            child: Text(
                              allSelected ? 'Tümünü Kaldır' : 'Tümünü Seç',
                              style: const TextStyle(color: AppColors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: registeredUsers.length,
                          separatorBuilder: (_, __) => const Divider(color: AppColors.cardBorder, height: 1),
                          itemBuilder: (ctx, idx) {
                            final u = registeredUsers[idx];
                            final isChecked = userSelections[u.id] ?? false;
                            final ctrl = emailControllers[u.id]!;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        activeColor: AppColors.primary,
                                        value: isChecked,
                                        onChanged: (val) {
                                          setDialogState(() {
                                            userSelections[u.id] = val == true;
                                          });
                                        },
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${u.adSoyad} (@${u.kullaniciAdi})',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: u.rol == 'admin'
                                              ? AppColors.brandRedLight.withValues(alpha: 0.2)
                                              : AppColors.cyanAccent.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          u.rol.toUpperCase(),
                                          style: TextStyle(
                                            color: u.rol == 'admin'
                                                ? AppColors.brandRedLight
                                                : AppColors.cyanAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isChecked)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 40, right: 8, bottom: 8),
                                      child: TextField(
                                        controller: ctrl,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                        decoration: const InputDecoration(
                                          labelText: 'E-posta Adresi',
                                          labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                          hintText: 'patron@sirket.com',
                                          hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    const Text(
                      'Farklı / Ek E-posta Adresi:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: customEmailController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'ornek@sirket.com',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.pop(dialogCtx),
                child: const Text('İptal'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: isSending
                    ? null
                    : () async {
                        final Set<String> targetEmails = {};

                        for (var u in registeredUsers) {
                          if (userSelections[u.id] == true) {
                            final em = emailControllers[u.id]?.text.trim() ?? '';
                            if (em.isNotEmpty) {
                              targetEmails.add(em);
                            }
                          }
                        }

                        final custom = customEmailController.text.trim();
                        if (custom.isNotEmpty) {
                          targetEmails.add(custom);
                        }

                        if (targetEmails.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Lütfen seçilen patron hesaplarının e-posta adresini doldurun veya ek bir adres yazın.'),
                              backgroundColor: AppColors.alarm,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSending = true);
                        final (start, end) = _getDateRange(_selectedPeriod);
                        final istasyonParam = _selectedStation == 'Tüm İstasyonlar' ? '' : _selectedStation;
                        final workerParam = _selectedWorker == 'Tüm Çalışanlar' ? '' : _selectedWorker;

                        final success = await ApiClient.sendReportEmail(
                          emails: targetEmails.toList(),
                          start: start,
                          end: end,
                          istasyon: istasyonParam,
                          worker: workerParam,
                        );

                        setDialogState(() => isSending = false);
                        if (mounted) {
                          Navigator.pop(dialogCtx);
                          final msg = success
                              ? 'PDF Raporu ${targetEmails.length} e-posta adresine başarıyla gönderildi!'
                              : (ApiClient.lastErrorMessage.isNotEmpty
                                  ? ApiClient.lastErrorMessage
                                  : 'E-posta gönderilemedi. Lütfen sunucu SMTP ayarlarını kontrol edin.');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: success ? AppColors.working : AppColors.alarm,
                            ),
                          );
                        }
                      },
                icon: isSending
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                label: Text(isSending ? 'Gönderiliyor...' : 'E-posta Gönder', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalMin = _workingMin + _idleMin + _weldingMin;
    final workingPct = totalMin > 0 ? ((_workingMin / totalMin) * 100).toStringAsFixed(1) : '0';
    final idlePct = totalMin > 0 ? ((_idleMin / totalMin) * 100).toStringAsFixed(1) : '0';
    final weldingPct = totalMin > 0 ? ((_weldingMin / totalMin) * 100).toStringAsFixed(1) : '0';

    final provider = context.watch<AppProvider>();
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
        title: const Text('Raporlar & Saha Analitiği', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_unread_rounded, color: Colors.white),
            onPressed: () => _showEmailReportDialog(context),
            tooltip: 'PDF Raporu E-postayla Gönder',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadReportData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandRedLight))
          : RefreshIndicator(
              onRefresh: _loadReportData,
              color: AppColors.brandRedLight,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Tüm Zamanlar', ReportFilterPeriod.allTime),
                          const SizedBox(width: 8),
                          _buildFilterChip('Bugün', ReportFilterPeriod.today),
                          const SizedBox(width: 8),
                          _buildFilterChip('Dün', ReportFilterPeriod.yesterday),
                          const SizedBox(width: 8),
                          _buildFilterChip('Bu Hafta', ReportFilterPeriod.thisWeek),
                          const SizedBox(width: 8),
                          _buildFilterChip('Bu Ay', ReportFilterPeriod.thisMonth),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Station & Worker Dropdown Filters
                    Row(
                      children: [
                        Expanded(
                          child: _buildStationDropdown(),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildWorkerDropdown(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Efficiency & Worker Count Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Genel Verimlilik Oranı',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '%${_verimlilik.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: AppColors.working,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Aktif Saha İşçileri',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_totalWorkers KİŞİ',
                                style: const TextStyle(
                                  color: AppColors.cyanAccent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Metric Cards
                    _buildMetricRow('Çalışma Süresi', '${_workingMin.toStringAsFixed(1)} dk (%$workingPct)', AppColors.working),
                    const SizedBox(height: 10),
                    _buildMetricRow('Duruş Süresi', '${_idleMin.toStringAsFixed(1)} dk (%$idlePct)', AppColors.idle),
                    const SizedBox(height: 10),
                    _buildMetricRow('Kaynak İşlemi Süresi', '${_weldingMin.toStringAsFixed(1)} dk (%$weldingPct)', AppColors.accent),
                    const SizedBox(height: 10),
                    _buildMetricRow('Toplam İhlal / Alarm', '$_totalAlarms Kayıt', AppColors.alarm),
                    const SizedBox(height: 24),

                    // Donut & Bar Charts
                    if (totalMin > 0) ...[
                      const Text(
                        'Süre & Durum Dağılım Grafiği',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(
                                color: AppColors.working,
                                value: _workingMin > 0 ? _workingMin : 1,
                                title: '%$workingPct',
                                radius: 45,
                                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              PieChartSectionData(
                                color: AppColors.idle,
                                value: _idleMin > 0 ? _idleMin : 0.1,
                                title: '%$idlePct',
                                radius: 45,
                                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              PieChartSectionData(
                                color: AppColors.accent,
                                value: _weldingMin > 0 ? _weldingMin : 1,
                                title: '%$weldingPct',
                                radius: 45,
                                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Detailed Station & Time Log Timeline
                    Row(
                      children: const [
                        Icon(Icons.history_toggle_off_rounded, color: AppColors.cyanAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'İstasyon & Zaman Çizelgesi Raporu',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_detailLogs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Center(
                          child: Text(
                            'Seçilen zaman aralığında istasyon kaydı bulunmuyor.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _detailLogs.length,
                        itemBuilder: (context, index) {
                          final log = _detailLogs[index];
                          return _buildDetailLogCard(log);
                        },
                      ),

                    const SizedBox(height: 24),

                    // PDF Export & Email Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.picture_as_pdf_rounded, color: AppColors.brandRedLight, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'PDF Raporu & E-posta Gönderimi',
                                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Seçilen filtrelere ait analiz özetini ve çizelgeyi PDF olarak e-posta adreslerine iletebilirsiniz.',
                            style: TextStyle(color: subTextColor, fontSize: 12),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _showEmailReportDialog(context),
                              icon: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 18),
                              label: const Text(
                                'PDF Raporunu E-posta ile Gönder 📩',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.cardDark,
      side: BorderSide(color: isSelected ? AppColors.cyanAccent : AppColors.cardBorder),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPeriod = period);
          _loadReportData();
        }
      },
    );
  }

  Widget _buildStationDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStation,
          dropdownColor: AppColors.cardDark,
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          items: ['Tüm İstasyonlar', 'Istasyon-1', 'Istasyon-2', 'Istasyon-3', 'Istasyon-4'].map((st) {
            return DropdownMenuItem(value: st, child: Text(st, overflow: TextOverflow.ellipsis));
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedStation = val);
              _loadReportData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildWorkerDropdown() {
    final provider = context.watch<AppProvider>();
    final workerNames = ['Tüm Çalışanlar', ...provider.workers.map((w) => w.name)];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: workerNames.contains(_selectedWorker) ? _selectedWorker : 'Tüm Çalışanlar',
          dropdownColor: AppColors.cardDark,
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          items: workerNames.map((w) {
            return DropdownMenuItem(value: w, child: Text(w, overflow: TextOverflow.ellipsis));
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedWorker = val);
              _loadReportData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailLogCard(Map<String, dynamic> log) {
    final station = log['istasyon_adi'] ?? 'Istasyon-1';
    final worker = log['worker_adi'] ?? 'Atanmamış Çalışan';
    final startTime = _formatTimeOnly(log['ilk_gorulme']);
    final endTime = _formatTimeOnly(log['son_gorulme']);
    final dateStr = log['tarih_fmt'] ?? log['tarih'] ?? '';
    final workingFmt = log['aktif_sure_fmt'] ?? '${log['aktif_sure_min'] ?? 0} dk';
    final idleFmt = log['inaktif_sure_fmt'] ?? '${log['inaktif_sure_min'] ?? 0} dk';
    final kaynakFmt = log['kaynak_sure_fmt'] ?? '${log['kaynak_sure_min'] ?? 0} dk';
    final verim = log['verimlilik_orani'] ?? log['aktif_oran'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.videocam_rounded, color: AppColors.cyanAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    station,
                    style: const TextStyle(color: AppColors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.working.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.working.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Verimlilik: %$verim',
                  style: const TextStyle(color: AppColors.working, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, color: Colors.orangeAccent, size: 16),
              const SizedBox(width: 6),
              Text(
                worker,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: AppColors.textSecondary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Giriş-Çıkış: $startTime - $endTime',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (dateStr.isNotEmpty)
                Text(
                  dateStr,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🟢 Çalışma: $workingFmt',
                style: const TextStyle(color: AppColors.working, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Text(
                '🟣 Kaynak: $kaynakFmt',
                style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Text(
                '🟠 Duruş: $idleFmt',
                style: const TextStyle(color: AppColors.idle, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
