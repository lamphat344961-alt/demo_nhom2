import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_colors.dart';
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';

import 'providers/auth_provider.dart';

import 'screens/auth/login_screen.dart';
// KHÔNG CẦN CÁC TRANG HOME NỮA VÌ ĐI THẲNG ĐẾN LOGIN
// import 'screens/owner/owner_home_screen.dart';
// import 'screens/driver/driver_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init services
  await StorageService.init();
  ApiService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Các Providers khác
      ],
      child: MaterialApp(
        title: 'Delivery Management',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(),
          scaffoldBackgroundColor: AppColors.background,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Điều hướng thẳng đến màn hình đăng nhập sau 1 giây (hoặc thời gian SplashScreen mong muốn)
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      // CHUYỂN THẲNG NGƯỜI DÙNG ĐẾN LOGIN SCREEN
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    });
  }

  // HÀM _checkAuth() ĐÃ BỊ XÓA BỎ HOÀN TOÀN

  @override
  Widget build(BuildContext context) {
    // Màn hình Splash vẫn hiển thị trong 1 giây
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping, size: 100, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'Delivery Management',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
