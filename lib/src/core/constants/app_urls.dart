/// AppUrls - Quản lý các URL của API
class AppUrls {
  // Private constructor
  AppUrls._();

  // Base URL - TODO: Thay đổi khi có API thật
  static const String baseUrl = 'https://api.example.com';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // Product endpoints
  static const String products = '/products';
  static String productDetail(String id) => '/products/$id';
  static const String featuredProducts = '/products/featured';
  static const String popularProducts = '/products/popular';

  // Category endpoints
  static const String categories = '/categories';
  static String categoryProducts(String id) => '/categories/$id/products';

  // Cart endpoints
  static const String cart = '/cart';
  static String cartItem(String id) => '/cart/items/$id';

  // Order endpoints
  static const String orders = '/orders';
  static String orderDetail(String id) => '/orders/$id';

  // User endpoints
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';
}
