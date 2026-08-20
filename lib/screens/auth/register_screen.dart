import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firmaController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firmaController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final adSoyad = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final firma = _firmaController.text.trim();

    if (username.isEmpty || password.isEmpty || adSoyad.isEmpty || email.isEmpty) {
      setState(() {
        _message = 'Lütfen tüm alanları doldurun.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final ok = await ApiClient.registerUser(
      username: username,
      password: password,
      adSoyad: adSoyad,
      email: email,
      firmaAdi: firma.isNotEmpty ? firma : 'Fabrika',
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSuccess = ok;
        _message = ok
            ? '✅ Başvurunuz alındı! Admin onayından sonra hesabınızla giriş yapabilirsiniz.'
            : '❌ Kayıt alınamadı. Bu kullanıcı adı veya e-posta zaten kayıtlı olabilir.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.brandRedDark,
        title: const Text('Patron Hesabı Kayıt Başvurusu', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yeni Patron / Yönetici Hesabı',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Saha erişimi için başvurunuz Admin onayına düşecektir.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),

            _buildTextField(_fullNameController, 'Ad Soyad', Icons.badge_outlined),
            const SizedBox(height: 16),
            _buildTextField(_usernameController, 'Kullanıcı Adı', Icons.person_outline_rounded),
            const SizedBox(height: 16),
            _buildTextField(_emailController, 'E-Posta Adresi', Icons.email_outlined),
            const SizedBox(height: 16),
            _buildTextField(_firmaController, 'Firma / Departman Adı', Icons.business_rounded),
            const SizedBox(height: 16),
            _buildTextField(_passwordController, 'Şifre', Icons.lock_outline_rounded, isObscure: true),
            const SizedBox(height: 20),

            if (_message != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess ? AppColors.working.withValues(alpha: 0.15) : AppColors.alarm.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _isSuccess ? AppColors.working : AppColors.alarm),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _isSuccess ? AppColors.working : AppColors.alarm,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandRedLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text(
                        'BAŞVURUYU GÖNDER',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isObscure = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.brandRedLight),
        filled: true,
        fillColor: AppColors.cardDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brandRedLight, width: 2)),
      ),
    );
  }
}
