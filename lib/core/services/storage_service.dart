import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _roleKey = 'user_role';
  static const String _fullNameKey = 'full_name';

  static SharedPreferences? _prefs;

  // Initialize
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token
  static Future<bool> saveToken(String token) async {
    return await _prefs?.setString(_tokenKey, token) ?? false;
  }

  static String? getToken() {
    return _prefs?.getString(_tokenKey);
  }

  static Future<bool> removeToken() async {
    return await _prefs?.remove(_tokenKey) ?? false;
  }

  static bool hasToken() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }

  // Role
  static Future<bool> saveRole(String role) async {
    return await _prefs?.setString(_roleKey, role) ?? false;
  }

  static String? getRole() {
    return _prefs?.getString(_roleKey);
  }

  static Future<bool> removeRole() async {
    return await _prefs?.remove(_roleKey) ?? false;
  }

  // Full Name
  static Future<bool> saveFullName(String fullName) async {
    return await _prefs?.setString(_fullNameKey, fullName) ?? false;
  }

  static String? getFullName() {
    return _prefs?.getString(_fullNameKey);
  }

  static Future<bool> removeFullName() async {
    return await _prefs?.remove(_fullNameKey) ?? false;
  }

  // Clear all
  static Future<bool> clearAll() async {
    await removeToken();
    await removeRole();
    await removeFullName();
    return true;
  }

  // Check if logged in
  static bool isLoggedIn() {
    return hasToken() && getRole() != null;
  }

  // Check role
  static bool isOwner() {
    return getRole()?.toLowerCase() == 'owner';
  }

  static bool isDriver() {
    return getRole()?.toLowerCase() == 'driver';
  }
}
