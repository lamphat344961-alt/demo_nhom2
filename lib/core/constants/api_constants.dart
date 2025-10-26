import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static final String baseUrl =
      dotenv.env['BASE_URL'] ?? 'https://localhost:7197/api';

  // Auth
  static const String login = '/Auth/login';
  static const String register = '/Auth/register';

  // Owner - Orders
  static const String orders = '/DonHang';
  static String orderById(String id) => '/DonHang/$id';

  // Owner - Vehicles
  static const String vehicles = '/Xe';
  static String vehicleById(String id) => '/Xe/$id';
  static String assignDriver(String bsxe) => '/Xe/$bsxe/assign-driver';
  static const String assignNfcCard =
      '/User/assign-nfc'; // Giả định API gán thẻ (sẽ tạo sau)
  static const String addDriverScore =
      '/Owner/add-score'; // 🆕 THÊM MỚI: API cộng điểm

  // Owner - Drivers
  static const String drivers = '/User/drivers';
  static const String createDriver = '/User/create-driver';

  // Owner - Delivery Points
  static const String deliveryPoints = '/DiemGiao';
  static String deliveryPointById(String id) => '/DiemGiao/$id';

  // Owner - Products
  static const String products = '/HangHoa';
  static String productById(String id) => '/HangHoa/$id';

  // Owner - Order Details
  static const String orderDetails = '/CtDonHang';

  // Owner - Assign Points to Order
  static const String assignPoints = '/CtDiemGiao';
  static const String pointsByOrder = '/CtDiemGiao/by-don';

  // Route Optimization
  static const String optimizeRoute = '/Route/optimize-from-orders';
  static String routeById(int id) => '/Route/$id';

  // Driver
  static const String myDeliveries = '/Driver/my-deliveries';
  static const String completeDelivery = '/CtDiemGiao/complete';
  // Thêm vào class ApiConstants:
  static String driverComplete(String maDon) => '/api/Driver/complete/$maDon';

  // Timeout
  static const Duration timeout = Duration(seconds: 30);
}
