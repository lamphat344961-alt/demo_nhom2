import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';

class ManageVehiclesTab extends StatefulWidget {
  const ManageVehiclesTab({super.key});

  @override
  State<ManageVehiclesTab> createState() => _ManageVehiclesTabState();
}

class _ManageVehiclesTabState extends State<ManageVehiclesTab> {
  final ApiService _api = ApiService();
  List<VehicleModel> _vehicles = [];
  List<UserModel> _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _api.get(ApiConstants.vehicles),
        _api.get(ApiConstants.drivers),
      ]);

      setState(() {
        _vehicles = (results[0].data as List)
            .map((json) => VehicleModel.fromJson(json))
            .toList();
        _drivers = (results[1].data as List)
            .map((json) => UserModel.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  Future<void> _showAddDialog() async {
    final bsXeController = TextEditingController();
    final tenXeController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm xe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bsXeController,
              decoration: const InputDecoration(
                labelText: 'Biển số xe *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tenXeController,
              decoration: const InputDecoration(
                labelText: 'Tên xe',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (bsXeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập biển số xe')),
                );
                return;
              }

              try {
                await _api.post(
                  ApiConstants.vehicles,
                  data: {
                    'bs_XE': bsXeController.text.toUpperCase(),
                    'tenxe': tenXeController.text,
                    'tt_XE': 'AVAILABLE',
                  },
                );

                Navigator.pop(context);
                _loadData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thêm xe thành công')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignDriver(VehicleModel vehicle) async {
    int? selectedDriverId = vehicle.userId;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Gán tài xế cho ${vehicle.bsXe}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_drivers.isEmpty)
                const Text('Chưa có tài xế nào')
              else
                ..._drivers.map((driver) {
                  return RadioListTile<int>(
                    title: Text(driver.fullName),
                    subtitle: Text(driver.phoneNumber ?? ''),
                    value: driver.userId,
                    groupValue: selectedDriverId,
                    onChanged: (value) {
                      setState(() {
                        selectedDriverId = value;
                      });
                    },
                  );
                }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: selectedDriverId == null
                  ? null
                  : () => Navigator.pop(context, selectedDriverId),
              child: const Text('Gán'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    try {
      await _api.put(
        ApiConstants.assignDriver(vehicle.bsXe),
        data: {'userId': result},
      );

      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gán tài xế thành công')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  Future<void> _deleteVehicle(String bsXe) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa xe $bsXe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.delete(ApiConstants.vehicleById(bsXe));
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Xóa xe thành công')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Xe'),
        backgroundColor: AppColors.ownerPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _vehicles.isEmpty
                  ? const Center(child: Text('Chưa có xe nào'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _vehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = _vehicles[index];
                        return _buildVehicleCard(vehicle);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.ownerPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVehicleCard(VehicleModel vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.local_shipping, color: AppColors.success),
        ),
        title: Text(
          vehicle.bsXe,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vehicle.tenxe != null) Text(vehicle.tenxe!),
            const SizedBox(height: 4),
            if (vehicle.driverFullName != null)
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    vehicle.driverFullName!,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else
              const Text(
                'Chưa có tài xế',
                style: TextStyle(color: AppColors.textSecondary),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'assign',
              child: Row(
                children: [
                  Icon(Icons.person_add, size: 20),
                  SizedBox(width: 8),
                  Text('Gán tài xế'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Text('Xóa'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'assign') {
              _assignDriver(vehicle);
            } else if (value == 'delete') {
              _deleteVehicle(vehicle.bsXe);
            }
          },
        ),
      ),
    );
  }
}
