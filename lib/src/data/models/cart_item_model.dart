import 'product_model.dart';

/// CartItemModel - Model cho item trong giỏ hàng
class CartItemModel {
  /// ID của cart item (unique identifier cho mỗi item trong giỏ hàng)
  final String id;

  /// ID của sản phẩm (reference đến ProductModel)
  final String productId;

  /// Thông tin sản phẩm đầy đủ
  final ProductModel product;

  /// Số lượng sản phẩm
  final int quantity;

  /// Màu sắc đã chọn (vd: "Đỏ", "Xanh", "Trắng", "#FF0000")
  final String? color;

  /// Kích cỡ đã chọn (vd: "S", "M", "L", "XL", "42", "43")
  final String? size;

  /// Danh mục sản phẩm (vd: "Áo quần", "Điện tử", "Phụ kiện")
  final String? category;

  /// Trạng thái được chọn để thanh toán (mặc định: true)
  final bool isSelected;

  CartItemModel({
    String? id,
    required this.productId,
    required this.product,
    required this.quantity,
    this.color,
    this.size,
    this.category,
    this.isSelected = true, // Mặc định được chọn
  }) : id = id ?? _generateId();

  /// Tạo ID tự động cho cart item (format: cart_item_timestamp_random)
  static String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'cart_item_${timestamp}_$random';
  }

  /// Tính giá trị của item (giá * số lượng)
  double get totalPrice => product.discountedPrice * quantity;

  /// Lấy danh mục từ product nếu category chưa được set
  String get categoryName => category ?? product.categoryId ?? 'Chưa phân loại';

  /// Tạo CartItemModel từ JSON
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      productId: json['productId']?.toString() ?? '',
      product: ProductModel.fromJson(json['product'] ?? {}),
      quantity: json['quantity'] is num ? json['quantity'].toInt() : 1,
      color: json['color']?.toString(),
      size: json['size']?.toString(),
      category: json['category']?.toString(),
      isSelected: json['isSelected'] is bool
          ? json['isSelected'] as bool
          : true,
    );
  }

  /// Chuyển CartItemModel sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'product': product.toJson(),
      'quantity': quantity,
      if (color != null) 'color': color,
      if (size != null) 'size': size,
      if (category != null) 'category': category,
      'isSelected': isSelected,
    };
  }

  /// Copy với các giá trị mới
  CartItemModel copyWith({
    String? id,
    String? productId,
    ProductModel? product,
    int? quantity,
    String? color,
    String? size,
    String? category,
    bool? isSelected,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      color: color ?? this.color,
      size: size ?? this.size,
      category: category ?? this.category,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  /// So sánh 2 cart items có giống nhau không (dùng để merge items)
  /// 2 items được coi là giống nhau nếu cùng productId, color và size
  bool isSameItem(CartItemModel other) {
    return productId == other.productId &&
        color == other.color &&
        size == other.size;
  }

  /// Tạo display text cho màu sắc và kích cỡ
  String get variantDisplay {
    final parts = <String>[];
    if (color != null && color!.isNotEmpty) {
      parts.add('Màu: $color');
    }
    if (size != null && size!.isNotEmpty) {
      parts.add('Size: $size');
    }
    return parts.isEmpty ? 'Không có' : parts.join(', ');
  }
}
