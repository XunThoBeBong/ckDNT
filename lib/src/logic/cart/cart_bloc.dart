import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';
import '../../data/models/cart_item_model.dart';

/// CartBloc - Quản lý state của giỏ hàng
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartInitial()) {
    // Danh sách items trong giỏ hàng (tạm thời lưu trong memory)
    List<CartItemModel> _cartItems = [];

    // Load cart (READ - All)
    on<LoadCartEvent>((event, emit) async {
      try {
        emit(const CartLoading());
        // TODO: Load từ storage hoặc API
        emit(
          CartLoaded(
            items: List.from(_cartItems),
            totalPrice: _calculateTotal(_cartItems),
          ),
        );
      } catch (e) {
        emit(CartError('Lỗi khi tải giỏ hàng: ${e.toString()}'));
      }
    });

    // Add product to cart (CREATE - Single)
    on<AddProductToCartEvent>((event, emit) async {
      try {
        // Validation: Kiểm tra tồn kho trước khi thêm vào giỏ
        final availableStock = event.product.stock ?? 0;
        if (availableStock <= 0) {
          emit(CartError('Sản phẩm "${event.product.name}" đã hết hàng'));
          return;
        }

        // Tạo cart item mới với các thuộc tính đầy đủ
        final newItem = CartItemModel(
          productId: event.product.id,
          product: event.product,
          quantity: event.quantity,
          color: event.color,
          size: event.size,
          category: event.category ?? event.product.categoryId,
        );

        // Tìm xem item tương tự đã có trong giỏ chưa (cùng productId, color, size)
        final existingIndex = _cartItems.indexWhere(
          (item) => item.isSameItem(newItem),
        );

        if (existingIndex >= 0) {
          // Nếu đã có item tương tự, tăng số lượng
          final currentQuantity = _cartItems[existingIndex].quantity;
          final newQuantity = currentQuantity + event.quantity;

          // Validation: Kiểm tra tồn kho sau khi tăng số lượng
          if (newQuantity > availableStock) {
            emit(
              CartError(
                'Sản phẩm "${event.product.name}" chỉ còn $availableStock sản phẩm (bạn đang có $currentQuantity trong giỏ)',
              ),
            );
            return;
          }

          _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
            quantity: newQuantity,
          );
        } else {
          // Validation: Kiểm tra số lượng thêm vào không vượt quá tồn kho
          if (event.quantity > availableStock) {
            emit(
              CartError(
                'Sản phẩm "${event.product.name}" chỉ còn $availableStock sản phẩm',
              ),
            );
            return;
          }

          // Nếu chưa có, thêm mới
          _cartItems.add(newItem);
        }

        emit(
          CartLoaded(
            items: List.from(_cartItems),
            totalPrice: _calculateTotal(_cartItems),
          ),
        );
      } catch (e) {
        emit(CartError('Lỗi khi thêm sản phẩm vào giỏ hàng: ${e.toString()}'));
      }
    });

    // Remove product from cart (DELETE - Single)
    // Có thể xóa bằng cart item id hoặc productId
    on<RemoveProductFromCartEvent>((event, emit) async {
      try {
        final initialLength = _cartItems.length;
        _cartItems.removeWhere(
          (item) =>
              item.id == event.productId || item.productId == event.productId,
        );

        if (_cartItems.length == initialLength) {
          emit(CartError('Không tìm thấy sản phẩm trong giỏ hàng'));
          return;
        }

        emit(
          CartLoaded(
            items: List.from(_cartItems),
            totalPrice: _calculateTotal(_cartItems),
          ),
        );
      } catch (e) {
        emit(CartError('Lỗi khi xóa sản phẩm khỏi giỏ hàng: ${e.toString()}'));
      }
    });

    // Update quantity (UPDATE - Quantity only)
    // Có thể update bằng cart item id hoặc productId
    on<UpdateCartItemQuantityEvent>((event, emit) async {
      try {
        final index = _cartItems.indexWhere(
          (item) =>
              item.id == event.productId || item.productId == event.productId,
        );

        if (index < 0) {
          emit(CartError('Không tìm thấy sản phẩm trong giỏ hàng'));
          return;
        }

        final item = _cartItems[index];
        final availableStock = item.product.stock ?? 0;

        if (event.quantity <= 0) {
          // Nếu quantity <= 0, xóa item
          _cartItems.removeAt(index);
        } else {
          // Validation: Kiểm tra tồn kho trước khi cập nhật số lượng
          if (event.quantity > availableStock) {
            emit(
              CartError(
                'Sản phẩm "${item.product.name}" chỉ còn $availableStock sản phẩm',
              ),
            );
            return;
          }

          _cartItems[index] = _cartItems[index].copyWith(
            quantity: event.quantity,
          );
        }

        emit(
          CartLoaded(
            items: List.from(_cartItems),
            totalPrice: _calculateTotal(_cartItems),
          ),
        );
      } catch (e) {
        emit(CartError('Lỗi khi cập nhật số lượng: ${e.toString()}'));
      }
    });

    // Clear cart
    on<ClearCartEvent>((event, emit) async {
      _cartItems.clear();
      emit(CartLoaded(items: [], totalPrice: 0.0));
    });

    // Get cart item by productId or cart item id (READ - Get one)
    on<GetCartItemEvent>((event, emit) async {
      try {
        final item = _cartItems.firstWhere(
          (item) =>
              item.id == event.productId || item.productId == event.productId,
          orElse: () => throw Exception('Item not found'),
        );
        emit(CartItemFound(item));
      } catch (e) {
        emit(CartItemNotFound(event.productId));
      }
    });

    // Update cart item (UPDATE - Full update)
    on<UpdateCartItemEvent>((event, emit) async {
      try {
        final index = _cartItems.indexWhere(
          (item) =>
              item.id == event.productId || item.productId == event.productId,
        );

        if (index < 0) {
          emit(CartError('Không tìm thấy sản phẩm trong giỏ hàng'));
          return;
        }

        if (event.quantity <= 0) {
          // Nếu quantity <= 0, xóa item
          _cartItems.removeAt(index);
        } else {
          final currentItem = _cartItems[index];
          final product = event.product ?? currentItem.product;
          final availableStock = product.stock ?? 0;

          // Validation: Kiểm tra tồn kho trước khi cập nhật số lượng
          if (event.quantity > availableStock) {
            emit(
              CartError(
                'Sản phẩm "${product.name}" chỉ còn $availableStock sản phẩm',
              ),
            );
            return;
          }

          // Update item với các thuộc tính mới
          _cartItems[index] = _cartItems[index].copyWith(
            product: product,
            quantity: event.quantity,
          );
        }

        emit(
          CartLoaded(
            items: List.from(_cartItems),
            totalPrice: _calculateTotal(_cartItems),
          ),
        );
      } catch (e) {
        emit(CartError('Lỗi khi cập nhật giỏ hàng: ${e.toString()}'));
      }
    });

    // Batch add to cart (CREATE - Multiple)
    on<BatchAddToCartEvent>((event, emit) async {
      try {
        for (final product in event.products) {
          final newItem = CartItemModel(
            productId: product.id,
            product: product,
            quantity: event.quantityPerProduct,
            category: product.categoryId,
          );

          final existingIndex = _cartItems.indexWhere(
            (item) => item.isSameItem(newItem),
          );

          if (existingIndex >= 0) {
            // Nếu đã có, tăng số lượng
            _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
              quantity:
                  _cartItems[existingIndex].quantity + event.quantityPerProduct,
            );
          } else {
            // Nếu chưa có, thêm mới
            _cartItems.add(newItem);
          }
        }

        emit(
          CartLoaded(
            items: List.from(_cartItems),
            totalPrice: _calculateTotal(_cartItems),
          ),
        );
      } catch (e) {
        emit(CartError('Lỗi khi thêm nhiều sản phẩm: ${e.toString()}'));
      }
    });

    // Batch remove from cart (DELETE - Multiple)
    on<BatchRemoveFromCartEvent>((event, emit) async {
      try {
        _cartItems.removeWhere(
          (item) => event.productIds.contains(item.productId),
        );

        emit(
          CartLoaded(
            items: List.from(_cartItems),
            totalPrice: _calculateTotal(_cartItems),
          ),
        );
      } catch (e) {
        emit(CartError('Lỗi khi xóa nhiều sản phẩm: ${e.toString()}'));
      }
    });

    // Check product in cart (READ - Check existence)
    on<CheckProductInCartEvent>((event, emit) async {
      try {
        final item = _cartItems.firstWhere(
          (item) => item.productId == event.productId,
          orElse: () => throw Exception('Not found'),
        );

        emit(
          ProductInCartState(
            productId: event.productId,
            isInCart: true,
            quantity: item.quantity,
          ),
        );
      } catch (e) {
        emit(ProductInCartState(productId: event.productId, isInCart: false));
      }
    });

    // Toggle selection cho một item (chọn/bỏ chọn)
    on<ToggleCartItemEvent>((event, emit) async {
      try {
        final index = _cartItems.indexWhere(
          (item) =>
              item.id == event.productId || item.productId == event.productId,
        );

        if (index < 0) {
          emit(CartError('Không tìm thấy sản phẩm trong giỏ hàng'));
          return;
        }

        final currentItem = _cartItems[index];
        // Đảo trạng thái isSelected bằng copyWith (vì model là immutable)
        _cartItems[index] = currentItem.copyWith(
          isSelected: !currentItem.isSelected,
        );

        emit(
          CartLoaded(
            items: List.from(_cartItems),
            totalPrice: _calculateTotal(_cartItems),
          ),
        );
      } catch (e) {
        emit(CartError('Lỗi khi chọn/bỏ chọn sản phẩm: ${e.toString()}'));
      }
    });

    // Toggle selection cho tất cả items (chọn tất cả/bỏ chọn tất cả)
    on<ToggleAllItemsEvent>((event, emit) async {
      try {
        // Cập nhật tất cả items với isSelected mới
        for (int i = 0; i < _cartItems.length; i++) {
          final currentItem = _cartItems[i];
          _cartItems[i] = currentItem.copyWith(isSelected: event.isSelected);
        }

        emit(
          CartLoaded(
            items: List.from(_cartItems),
            totalPrice: _calculateTotal(_cartItems),
          ),
        );
      } catch (e) {
        emit(CartError('Lỗi khi chọn/bỏ chọn tất cả: ${e.toString()}'));
      }
    });
  }

  /// Tính tổng giá trị giỏ hàng (chỉ tính các items được chọn)
  double _calculateTotal(List<CartItemModel> items) {
    return items
        .where((item) => item.isSelected) // Chỉ tính items được chọn
        .fold(
          0.0,
          (sum, item) => sum + (item.product.discountedPrice * item.quantity),
        );
  }
}
