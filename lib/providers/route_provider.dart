import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/services/api_service.dart';
import '../models/route_model.dart';

class RouteProvider with ChangeNotifier {
  final _api = ApiService();
  bool loading = false;
  String? error;
  RouteModel? route;

  Future<bool> optimizeFromOrders(
    List<String> orderIds, {
    int vehicleSpeedKph = 40,
    int? departureEpoch,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await _api.post(
        ApiConstants.optimizeRoute,
        data: {
          'orderIds': orderIds,
          'vehicleSpeedKph': vehicleSpeedKph,
          'departureEpoch':
              departureEpoch ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
        },
      );
      route = RouteModel.fromJson(res.data);
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
