import 'package:shared_preferences/shared_preferences.dart';

/// StorageService - Service để lưu trữ dữ liệu local
///
/// Sử dụng SharedPreferences cho dữ liệu đơn giản
class StorageService {
  static SharedPreferences? _prefs;

  /// Khởi tạo SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Lưu string
  static Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  /// Lấy string
  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  /// Lưu int
  static Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  /// Lấy int
  static int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  /// Lưu bool
  static Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  /// Lấy bool
  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  /// Xóa key
  static Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  /// Xóa tất cả
  static Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }
}
