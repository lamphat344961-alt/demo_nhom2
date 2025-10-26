import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // <--- THÊM IMPORT

import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/user_model.dart'; // Đảm bảo UserModel có phoneNumber
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class ManageDriversTab extends StatefulWidget {
  const ManageDriversTab({super.key});

  @override
  State<ManageDriversTab> createState() => _ManageDriversTabState();
}

class _ManageDriversTabState extends State<ManageDriversTab> {
  final ApiService _api = ApiService();
  List<UserModel> _drivers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    // Chỉ set loading=true nếu chưa có dữ liệu hoặc có lỗi
    if (_drivers.isEmpty || _errorMessage != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _api.get(ApiConstants.drivers);
      final List data = response.data;

      // Kiểm tra mounted trước khi setState
      if (!mounted) return;
      setState(() {
        _drivers = data.map((json) => UserModel.fromJson(json)).toList();
        _isLoading = false;
        _errorMessage = null; // Xóa lỗi cũ nếu thành công
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // (Hàm _showAddDialog giữ nguyên code gốc của bạn)
  Future<void> _showAddDialog() async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final fullNameController = TextEditingController();
    final phoneController = TextEditingController();
    final cccdController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm tài xế'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Tên đăng nhập *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cccdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CCCD',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (usernameController.text.isEmpty ||
                  passwordController.text.isEmpty ||
                  fullNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Vui lòng điền đầy đủ thông tin bắt buộc (*)',
                    ),
                  ),
                );
                return;
              }
              // Sử dụng context an toàn hơn (tránh dùng biến cục bộ sau await)
              final currentContext = context;
              try {
                await _api.post(
                  ApiConstants.createDriver,
                  data: {
                    'username': usernameController.text,
                    'password': passwordController.text,
                    'fullName': fullNameController.text,
                    'phoneNumber': phoneController.text.isNotEmpty
                        ? phoneController.text
                        : null,
                    'cccd': cccdController.text.isNotEmpty
                        ? cccdController.text
                        : null,
                    'role': 'Driver',
                  },
                );

                if (!currentContext.mounted)
                  return; // Kiểm tra trước khi dùng context
                Navigator.pop(currentContext); // Đóng dialog
                await _loadDrivers(); // Tải lại dữ liệu

                if (!currentContext.mounted) return;
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  const SnackBar(content: Text('Thêm tài xế thành công')),
                );
              } catch (e) {
                if (!currentContext.mounted) return;
                ScaffoldMessenger.of(
                  currentContext,
                ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  // ----- HÀM MỚI: GỌI ĐIỆN CHO DRIVER -----
  Future<void> _callDriver(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tài xế này không có số điện thoại.')),
      );
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      // Dùng launchUrl trực tiếp, nó sẽ trả về false nếu không mở được
      if (!await launchUrl(launchUri)) {
        throw 'Không thể mở ứng dụng gọi điện thoại.';
      }
    } catch (e) {
      // Kiểm tra mounted trước khi hiển thị SnackBar
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }
  // ------------------------------------

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingWidget();
    }
    if (_errorMessage != null) {
      return ErrorDisplayWidget(message: _errorMessage!, onRetry: _loadDrivers);
    }
    if (_drivers.isEmpty) {
      return const Center(child: Text('Chưa có tài xế nào'));
    }

    return RefreshIndicator(
      onRefresh: _loadDrivers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _drivers.length,
        itemBuilder: (context, index) {
          final driver = _drivers[index];
          // Kiểm tra xem có số điện thoại hợp lệ không
          final bool hasValidPhone =
              driver.phoneNumber != null && driver.phoneNumber!.isNotEmpty;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              leading: CircleAvatar(
                backgroundColor: AppColors.ownerPrimary.withAlpha(51),
                child: Text(
                  driver.fullName.isNotEmpty
                      ? driver.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.ownerPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                driver.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Username: ${driver.username}'),
                  // Chỉ hiển thị SĐT nếu có
                  if (hasValidPhone) Text('SĐT: ${driver.phoneNumber!}'),
                  if (driver.cccd != null && driver.cccd!.isNotEmpty)
                    Text('CCCD: ${driver.cccd!}'),
                ],
              ),
              // ----- THÊM ICON GỌI ĐIỆN VÀO TRAILING -----
              trailing: hasValidPhone
                  ? IconButton(
                      icon: const Icon(
                        Icons.call_outlined,
                        color: AppColors.success,
                      ),
                      tooltip: 'Gọi ${driver.fullName}', // Tooltip hữu ích
                      // Gọi hàm _callDriver khi nhấn nút
                      onPressed: () => _callDriver(driver.phoneNumber),
                    )
                  : null, // Không hiển thị nút nếu không có SĐT
              // -------------------------------------------
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Tài xế'),
        backgroundColor: AppColors.ownerPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDrivers),
        ],
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.ownerPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
