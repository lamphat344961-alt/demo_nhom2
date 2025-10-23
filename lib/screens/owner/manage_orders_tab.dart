import 'package:demo_nhom2/models/order_model.dart';
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

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _api.get(ApiConstants.orders);
      final List data = response.data;

      setState(() {
        _orders = data.map((json) => OrderModel.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _showAddDialog() async {

    final madonController = TextEditingController();
    final tongtienController = TextEditingController(text: '0');

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm đơn hàng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: madonController,
                decoration: const InputDecoration(
                  labelText: 'Mã đơn *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (madonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập mã đơn')),
                );
                return;
              }

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              try {
                await _api.post(
                  ApiConstants.orders,
                  data: {
                    'madon': madonController.text,
                    'ngaylap': DateTime.now().toIso8601String(),
                    'tongtien': double.tryParse(tongtienController.text) ?? 0,
                  },
                );

                navigator.pop();
                _loadOrders();
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
        onRetry: _loadOrders,
      );
    }

    if (_orders.isEmpty) {
      return const Center(child: Text('Chưa có đơn hàng nào'));
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
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
            if (order.bsXe != null) Text('Xe: ${order.bsXe}'),
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