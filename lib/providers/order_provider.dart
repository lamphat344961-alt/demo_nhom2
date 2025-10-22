import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/services/api_service.dart';
import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
  final _api = ApiService();
  bool loading = false;
  String? error;
  List<OrderModel> items = [];

  Future<void> fetchAll() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await _api.get(ApiConstants.orders);
      final List data = res.data is List ? res.data : [];
      items = data.map((e) => OrderModel.fromJson(e)).toList();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> create(Map<String, dynamic> body) async {
    try {
      final res = await _api.post(ApiConstants.orders, data: body);
      final created = OrderModel.fromJson(res.data);
      items.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(String madon, Map<String, dynamic> body) async {
    try {
      final res = await _api.put(ApiConstants.orderById(madon), data: body);
      final updated = OrderModel.fromJson(res.data);
      final i = items.indexWhere((x) => x.madon == madon);
      if (i != -1) items[i] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> remove(String madon) async {
    try {
      await _api.delete(ApiConstants.orderById(madon));
      items.removeWhere((x) => x.madon == madon);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
