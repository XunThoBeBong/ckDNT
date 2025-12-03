import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../logic/cart/cart_bloc.dart';
import '../../../logic/cart/cart_event.dart';
import '../../../logic/cart/cart_state.dart';
import '../../../data/models/cart_item_model.dart';
import '../../config/themes/app_colors.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isExpanded = true; // Trạng thái mở rộng/thu gọn danh sách

  @override
  void initState() {
    super.initState();
    // Load giỏ hàng khi màn hình được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartBloc>().add(const LoadCartEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CartError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CartBloc>().add(const LoadCartEvent());
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is CartLoaded) {
            if (state.items.isEmpty) {
              return _buildEmptyCart();
            }

            return Column(
              children: [
                // Header với nút thu gọn/mở rộng
                _buildHeader(context, state),

                // Danh sách items (có thể thu gọn/mở rộng)
                Expanded(
                  child: _isExpanded
                      ? _buildCartItemsList(context, state.items)
                      : const SizedBox.shrink(),
                ),

                // Tổng tiền và nút thanh toán
                _buildCheckoutSection(context, state),
              ],
            );
          }

          // CartInitial state
          return _buildEmptyCart();
        },
      ),
    );
  }

  /// Header với nút thu gọn/mở rộng và checkbox chọn tất cả
  Widget _buildHeader(BuildContext context, CartLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Checkbox chọn tất cả
          Row(
            children: [
              Checkbox(
                value: state.allItemsSelected,
                onChanged: (bool? value) {
                  if (value != null) {
                    context.read<CartBloc>().add(ToggleAllItemsEvent(value));
                  }
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Chọn tất cả (${state.selectedItemCount}/${state.itemCount} món)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            tooltip: _isExpanded ? 'Thu gọn' : 'Mở rộng',
          ),
        ],
      ),
    );
  }

  /// Danh sách items trong giỏ hàng
  Widget _buildCartItemsList(BuildContext context, List<CartItemModel> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildCartItem(context, items[index]);
      },
    );
  }

  /// Widget hiển thị 1 item trong giỏ hàng
  Widget _buildCartItem(BuildContext context, CartItemModel item) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10), // Giảm từ 12 xuống 10
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox chọn/bỏ chọn item - giảm kích thước
            SizedBox(
              width: 24, // Giảm kích thước checkbox
              height: 24,
              child: Checkbox(
                value: item.isSelected,
                onChanged: (bool? value) {
                  if (value != null) {
                    context.read<CartBloc>().add(ToggleCartItemEvent(item.id));
                  }
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 6), // Giảm từ 8 xuống 6
            // Ảnh sản phẩm - giảm kích thước
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.product.image.isNotEmpty
                    ? item.product.image
                    : 'https://via.placeholder.com/100',
                width: 70, // Giảm từ 80 xuống 70
                height: 70, // Giảm từ 80 xuống 70
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 6), // Giảm từ 8 xuống 6
            // Thông tin sản phẩm
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên sản phẩm
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Màu sắc và kích cỡ
                  if (item.variantDisplay != 'Không có')
                    Text(
                      item.variantDisplay,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),

                  const SizedBox(height: 8),

                  // Giá và số lượng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Giá - wrap trong Flexible để tránh overflow
                      Flexible(
                        child: Text(
                          currencyFormat.format(item.product.discountedPrice),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 4), // Giảm từ 8 xuống 4
                      // Nút điều chỉnh số lượng - wrap trong Flexible
                      Flexible(
                        flex: 0, // Không cho phép mở rộng
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Nút giảm - giảm kích thước icon
                            InkWell(
                              onTap: () {
                                if (item.quantity > 1) {
                                  context.read<CartBloc>().add(
                                    UpdateCartItemQuantityEvent(
                                      productId: item.id,
                                      quantity: item.quantity - 1,
                                    ),
                                  );
                                } else {
                                  context.read<CartBloc>().add(
                                    RemoveProductFromCartEvent(item.id),
                                  );
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.remove_circle_outline,
                                  size: 18,
                                ),
                              ),
                            ),

                            // Số lượng - giảm padding
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Nút tăng (disable nếu đã đạt stock limit)
                            Builder(
                              builder: (context) {
                                final availableStock = item.product.stock ?? 0;
                                final canIncrease =
                                    item.quantity < availableStock;
                                return InkWell(
                                  onTap: canIncrease
                                      ? () {
                                          context.read<CartBloc>().add(
                                            UpdateCartItemQuantityEvent(
                                              productId: item.id,
                                              quantity: item.quantity + 1,
                                            ),
                                          );
                                        }
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.add_circle_outline,
                                      size: 18,
                                      color: canIncrease ? null : Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Tổng tiền của item
                  const SizedBox(height: 4),
                  Text(
                    'Tổng: ${currencyFormat.format(item.totalPrice)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            // Nút xóa - dùng InkWell thay vì IconButton để tiết kiệm không gian
            InkWell(
              onTap: () {
                _showDeleteConfirmation(context, item);
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 18, // Giảm từ 20 xuống 18
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hiển thị dialog xác nhận xóa
  void _showDeleteConfirmation(BuildContext context, CartItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text(
          'Bạn có chắc muốn xóa "${item.product.name}" khỏi giỏ hàng?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              context.read<CartBloc>().add(RemoveProductFromCartEvent(item.id));
              Navigator.of(context).pop();
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Section tổng tiền và nút thanh toán
  Widget _buildCheckoutSection(BuildContext context, CartLoaded state) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Quan trọng: giảm kích thước tối thiểu
        children: [
          // Tổng tiền
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Flexible(
                child: Text(
                  currencyFormat.format(state.totalPrice),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Giảm từ 16 xuống 12
          // Nút thanh toán
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to checkout screen
                context.push('/checkout');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Thanh toán',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget hiển thị khi giỏ hàng trống
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Giỏ hàng trống',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thêm sản phẩm vào giỏ hàng',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
