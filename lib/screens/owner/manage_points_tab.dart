import 'package:demo_nhom2/models/delivery_point_model.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class ManagePointsTab extends StatefulWidget {
  const ManagePointsTab({super.key});

  @override
  State<ManagePointsTab> createState() => _ManagePointsTabState();
}

class _ManagePointsTabState extends State<ManagePointsTab> {
  final ApiService _api = ApiService();
  List<DeliveryPointModel> _points = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _api.get(ApiConstants.deliveryPoints);
      setState(() {
        _points = (response.data as List)
            .map((json) => DeliveryPointModel.fromJson(json))
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
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();

    final currentContext = context;

    return showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Thêm điểm giao'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'Mã điểm *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên điểm *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Địa chỉ *',
                    hintText: 'Hệ thống sẽ tự lấy tọa độ nếu bỏ trống Lat/Lng'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: latController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                    const InputDecoration(labelText: 'Latitude (Tùy chọn)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: lngController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                    const InputDecoration(labelText: 'Longitude (Tùy chọn)'),
                  ),
                ),
              ]),
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
              if (idController.text.isEmpty ||
                  nameController.text.isEmpty ||
                  addressController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Vui lòng điền đủ Mã, Tên, Địa chỉ')),
                );
                return;
              }

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              try {
                await _api.post(
                  ApiConstants.deliveryPoints,
                  data: {
                    'idDD': idController.text,
                    'ten': nameController.text,
                    'vitri': addressController.text,
                    'lat': double.tryParse(latController.text),
                    'lng': double.tryParse(lngController.text),
                  },
                );

                navigator.pop();
                _loadPoints(); // Tải lại

                messenger.showSnackBar(
                  const SnackBar(content: Text('Thêm điểm giao thành công')),
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

  Future<void> _showEditDialog(DeliveryPointModel point) async {
    final nameController = TextEditingController(text: point.ten);
    final addressController = TextEditingController(text: point.vitri);
    final latController = TextEditingController(text: point.lat?.toString());
    final lngController = TextEditingController(text: point.lng?.toString());

    final currentContext = context;

    await showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: Text('Sửa điểm giao ${point.idDD}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên điểm'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: latController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Latitude'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: lngController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Longitude'),
                  ),
                ),
              ]),
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
                  ApiConstants.deliveryPointById(point.idDD),
                  data: {
                    'idDD': point.idDD,
                    'ten': nameController.text,
                    'vitri': addressController.text,
                    'lat': double.tryParse(latController.text),
                    'lng': double.tryParse(lngController.text),
                  },
                );
                navigator.pop();
                _loadPoints();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Cập nhật điểm giao thành công')),
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

  Future<void> _deletePoint(String idDD) async {
    final currentContext = context;
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa điểm giao $idDD?'),
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
      await _api.delete(ApiConstants.deliveryPointById(idDD));
      _loadPoints(); // Tải lại
      messenger.showSnackBar(
        const SnackBar(content: Text('Xóa điểm giao thành công')),
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
      return ErrorDisplayWidget(message: _errorMessage!, onRetry: _loadPoints);
    }
    if (_points.isEmpty) {
      return const Center(child: Text('Chưa có điểm giao nào'));
    }
    return RefreshIndicator(
      onRefresh: _loadPoints,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _points.length,
        itemBuilder: (context, index) {
          final point = _points[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on, color: AppColors.error),
              ),
              title: Text(
                point.ten ?? point.idDD,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (point.vitri != null) Text(point.vitri!),
                  if (point.lat != null && point.lng != null)
                    Text(
                      'Tọa độ: ${point.lat!.toStringAsFixed(4)}, ${point.lng!.toStringAsFixed(4)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                ],
              ),
              trailing: PopupMenuButton(
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
                    _showEditDialog(point);
                  } else if (value == 'delete') {
                    _deletePoint(point.idDD);
                  }
                },
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
        title: const Text('Quản lý Điểm giao'),
        backgroundColor: AppColors.ownerPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPoints),
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