import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // <--- THÊM IMPORT

import '../../core/constants/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class DriverAccountTab extends StatelessWidget {
  const DriverAccountTab({super.key});

  // ----- THÊM HẰNG SỐ SỐ ĐIỆN THOẠI -----
  static const String _ownerPhoneNumber = '0979344962'; // <-- SỐ CỦA BẠN

  // ----- HÀM MỚI: GỌI ĐIỆN -----
  Future<void> _callOwner(BuildContext context) async {
    final Uri launchUri = Uri(scheme: 'tel', path: _ownerPhoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Không thể mở ứng dụng gọi điện';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  // ----- HÀM MỚI: NHẮN TIN -----
  Future<void> _textOwner(BuildContext context) async {
    final Uri launchUri = Uri(scheme: 'sms', path: _ownerPhoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Không thể mở ứng dụng nhắn tin';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    // (Hàm logout giữ nguyên)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = StorageService.getFullName() ?? 'Driver';
    final role = StorageService.getRole() ?? 'Driver';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        backgroundColor: AppColors.driverPrimary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card (Giữ nguyên)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.driverPrimary.withOpacity(0.2),
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'D',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.driverPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.driverPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(
                        color: AppColors.driverPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ----- THÊM PHẦN LIÊN HỆ KHẨN CẤP -----
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.call_outlined, // Icon gọi điện
                    color: AppColors.success, // Màu xanh lá
                  ),
                  title: const Text('Gọi khẩn cấp Chủ xe'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _callOwner(context), // <-- Gọi hàm
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.sms_outlined, // Icon nhắn tin
                    color: AppColors.warning, // Màu vàng
                  ),
                  title: const Text('Nhắn tin Chủ xe'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _textOwner(context), // <-- Gọi hàm
                ),
              ],
            ),
          ),

          // ------------------------------------
          const SizedBox(height: 24),

          // Settings Options (Giữ nguyên)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.person_outline,
                    color: AppColors.driverPrimary,
                  ),
                  title: const Text('Thông tin cá nhân'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to profile
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.lock_outline,
                    color: AppColors.driverPrimary,
                  ),
                  title: const Text('Đổi mật khẩu'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to change password
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.history,
                    color: AppColors.driverPrimary,
                  ),
                  title: const Text('Lịch sử giao hàng'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to history
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout Button (Giữ nguyên)
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _handleLogout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Đăng xuất',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // App Info (Giữ nguyên)
          Center(
            child: Column(
              children: [
                Text(
                  'Delivery Management System',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // (Widget _buildStatItem giữ nguyên, hiện không được dùng)
  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppColors.driverPrimary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.driverPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
