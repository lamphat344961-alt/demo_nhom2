import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../models/order_detail_model.dart';
import '../../models/order_model.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final ApiService _api = ApiService();
  List<OrderDetailReadModel> _details = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Dữ liệu cho dialog "Thêm sản phẩm"
  List<ProductModel> _allProducts = [];
  bool _isProductsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
    _loadAllProducts(); // Tải sẵn danh sách sản phẩm
  }

  // Tải chi tiết đơn hàng (các sản phẩm đã có trong đơn)
  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Gọi API: GET /api/CtDonHang?madon=...
      final response = await _api.get(
        ApiConstants.orderDetails,
        queryParameters: {'madon': widget.order.madon},
      );
      final List data = response.data;
      setState(() {
        _details = data.map((e) => OrderDetailReadModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // Tải tất cả sản phẩm hiện có để hiển thị trong dialog
  Future<void> _loadAllProducts() async {
    _isProductsLoading = true;
    try {
      final response = await _api.get(
        ApiConstants.products,
      ); // GET /api/HangHoa
      final List data = response.data;
      setState(() {
        _allProducts = data.map((e) => ProductModel.fromJson(e)).toList();
      });
    } catch (e) {
      // Báo lỗi thầm lặng, không ảnh hưởng UI chính
      debugPrint("Lỗi tải sản phẩm: $e");
    }
    _isProductsLoading = false;
  }

  // Hiển thị Dialog để thêm sản phẩm
  Future<void> _showAddProductDialog() async {
    final formKey = GlobalKey<FormState>();
    ProductModel? selectedProduct;
    final slController = TextEditingController(text: '1');
    final dongiaController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Thêm sản phẩm'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<ProductModel>(
                        value: selectedProduct,
                        isExpanded: true,
                        hint: _isProductsLoading
                            ? const Text('Đang tải sản phẩm...')
                            : const Text('Chọn sản phẩm *'),
                        items: _allProducts.map((product) {
                          return DropdownMenuItem(
                            value: product,
                            child: Text(
                              '${product.tenhh} (${product.mahh})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (product) {
                          setDialogState(() {
                            selectedProduct = product;
                            // Tự động điền giá (nếu có)
                            // Giả định ProductModel có trường 'gia'
                            // dongiaController.text = (product?.gia ?? 0).toString();
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Vui lòng chọn sản phẩm' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: slController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số lượng *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập số lượng';
                          }
                          if ((int.tryParse(value) ?? 0) <= 0) {
                            return 'Số lượng phải > 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: dongiaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Đơn giá *',
                          border: OutlineInputBorder(),
                          prefixText: '₫ ',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập đơn giá';
                          }
                          if ((double.tryParse(value) ?? -1) < 0) {
                            return 'Đơn giá không hợp lệ';
                          }
                          return null;
                        },
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
                    if (formKey.currentState?.validate() != true) return;

                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);

                    final model = OrderDetailCreateModel(
                      madon: widget.order.madon,
                      mahh: selectedProduct!.mahh,
                      sl: int.parse(slController.text),
                      dongia: double.parse(dongiaController.text),
                    );

                    try {
                      // Gọi API: POST /api/CtDonHang
                      await _api.post(
                        ApiConstants.orderDetails,
                        data: model.toJson(),
                      );
                      navigator.pop();
                      _loadOrderDetails(); // Tải lại danh sách
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
        );
      },
    );
  }

  // (Bạn có thể thêm hàm _deleteProduct(mahh) tương tự)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết ĐH: ${widget.order.madon}'),
        backgroundColor: AppColors.ownerPrimary,
        foregroundColor: Colors.white,
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        backgroundColor: AppColors.ownerPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingWidget();
    }
    if (_errorMessage != null) {
      return ErrorDisplayWidget(
        message: _errorMessage!,
        onRetry: _loadOrderDetails,
      );
    }
    if (_details.isEmpty) {
      return const Center(child: Text('Đơn hàng này chưa có sản phẩm nào.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _details.length,
      itemBuilder: (context, index) {
        final item = _details[index];
        final formattedPrice = NumberFormat.currency(
          locale: 'vi_VN',
          symbol: '₫',
        ).format(item.dongia);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: Icon(Icons.widgets),
            ),
            title: Text(
              '${item.tenhh ?? "Sản phẩm"} (${item.mahh})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Số lượng: ${item.sl} x $formattedPrice'),
            trailing: Text(
              NumberFormat.currency(
                locale: 'vi_VN',
                symbol: '₫',
              ).format(item.sl * item.dongia),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            // (Bạn có thể thêm PopupMenuButton ở đây để Xóa)
          ),
        );
      },
    );
  }
}
