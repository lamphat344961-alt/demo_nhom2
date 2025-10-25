import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'manage_vehicles_tab.dart';
import 'manage_drivers_tab.dart';
import 'manage_orders_tab.dart';
import 'manage_points_tab.dart';
import 'manage_products_tab.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng Điều Khiển'),
        backgroundColor: AppColors.ownerPrimary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        children: [
          _buildManagementCard(
            context,
            'Quản Lý Xe',
            'Thêm, sửa, xóa và gán tài xế cho xe',
            Icons.local_shipping,
            const ManageVehiclesTab(),
          ),
          _buildManagementCard(
            context,
            'Quản Lý Tài Xế',
            'Tạo tài khoản mới cho tài xế',
            Icons.people,
            const ManageDriversTab(),
          ),
          _buildManagementCard(
            context,
            'Quản Lý Đơn Hàng',
            'Tạo và theo dõi các đơn hàng',
            Icons.inventory_2,
            const ManageOrdersTab(),
          ),
          _buildManagementCard(
            context,
            'Quản Lý Hàng Hóa',
            'Xem và quản lý kho hàng của bạn',
            Icons.category,
            const ManageProductsTab(),
          ),
          _buildManagementCard(
            context,
            'Quản Lý Điểm Giao',
            'Thêm, sửa, xóa các điểm giao hàng',
            Icons.location_on,
            const ManagePointsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Widget destination,
      ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Icon(icon, size: 40, color: AppColors.ownerPrimary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppColors.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
      ),
    );
  }
}