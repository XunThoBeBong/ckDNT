import 'dart:async';

/// Service để notify các screen cần reload product data
/// Sử dụng khi có thay đổi về products (ví dụ: sau khi checkout)
class ProductRefreshService {
  static final ProductRefreshService _instance =
      ProductRefreshService._internal();
  factory ProductRefreshService() => _instance;
  ProductRefreshService._internal();

  final _refreshController = StreamController<bool>.broadcast();

  /// Stream để lắng nghe khi cần refresh products
  Stream<bool> get refreshStream => _refreshController.stream;

  /// Notify tất cả listeners cần refresh products
  void notifyRefresh() {
    _refreshController.add(true);
  }

  void dispose() {
    _refreshController.close();
  }
}
