import 'package:equatable/equatable.dart';
import '../../data/models/product_model.dart';

/// CartEvent - Base class cho tất cả events của CartBloc
abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

/// AddProductToCartEvent - Event thêm sản phẩm vào giỏ hàng
class AddProductToCartEvent extends CartEvent {
  final ProductModel product;
  final int quantity;
  final String? color;
  final String? size;
  final String? category;

  const AddProductToCartEvent(
    this.product, {
    this.quantity = 1,
    this.color,
    this.size,
    this.category,
  });

  @override
  List<Object?> get props => [product, quantity, color, size, category];
}

/// RemoveProductFromCartEvent - Event xóa sản phẩm khỏi giỏ hàng
class RemoveProductFromCartEvent extends CartEvent {
  final String productId;

  const RemoveProductFromCartEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// UpdateCartItemQuantityEvent - Event cập nhật số lượng sản phẩm
class UpdateCartItemQuantityEvent extends CartEvent {
  final String productId;
  final int quantity;

  const UpdateCartItemQuantityEvent({
    required this.productId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [productId, quantity];
}

/// ClearCartEvent - Event xóa toàn bộ giỏ hàng
class ClearCartEvent extends CartEvent {
  const ClearCartEvent();
}

/// LoadCartEvent - Event load giỏ hàng từ storage/API
class LoadCartEvent extends CartEvent {
  const LoadCartEvent();
}

/// GetCartItemEvent - Event lấy 1 item trong giỏ hàng theo productId
class GetCartItemEvent extends CartEvent {
  final String productId;

  const GetCartItemEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// UpdateCartItemEvent - Event cập nhật toàn bộ thông tin item (không chỉ quantity)
class UpdateCartItemEvent extends CartEvent {
  final String productId;
  final int quantity;
  final ProductModel? product; // Optional: nếu muốn update product info

  const UpdateCartItemEvent({
    required this.productId,
    required this.quantity,
    this.product,
  });

  @override
  List<Object?> get props => [productId, quantity, product];
}

/// BatchAddToCartEvent - Event thêm nhiều sản phẩm vào giỏ hàng cùng lúc
class BatchAddToCartEvent extends CartEvent {
  final List<ProductModel> products;
  final int quantityPerProduct;

  const BatchAddToCartEvent({
    required this.products,
    this.quantityPerProduct = 1,
  });

  @override
  List<Object?> get props => [products, quantityPerProduct];
}

/// BatchRemoveFromCartEvent - Event xóa nhiều sản phẩm khỏi giỏ hàng cùng lúc
class BatchRemoveFromCartEvent extends CartEvent {
  final List<String> productIds;

  const BatchRemoveFromCartEvent(this.productIds);

  @override
  List<Object?> get props => [productIds];
}

/// CheckProductInCartEvent - Event kiểm tra sản phẩm có trong giỏ hàng không
class CheckProductInCartEvent extends CartEvent {
  final String productId;

  const CheckProductInCartEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// ToggleCartItemEvent - Event chọn/bỏ chọn một item trong giỏ hàng
class ToggleCartItemEvent extends CartEvent {
  final String productId; // Có thể là cart item id hoặc productId

  const ToggleCartItemEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// ToggleAllItemsEvent - Event chọn/bỏ chọn tất cả items trong giỏ hàng
class ToggleAllItemsEvent extends CartEvent {
  final bool isSelected;

  const ToggleAllItemsEvent(this.isSelected);

  @override
  List<Object?> get props => [isSelected];
}
