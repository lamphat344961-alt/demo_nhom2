import 'package:jwt_decoder/jwt_decoder.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _api.post(
        ApiConstants.login,
        data: {'username': username, 'password': password},
      );

      // Kiểm tra status code
      if (response.statusCode != 200) {
        throw 'Đăng nhập thất bại: ${response.statusMessage}';
      }

      // Kiểm tra response data
      if (response.data == null) {
        throw 'Server không trả về dữ liệu';
      }

      final data = response.data;

      // Backend  trả về: { token, fullName, role }
      final token = data['token'];
      final role = data['role'];
      final fullName = data['fullName'];

      if (token == null || token.isEmpty) {
        throw 'Token không hợp lệ';
      }

      // Validate token
      try {
        if (JwtDecoder.isExpired(token)) {
          throw 'Token đã hết hạn';
        }
      } catch (e) {
        throw 'Token không hợp lệ: $e';
      }

      // Save to storage
      await StorageService.saveToken(token);
      await StorageService.saveRole(role ?? 'User');
      await StorageService.saveFullName(fullName ?? username);

      return {'success': true, 'role': role, 'fullName': fullName};
    } catch (e) {
      // Re-throw với message rõ ràng
      if (e is String) {
        throw e;
      } else {
        throw 'Lỗi đăng nhập: ${e.toString()}';
      }
    }
  }

  Future<void> logout() async {
    await StorageService.clearAll();
  }

  bool isTokenValid() {
    final token = StorageService.getToken();
    if (token == null) return false;

    try {
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic>? getCurrentUser() {
    final token = StorageService.getToken();
    if (token == null) return null;

    try {
      return JwtDecoder.decode(token);
    } catch (e) {
      return null;
    }
  }

  Future<bool> checkAutoLogin() async {
    if (!StorageService.isLoggedIn()) return false;
    return isTokenValid();
  }
}
