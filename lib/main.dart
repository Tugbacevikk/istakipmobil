import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'providers/app_provider.dart';
import 'screens/auth/login_screen.dart';
import 'widgets/mobile_frame_wrapper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IsTakipApp());
}

class IsTakipApp extends StatelessWidget {
  const IsTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final isDark = provider.isDarkMode;
          return MaterialApp(
            title: 'İş Takip Mobil',
            debugShowCheckedModeBanner: false,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              scaffoldBackgroundColor: AppColors.bgLight,
              primaryColor: AppColors.brandRedDark,
              colorScheme: const ColorScheme.light(
                primary: AppColors.brandRedDark,
                secondary: AppColors.cyanAccent,
                surface: Colors.white,
                onSurface: Color(0xFF0F172A),
              ),
              dialogTheme: const DialogThemeData(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                contentTextStyle: TextStyle(color: Color(0xFF334155), fontSize: 14),
              ),
              popupMenuTheme: PopupMenuThemeData(
                color: Colors.white,
                textStyle: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                labelStyle: const TextStyle(color: Color(0xFF475569)),
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.brandRedDark, width: 1.8),
                ),
              ),
              fontFamily: 'Roboto',
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: AppColors.bgDark,
              primaryColor: AppColors.primary,
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                secondary: AppColors.cyanAccent,
                surface: AppColors.cardDark,
                onSurface: AppColors.textPrimary,
              ),
              dialogTheme: const DialogThemeData(
                backgroundColor: AppColors.cardDark,
                surfaceTintColor: AppColors.cardDark,
                titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                contentTextStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              popupMenuTheme: PopupMenuThemeData(
                color: AppColors.cardDark,
                textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              cardTheme: CardThemeData(
                color: AppColors.cardDark,
                surfaceTintColor: AppColors.cardDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cyanAccent, width: 1.8),
                ),
              ),
              fontFamily: 'Roboto',
            ),
            builder: (context, child) {
              return MobileFrameWrapper(child: child ?? const LoginScreen());
            },
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
