/// AppConstants - Các hằng số của ứng dụng
class AppConstants {
  // Private constructor
  AppConstants._();

  // App Info
  static const String appName = 'Ecommerce App';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;

  // ============================================
  // Product Categories
  // ============================================
  /// Danh sách categories cho sản phẩm
  ///
  /// ⚠️ QUAN TRỌNG: Tên category phải khớp 100% với categoryName trong ProductModel
  /// để filtering hoạt động đúng. So sánh case-insensitive nhưng nên giữ chính tả đúng.
  static const List<String> productCategories = [
    'Quần áo',
    'Đồ chơi',
    'Giày dép',
    'Sách vở',
    'Đồ dùng học tập',
    'Phụ kiện',
    'Đồ chơi giáo dục',
    'Khác',
  ];
}
