// [GIẢ ĐỊNH] Bạn cần import 2 file này
import 'package:demo_nhom2/models/order_model.dart';
// (File 'order_model.dart' chứa cả OrderModel, DeliveryPointModel, và VehicleModel)

// [THÊM MỚI] Import màn hình chi tiết
import 'package:demo_nhom2/screens/owner/order_details_screen.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class ManageOrdersTab extends StatefulWidget {
  const ManageOrdersTab({super.key});

  @override
  State<ManageOrdersTab> createState() => _ManageOrdersTabState();
}

class _ManageOrdersTabState extends State<ManageOrdersTab> {
  final ApiService _api = ApiService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Dữ liệu cho các Dropdown trong Dialog
  List<DeliveryPointModel> _deliveryPoints = [];
  List<VehicleModel> _vehicles = [];

  @override
  void initState() {
    super.initState();
    // Tải đồng thời cả đơn hàng, điểm giao, và xe
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Chạy song song 3 API calls
      final responses = await Future.wait([
        _api.get(ApiConstants.orders),
        _api.get(ApiConstants.deliveryPoints), // /api/DiemGiao
        _api.get(ApiConstants.vehicles), // /api/Xe
      ]);

      final List ordersData = responses[0].data;
      final List pointsData = responses[1].data;
      final List vehiclesData = responses[2].data;

      setState(() {
        _orders = ordersData.map((json) => OrderModel.fromJson(json)).toList();
        _deliveryPoints = pointsData
            .map((json) => DeliveryPointModel.fromJson(json))
            .toList();
        _vehicles = vehiclesData
            .map((json) => VehicleModel.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // Tách hàm load orders để dùng cho RefreshIndicator
  Future<void> _loadOrders() async {
    // Không cần set _isLoading = true ở đây để refresh mượt hơn
    // (RefreshIndicator có loading riêng)
    try {
      final response = await _api.get(ApiConstants.orders);
      final List data = response.data;

      setState(() {
        _orders = data.map((json) => OrderModel.fromJson(json)).toList();
        _errorMessage = null; // Xóa lỗi cũ nếu refresh thành công
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _showAddDialog() async {
    // Controllers cho các trường
    final madonController = TextEditingController();
    final tongtienController = TextEditingController(text: '0');
    final maloaiController = TextEditingController();

    // State cho Dropdowns
    DeliveryPointModel? selectedPoint;
    VehicleModel? selectedVehicle;
    final formKey = GlobalKey<FormState>();

    // (Giả định _deliveryPoints và _vehicles đã được tải trong _loadAllData)

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Thêm đơn hàng'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: madonController,
                      decoration: const InputDecoration(
                        labelText: 'Mã đơn *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Vui lòng nhập mã đơn'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // DROPDOWN CHỌN ĐIỂM GIAO (Bắt buộc)
                    DropdownButtonFormField<DeliveryPointModel>(
                      value: selectedPoint,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Điểm giao hàng *',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Chọn điểm giao'),
                      items: _deliveryPoints.map((point) {
                        return DropdownMenuItem<DeliveryPointModel>(
                          value: point,
                          child: Text(
                            '${point.ten} (${point.vitri})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPoint = value;
                        });
                      },
                      validator: (value) =>
                          (value == null) ? 'Vui lòng chọn điểm giao' : null,
                    ),
                    const SizedBox(height: 16),

                    // DROPDOWN CHỌN XE (Không bắt buộc)
                    DropdownButtonFormField<VehicleModel>(
                      value: selectedVehicle,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Gán cho xe', // Không bắt buộc
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Chọn xe (nếu có)'),
                      items: _vehicles.map((vehicle) {
                        return DropdownMenuItem<VehicleModel>(
                          value: vehicle,
                          child: Text(
                            '${vehicle.bsXe} (${vehicle.tenxe ?? "N/A"})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedVehicle = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: maloaiController,
                      decoration: const InputDecoration(
                        labelText: 'Mã loại hàng *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Vui lòng nhập mã loại'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: tongtienController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tổng tiền',
                        border: OutlineInputBorder(),
                        prefixText: '₫ ',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() != true) {
                    return;
                  }

                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  // Dữ liệu gửi đi (đã sửa lỗi 'toIso817String')
                  final Map<String, dynamic> body = {
                    'madon': madonController.text,
                    'ngaylap': DateTime.now().toIso8601String(), // <-- Sửa lỗi
                    'tongtien': double.tryParse(tongtienController.text) ?? 0,
                    'd_DD': selectedPoint!.idDD,
                    'maloai': maloaiController.text,
                    'trangthai': 'Mới',
                    'bS_XE':
                        selectedVehicle?.bsXe, // Gửi biển số xe (có thể null)
                  };

                  try {
                    await _api.post(ApiConstants.orders, data: body);

                    navigator.pop();
                    _loadOrders(); // Tải lại danh sách
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Thêm đơn hàng thành công')),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Lỗi: ${e.toString()}')),
                    );
                  }
                },
                child: const Text('Thêm'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteOrder(String madon) async {
    final messenger = ScaffoldMessenger.of(context);
    final currentContext = context;

    final confirm = await showDialog<bool>(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa đơn hàng $madon?'),
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
      await _api.delete(ApiConstants.orderById(madon));
      _loadOrders();

      messenger.showSnackBar(
        const SnackBar(content: Text('Xóa đơn hàng thành công')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_errorMessage != null) {
      return ErrorDisplayWidget(
        message: _errorMessage!,
        onRetry: _loadAllData, // Dùng _loadAllData khi retry
      );
    }

    if (_orders.isEmpty) {
      return const Center(child: Text('Chưa có đơn hàng nào'));
    }

    return RefreshIndicator(
      onRefresh: _loadOrders, // Chỉ tải lại orders
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Đơn hàng'),
        backgroundColor: AppColors.ownerPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
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

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),

        // ----- THÊM SỰ KIỆN ONTAP -----
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(order: order),
            ),
          ).then((_) {
            // Tải lại danh sách đơn hàng khi quay lại
            // để cập nhật tổng tiền (nếu chi tiết đơn hàng thay đổi)
            _loadOrders();
          });
        },

        // -------------------------
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.inventory_2, color: AppColors.primary),
        ),
        title: Text(
          order.madon,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Ngày lập: ${DateFormat('dd/MM/yyyy').format(order.ngaylap)}'),
            Text(
              'Tổng tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(order.tongtien)}',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (order.bsXe != null && order.bsXe!.isNotEmpty)
              Text('Xe: ${order.bsXe}'),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
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
            if (value == 'delete') {
              _deleteOrder(order.madon);
            }
          },
        ),
      ),
    );
  }
}
