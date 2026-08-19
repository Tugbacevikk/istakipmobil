import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../providers/app_provider.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late TextEditingController _urlController;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final currentUrl = context.read<AppProvider>().serverUrl;
    _urlController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final success = await ApiClient.testConnection(_urlController.text);

    setState(() {
      _isTesting = false;
      _testSuccess = success;
      _testResult = success
          ? 'Bağlantı Başarılı! Sunucuya ulaşıldı.'
          : 'Bağlantı Başarısız! Sunucu adresi ve portu kontrol edin.';
    });
  }

  Future<void> _saveSettings() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isEmpty) return;

    await context.read<AppProvider>().updateServerUrl(newUrl);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sunucu ayarları kaydedildi ve bağlantı yenilendi.'),
          backgroundColor: AppColors.working,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Sunucu Ayarları', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.dns_rounded, size: 64, color: AppColors.accent),
            const SizedBox(height: 16),
            const Text(
              'Flask API Sunucu Bağlantısı',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fabrika İş Takip sisteminin çalıştığı sunucu IP adresini ve port numarasını girin (Örn: http://192.168.1.100:5000).',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Sunucu Adresi (URL / IP)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintText: 'http://192.168.1.50:5000',
                hintStyle: const TextStyle(color: AppColors.primaryLight),
                prefixIcon: const Icon(Icons.link_rounded, color: AppColors.accent),
                filled: true,
                fillColor: AppColors.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                          )
                        : const Icon(Icons.network_check_rounded, color: AppColors.accent),
                    label: const Text('Bağlantıyı Test Et', style: TextStyle(color: AppColors.accent)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save_rounded, color: Colors.white),
                    label: const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _testSuccess ? AppColors.working.withOpacity(0.15) : AppColors.alarm.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _testSuccess ? AppColors.working : AppColors.alarm,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                      color: _testSuccess ? AppColors.working : AppColors.alarm,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          color: _testSuccess ? AppColors.working : AppColors.alarm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
