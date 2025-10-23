import 'package:demo_nhom2/models/product_model.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class ManageProductsTab extends StatefulWidget {
  const ManageProductsTab({super.key});

  @override
  State<ManageProductsTab> createState() => _ManageProductsTabState();
}

class _ManageProductsTabState extends State<ManageProductsTab> {
  final ApiService _api = ApiService();
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _api.get(ApiConstants.products);
      setState(() {
        _products = (response.data as List)
            .map((json) => ProductModel.fromJson(json))
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

  Future<void> _showAddDialog() async {
    final mahhController = TextEditingController();
    final tenhhController = TextEditingController();
    final slController = TextEditingController(text: '0');
    final maloaiController = TextEditingController();

    final currentContext = context;

    return showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Thêm hàng hóa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: mahhController,
                decoration: const InputDecoration(labelText: 'Mã hàng hóa *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tenhhController,
                decoration: const InputDecoration(labelText: 'Tên hàng hóa *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: slController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số lượng *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maloaiController,
                decoration:
                const InputDecoration(labelText: 'Mã loại hàng (Tùy chọn)'),
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
              if (mahhController.text.isEmpty ||
                  tenhhController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Vui lòng điền Mã và Tên hàng hóa')),
                );
                return;
              }

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              try {
                await _api.post(
                  ApiConstants.products,
                  data: {
                    'mahh': mahhController.text,
                    'tenhh': tenhhController.text,
                    'sl': int.tryParse(slController.text) ?? 0,
                    'maloai': maloaiController.text.isNotEmpty
                        ? maloaiController.text
                        : null,
                  },
                );

                navigator.pop();
                _loadProducts();

                messenger.showSnackBar(
                  const SnackBar(content: Text('Thêm hàng hóa thành công')),
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

  Future<void> _showEditDialog(ProductModel product) async {
    final tenhhController = TextEditingController(text: product.tenhh);
    final slController = TextEditingController(text: product.sl.toString());
    final maloaiController = TextEditingController(text: product.maloai);

    final currentContext = context;

    await showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: Text('Sửa hàng hóa ${product.mahh}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tenhhController,
                decoration: const InputDecoration(labelText: 'Tên hàng hóa'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: slController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số lượng'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maloaiController,
                decoration: const InputDecoration(labelText: 'Mã loại hàng'),
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
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              try {
                await _api.put(
                  ApiConstants.productById(product.mahh),
                  data: {
                    'tenhh': tenhhController.text,
                    'sl': int.tryParse(slController.text) ?? 0,
                    'maloai': maloaiController.text.isNotEmpty
                        ? maloaiController.text
                        : null,
                  },
                );
                navigator.pop();
                _loadProducts();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Cập nhật hàng hóa thành công')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Lỗi: ${e.toString()}')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(String mahh) async {
    final currentContext = context;
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa hàng hóa $mahh?'),
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
      await _api.delete(ApiConstants.productById(mahh));
      _loadProducts(); // Tải lại
      messenger.showSnackBar(
        const SnackBar(content: Text('Xóa hàng hóa thành công')),
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
      return ErrorDisplayWidget(message: _errorMessage!, onRetry: _loadProducts);
    }
    if (_products.isEmpty) {
      return const Center(child: Text('Chưa có hàng hóa nào'));
    }
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.category, color: AppColors.warning),
              ),
              title: Text(
                product.tenhh ?? product.mahh,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                  'Mã: ${product.mahh}${product.maloai != null ? " - Loại: ${product.maloai}" : ""}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'SL: ${product.sl}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: const Row(children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Sửa'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete, color: AppColors.error, size: 20),
                          SizedBox(width: 8),
                          Text('Xóa', style: TextStyle(color: AppColors.error)),
                        ]),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditDialog(product);
                      } else if (value == 'delete') {
                        _deleteProduct(product.mahh);
                      }
                    },
                  ),
                ],
              ),
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
        title: const Text('Quản lý Hàng hóa'),
        backgroundColor: AppColors.ownerPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProducts),
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