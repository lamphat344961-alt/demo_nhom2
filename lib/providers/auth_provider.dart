import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../core/services/storage_service.dart';
import '../core/services/auth_service.dart';

enum AutoLoginResult { none, okOwner, okDriver, invalid }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _role, _fullName, _errorMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get role => _role;
  String? get fullName => _fullName;
  String? get errorMessage => _errorMessage;

  bool get isOwner => _role?.toLowerCase() == 'owner';
  bool get isDriver => _role?.toLowerCase() == 'driver';

  /// 1) SILENT: không notify, không đụng widget tree
  Future<AutoLoginResult> silentCheckAutoLogin() async {
    final token = StorageService.getToken();
    final role = StorageService.getRole();
    final name = StorageService.getFullName();

    if (token == null || token.isEmpty || role == null)
      return AutoLoginResult.none;
    try {
      if (JwtDecoder.isExpired(token)) return AutoLoginResult.invalid;
    } catch (_) {
      return AutoLoginResult.invalid;
    }
    // Trả kết quả để UI quyết định điều hướng
    if (role.toLowerCase() == 'owner') return AutoLoginResult.okOwner;
    if (role.toLowerCase() == 'driver') return AutoLoginResult.okDriver;
    return AutoLoginResult.invalid;
  }

  /// 2) Áp trạng thái sau khi UI đã điều hướng (notify lúc này an toàn)
  Future<void> applyAutoLogin() async {
    _isAuthenticated = true;
    _role = StorageService.getRole();
    _fullName = StorageService.getFullName();
    notifyListeners();
  }

  /// 3) Đăng nhập chuẩn
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _authService.login(username, password);
      if (result['success'] == true) {
        _isAuthenticated = true;
        _role = result['role'];
        _fullName = result['fullName'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Đăng nhập thất bại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 4) Logout: chỉ notify khi UI đã rời màn hiện tại
  Future<void> logout() async {
    await _authService.logout(); // clear storage
    _isAuthenticated = false;
    _role = null;
    _fullName = null;
    _errorMessage = null;
    notifyListeners();
  }
}
