import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'home_tab.dart';
import 'dashboard_tab.dart';
import 'account_tab.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  int _currentIndex = 0;

  // Danh sách "builder" 3 tab mới
  late final List<Widget Function()> _builders = [
        () => const HomeTab(),
        () => const DashboardTab(),
        () => const AccountTab(),
  ];

  // Bộ đệm tab đã tạo (kích thước là 3)
  late final List<Widget?> _cached = List<Widget?>.filled(
    _builders.length,
    null,
  );

  Widget _currentBody() {
    _cached[_currentIndex] ??= _builders[_currentIndex].call();
    return _cached[_currentIndex]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.ownerPrimary.withOpacity(0.1),
        height: 70, // Tăng chiều cao 1 chút cho đẹp
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Thống kê',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}