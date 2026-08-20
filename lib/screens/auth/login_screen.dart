import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../providers/app_provider.dart';
import '../home_shell.dart';
import '../settings/server_settings_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Lütfen kullanıcı adı ve şifrenizi girin.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ApiClient.login(username, password);

    setState(() => _isLoading = false);

    if (success && mounted) {
      context.read<AppProvider>().refreshData();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } else if (mounted) {
      setState(() => _errorMessage = 'Giriş başarısız! Kullanıcı adı veya şifre hatalı.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDarkMode;

    final bgColor = AppColors.getBg(isDark);
    final cardColor = AppColors.getCard(isDark);
    final textColor = AppColors.getText(isDark);
    final subTextColor = AppColors.getSubText(isDark);
    final borderColor = AppColors.getBorder(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Red Brand Header Panel (With ÜÇGE Official Logo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 36),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.brandRedDark, AppColors.brandRedLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings_rounded, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ServerSettingsScreen()),
                          );
                        },
                        tooltip: 'Sunucu Bağlantı Ayarları',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // ÜÇGE Official Logo Container
                  Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/ucge_logo.jpg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'İş Takip Sistemi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Login Form Card
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hesabınıza Giriş Yapın',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Devam etmek için kullanıcı bilgilerinizi girin',
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.alarm.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.alarm.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.alarm, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.alarm, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Username Field
                  TextField(
                    controller: _usernameController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Kullanıcı Adı',
                      hintStyle: TextStyle(color: subTextColor, fontSize: 14),
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.brandRedLight),
                      filled: true,
                      fillColor: cardColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.brandRedLight, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Şifre',
                      hintStyle: TextStyle(color: subTextColor, fontSize: 14),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.brandRedLight),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: subTextColor,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: cardColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.brandRedLight, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandRedLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'GİRİŞ YAP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Register Prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hesabınız yok mu? ',
                        style: TextStyle(color: subTextColor, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Kayıt Olun',
                          style: TextStyle(
                            color: AppColors.brandRedLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
    );
  }
}
