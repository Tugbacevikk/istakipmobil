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
            secondary: AppColors.cyanAccent,
            surface: AppColors.cardDark,
          ),
          fontFamily: 'Roboto',
        ),
        builder: (context, child) {
          return MobileFrameWrapper(child: child ?? const LoginScreen());
        },
        home: const LoginScreen(),
      ),
    );
  }
}
