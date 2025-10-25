import 'package:demo_nhom2/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/route_model.dart';
import '../../providers/route_provider.dart';

class DeliveriesTab extends StatefulWidget {
  const DeliveriesTab({super.key});

  @override
  State<DeliveriesTab> createState() => _DeliveriesTabState();
}

class _DeliveriesTabState extends State<DeliveriesTab> {
  final ApiService _api = ApiService();
  List<DeliveryModel> _deliveries = [];
  bool _isLoading = true;
  bool _isSorted = false; // Trạng thái sắp xếp

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get(ApiConstants.myDeliveries);
      if (response.data is String) {
        setState(() {
          _deliveries = [];
          _isLoading = false;
        });
        return;
      }
      final List data = response.data;
      setState(() {
        _deliveries = data.map((json) => DeliveryModel.fromJson(json)).toList();
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

  Future<void> _launchGoogleMaps(DeliveryModel delivery) async {
    final String? address = delivery.diaChiGiao;
    if (address == null || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiếu địa chỉ để chỉ đường')),
      );
      return;
    }
    final query = Uri.encodeComponent(address);
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Không thể mở Google Maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _completeDelivery(DeliveryModel delivery) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hoàn thành'),
        content: Text(
          'Bạn đã giao hàng tại ${delivery.tenDiemGiao ?? delivery.idDiemGiao}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Chưa'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Dùng endpoint chính xác /api/Driver/complete/{maDon}
      await _api.post(ApiConstants.driverComplete(delivery.maDonHang));
      _loadDeliveries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đánh dấu hoàn thành'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  void _toggleSort() {
    final routeProvider = context.read<RouteProvider>();

    if (routeProvider.route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng qua tab "Bản đồ" để tối ưu tuyến trước.'),
          backgroundColor: AppColors.warning,
        ),
      );
      setState(() {
        _isSorted = false;
      });
    } else {
      setState(() {
        _isSorted = !_isSorted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<DeliveryModel> displayedDeliveries = List.from(_deliveries);

    // Lắng nghe (watch) để UI tự cập nhật nếu tuyến đường thay đổi
    final routeProvider = context.watch<RouteProvider>();

    if (_isSorted && routeProvider.route != null) {
      final route = routeProvider.route!;
      // Lấy map liên kết
      final map = routeProvider.pointIdToMaDonMap;

      // Tạo một map tra cứu (Key: maDonHang, Value: thứ tự sắp xếp)
      final Map<String, int> sortOrderMap = {};

      // Bỏ qua điểm 0 (kho)
      for (int i = 1; i < route.stops.length; i++) {
        final stop = route.stops[i];
        final int pointId = stop.pointId;
        final String? maDon = map[pointId]; // Tra cứu mã đơn từ map

        if (maDon != null) {
          // i chính là thứ tự sắp xếp (1, 2, 3...)
          sortOrderMap[maDon] = i;
        }
      }

      // Sắp xếp danh sách
      displayedDeliveries.sort((a, b) {
        final orderA = sortOrderMap[a.maDonHang] ?? 999;
        final orderB = sortOrderMap[b.maDonHang] ?? 999;
        return orderA.compareTo(orderB);
      });
    }
    // -------------------------

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách giao hàng'),
        backgroundColor: AppColors.driverPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isSorted ? Icons.list_alt : Icons.sort, // Thay đổi icon
            ),
            tooltip: 'Sắp xếp theo lộ trình',
            onPressed: _toggleSort,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeliveries,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDeliveries,
              child: displayedDeliveries.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 80,
                            color: AppColors.success,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Bạn không có đơn giao hàng nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: displayedDeliveries.length,
                      itemBuilder: (context, index) {
                        final delivery = displayedDeliveries[index];
                        return _buildDeliveryCard(delivery);
                      },
                    ),
            ),
    );
  }

  Widget _buildDeliveryCard(DeliveryModel delivery) {
    final isCompleted = delivery.trangThai.toUpperCase() == 'HOANTHANH';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.location_on,
                    color: isCompleted ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.tenDiemGiao ?? delivery.idDiemGiao,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Đơn hàng: ${delivery.maDonHang}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? 'Hoàn thành' : 'Chờ giao',
                    style: TextStyle(
                      color: isCompleted
                          ? AppColors.success
                          : AppColors.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            if (delivery.diaChiGiao != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.place,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      delivery.diaChiGiao!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // ----- KHU VỰC 2 NÚT BẤM -----
            if (!isCompleted) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _launchGoogleMaps(delivery),
                      icon: const Icon(Icons.navigation_outlined),
                      label: const Text('Bắt đầu'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.driverPrimary,
                        side: const BorderSide(color: AppColors.driverPrimary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _completeDelivery(delivery),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Hoàn thành'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
