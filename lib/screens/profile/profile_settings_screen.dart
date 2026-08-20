import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../providers/app_provider.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isEmailLoading = false;
  bool _isPasswordLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir e-posta adresi girin.'),
          backgroundColor: AppColors.alarm,
        ),
      );
      return;
    }

    setState(() => _isEmailLoading = true);
    final success = await ApiClient.updateProfileEmail(email);
    setState(() => _isEmailLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ E-posta adresiniz güncellendi.' : '❌ E-posta güncellenemedi.'),
          backgroundColor: success ? AppColors.working : AppColors.alarm,
        ),
      );
      if (success) {
        context.read<AppProvider>().refreshData();
      }
    }
  }

  Future<void> _handleChangePassword() async {
    final current = _currentPasswordController.text.trim();
    final newPwd = _newPasswordController.text.trim();
    final confirmPwd = _confirmPasswordController.text.trim();

    if (current.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm şifre alanlarını doldurun.'),
          backgroundColor: AppColors.alarm,
        ),
      );
      return;
    }

    if (newPwd != confirmPwd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeni şifreler birbirleriyle eşleşmiyor!'),
          backgroundColor: AppColors.alarm,
        ),
      );
      return;
    }

    if (newPwd.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeni şifreniz en az 4 karakter olmalıdır.'),
          backgroundColor: AppColors.alarm,
        ),
      );
      return;
    }

    setState(() => _isPasswordLoading = true);
    final success = await ApiClient.changePassword(current, newPwd);
    setState(() => _isPasswordLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ Şifreniz başarıyla güncellendi.' : '❌ Şifre güncellenemedi. Mevcut şifrenizi kontrol edin.'),
          backgroundColor: success ? AppColors.working : AppColors.alarm,
        ),
      );
      if (success) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final username = provider.username;
    final isAdmin = provider.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Profil & Güvenlik Ayarları', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: (isAdmin ? AppColors.brandRedLight : AppColors.cyanAccent).withValues(alpha: 0.2),
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                      color: isAdmin ? AppColors.brandRedLight : AppColors.cyanAccent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isAdmin ? AppColors.brandRedLight : AppColors.cyanAccent).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: (isAdmin ? AppColors.brandRedLight : AppColors.cyanAccent).withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                isAdmin ? '👑 Admin (Tam Yetki)' : '👔 Patron Hesabı',
                                style: TextStyle(
                                  color: isAdmin ? AppColors.brandRedLight : AppColors.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // E-mail Section
            const Text(
              '✉️ E-Posta Adresi Güncelle',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Yeni E-Posta Adresiniz (Örn: isim@firma.com)',
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.cyanAccent),
                      filled: true,
                      fillColor: AppColors.bgDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cyanAccent)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      icon: _isEmailLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 18),
                      label: const Text('E-POSTAYI KAYDET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isEmailLoading ? null : _handleUpdateEmail,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Password Section
            const Text(
              '🔒 Şifre Değiştirme',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _buildPasswordField(_currentPasswordController, 'Mevcut Şifreniz', _obscureCurrent, () => setState(() => _obscureCurrent = !_obscureCurrent)),
                  const SizedBox(height: 12),
                  _buildPasswordField(_newPasswordController, 'Yeni Şifreniz', _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
                  const SizedBox(height: 12),
                  _buildPasswordField(_confirmPasswordController, 'Yeni Şifre Tekrarı', _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: _isPasswordLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 20),
                      label: const Text('ŞİFREYİ GÜNCELLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandRedLight,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isPasswordLoading ? null : _handleChangePassword,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, bool obscure, VoidCallback onToggle) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.brandRedLight),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textSecondary, size: 20),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppColors.bgDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.brandRedLight)),
      ),
    );
  }
}
