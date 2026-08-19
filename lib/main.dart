import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'providers/app_provider.dart';
import 'screens/home_shell.dart';

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
      child: MaterialApp(
        title: 'İş Takip Mobil',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.bgDark,
          primaryColor: AppColors.primary,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.accent,
            surface: AppColors.cardDark,
            background: AppColors.bgDark,
          ),
          fontFamily: 'Roboto',
        ),
        home: const HomeShell(),
      ),
    );
  }
}
