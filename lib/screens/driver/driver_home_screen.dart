import 'package:demo_nhom2/screens/driver/account_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <--- THÊM IMPORT
import '../../core/constants/app_colors.dart';
import '../../providers/route_provider.dart'; // <--- THÊM IMPORT
import 'deliveries_tab.dart';
import 'map_tab.dart';
import 'account_tab.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DeliveriesTab(),
    const MapTab(),
    const DriverAccountTab(),
  ];

  @override
  Widget build(BuildContext context) {
    // ----- THÊM CHANGE NOTIFIER PROVIDER -----
    // Cung cấp RouteProvider cho các tab con bên dưới
    return ChangeNotifierProvider(
      create: (_) => RouteProvider(),
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          indicatorColor: AppColors.driverPrimary.withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Đơn hàng',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Bản đồ',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_circle_outlined),
              selectedIcon: Icon(Icons.account_circle),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}
