import 'package:flutter/material.dart';

import '../core/constants/api_constants.dart';
import '../core/services/api_service.dart';
import '../models/route_model.dart';

class RouteProvider with ChangeNotifier {
  final _api = ApiService();
  bool loading = false;
  String? error;

  // Dữ liệu được chia sẻ
  RouteModel? route;
  Map<int, String> pointIdToMaDonMap = {}; // <-- THÊM BIẾN MAP LIÊN KẾT

  Future<bool> optimizeRoute(
    List<Map<String, dynamic>> points, {
    required Map<int, String> pointIdMap, // <-- YÊU CẦU CUNG CẤP MAP
    int vehicleSpeedKph = 40,
    int? departureEpoch,
  }) async {
    loading = true;
    error = null;
    route = null;
    pointIdToMaDonMap = {}; // Xóa map cũ
    notifyListeners();
    try {
      final res = await _api.post(
        '/Route/optimize', // API bạn chỉ định
        data: {
          'vehicleSpeedKph': vehicleSpeedKph,
          'departureEpoch': departureEpoch ?? 0,
          'points': points,
        },
      );

      if (res.statusCode != 200 || res.data is! Map<String, dynamic>) {
        throw Exception('Tối ưu thất bại (mã: ${res.statusCode})');
      }

      // Lưu cả 2 kết quả
      route = RouteModel.fromJson(res.data as Map<String, dynamic>);
      pointIdToMaDonMap = pointIdMap; // <-- LƯU MAP LIÊN KẾT

      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }
}
