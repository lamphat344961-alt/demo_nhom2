import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/services/api_service.dart';
import '../models/vehicle_model.dart';

class VehicleProvider with ChangeNotifier {
  final _api = ApiService();
  bool loading = false;
  String? error;
  List<VehicleModel> items = [];

  Future<void> fetchAll() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await _api.get(ApiConstants.vehicles);
      final List data = res.data is List ? res.data : [];
      items = data.map((e) => VehicleModel.fromJson(e)).toList();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> create({
    required String bsXe,
    String? tenxe,
    String? ttXe,
    int? userId,
  }) async {
    try {
      final res = await _api.post(
        ApiConstants.vehicles,
        data: {'BS_XE': bsXe, 'TENXE': tenxe, 'TT_XE': ttXe, 'UserId': userId},
      );
      items.insert(0, VehicleModel.fromJson(res.data));
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(
    String bsXe, {
    String? tenxe,
    String? ttXe,
    int? userId,
  }) async {
    try {
      final res = await _api.put(
        ApiConstants.vehicleById(bsXe),
        data: {'TENXE': tenxe, 'TT_XE': ttXe, 'UserId': userId},
      );
      final updated = VehicleModel.fromJson(res.data);
      final i = items.indexWhere((v) => v.bsXe == bsXe);
      if (i != -1) items[i] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> remove(String bsXe) async {
    try {
      await _api.delete(ApiConstants.vehicleById(bsXe));
      items.removeWhere((v) => v.bsXe == bsXe);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
