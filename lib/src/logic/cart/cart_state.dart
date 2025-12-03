import 'package:equatable/equatable.dart';
import '../../data/models/cart_item_model.dart';

/// CartState - Base class cho tất cả states của CartBloc
abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

/// CartInitial - State khởi tạo
class CartInitial extends CartState {
  const CartInitial();
}

/// CartLoading - State đang load giỏ hàng
class CartLoading extends CartState {
  const CartLoading();
}

/// CartLoaded - State đã load giỏ hàng thành công
class CartLoaded extends CartState {
  final List<CartItemModel> items;
  final double totalPrice;

  const CartLoaded({required this.items, required this.totalPrice});

  @override
  List<Object?> get props => [items, totalPrice];

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Số lượng items được chọn
  int get selectedItemCount => items
      .where((item) => item.isSelected)
      .fold(0, (sum, item) => sum + item.quantity);

  /// Tính tổng tiền các món trong giỏ hàng (chỉ tính items được chọn)
  double get totalAmount => totalPrice;

  /// Kiểm tra tất cả items có được chọn không
  bool get allItemsSelected =>
      items.isNotEmpty && items.every((item) => item.isSelected);
}

/// CartError - State lỗi
class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}

/// CartItemFound - State tìm thấy item trong giỏ hàng
class CartItemFound extends CartState {
  final CartItemModel item;

  const CartItemFound(this.item);

  @override
  List<Object?> get props => [item];
}

/// CartItemNotFound - State không tìm thấy item trong giỏ hàng
class CartItemNotFound extends CartState {
  final String productId;

  const CartItemNotFound(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// ProductInCartState - State kiểm tra sản phẩm có trong giỏ hàng
class ProductInCartState extends CartState {
  final String productId;
  final bool isInCart;
  final int? quantity; // Số lượng nếu có trong giỏ hàng

  const ProductInCartState({
    required this.productId,
    required this.isInCart,
    this.quantity,
  });

  @override
  List<Object?> get props => [productId, isInCart, quantity];
}
