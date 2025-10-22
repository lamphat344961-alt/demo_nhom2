import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// Import các tab thật của bạn
import 'dashboard_tab.dart';
import 'manage_orders_tab.dart';
import 'manage_vehicles_tab.dart';
import 'manage_drivers_tab.dart';
import 'manage_points_tab.dart';
import 'manage_products_tab.dart';
import 'account_tab.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  int _currentIndex = 0;

  // Danh sách "builder" để lazy-load tab
  late final List<Widget Function()> _builders = [
    () => const DashboardTab(),
    () => const ManageOrdersTab(),
    () => const ManageVehiclesTab(),
    () => const ManageDriversTab(),
    () => const ManagePointsTab(), // tab này thường có map → cần lazy
    () => const ManageProductsTab(),
    () => const AccountTab(),
  ];

  // Bộ đệm tab đã tạo (chỉ tạo khi cần)
  late final List<Widget?> _cached = List<Widget?>.filled(
    _builders.length,
    null,
  );

  Widget _currentBody() {
    // Nếu tab chưa được tạo -> tạo và cache
    _cached[_currentIndex] ??= _builders[_currentIndex].call();
    return _cached[_currentIndex]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentBody(), // ❗ Chỉ build tab đang xem
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.ownerPrimary.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Đơn hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Xe',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Tài xế',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Điểm giao',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Hàng hóa',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
