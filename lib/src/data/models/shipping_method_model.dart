/// ShippingMethodModel - Model đại diện cho phương thức vận chuyển
class ShippingMethodModel {
  final String id;
  final String name;
  final String description; // Mô tả thời gian giao hàng
  final int minDays; // Số ngày tối thiểu
  final int maxDays; // Số ngày tối đa
  final double pricePerKm; // Phí vận chuyển trên 1km (VND)

  const ShippingMethodModel({
    required this.id,
    required this.name,
    required this.description,
    required this.minDays,
    required this.maxDays,
    required this.pricePerKm,
  });

  /// Tính phí vận chuyển dựa trên khoảng cách (km)
  double calculateShippingFee(double distanceKm) {
    return distanceKm * pricePerKm;
  }

  /// Lấy danh sách các phương thức vận chuyển mặc định
  static List<ShippingMethodModel> getDefaultMethods() {
    return [
      const ShippingMethodModel(
        id: 'basic',
        name: 'Cơ bản',
        description: '5-7 ngày',
        minDays: 5,
        maxDays: 7,
        pricePerKm: 1000.0,
      ),
      const ShippingMethodModel(
        id: 'fast',
        name: 'Nhanh',
        description: '3-4 ngày',
        minDays: 3,
        maxDays: 4,
        pricePerKm: 2000.0,
      ),
      const ShippingMethodModel(
        id: 'express',
        name: 'Hỏa tốc',
        description: '1-2 ngày',
        minDays: 1,
        maxDays: 2,
        pricePerKm: 5000.0,
      ),
    ];
  }

  /// Tìm phương thức vận chuyển theo ID
  static ShippingMethodModel? findById(String id) {
    return getDefaultMethods().firstWhere(
      (method) => method.id == id,
      orElse: () => getDefaultMethods().first,
    );
  }
}
