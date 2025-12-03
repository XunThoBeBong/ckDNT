import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../data/models/product_model.dart';
import '../config/themes/app_colors.dart';

/// ProductCard - Widget hiển thị thẻ sản phẩm
///
/// Hiển thị:
/// - Ảnh sản phẩm (với Hero animation)
/// - Tên sản phẩm
/// - Giá (với discount nếu có)
/// - Rating
/// - Badge giảm giá (nếu có)
/// - Badge trạng thái (Hết hàng/Sắp hết hàng)
/// - Badge Featured (nếu là sản phẩm nổi bật)
/// - Nút thêm vào giỏ hàng
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    // 3. Format tiền tệ chuẩn VN (Giữ lại từ code của bạn)
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // Thêm bóng nhẹ cho nổi (Material style) thay vì Border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ẢNH SẢN PHẨM ---
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Hero(
                      tag: product.id,
                      child: CachedNetworkImage(
                        imageUrl: product.getOptimizedImage(width: 300),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),

                  // Badge Featured (Nổi bật) - Góc trên bên phải
                  if (product.featured == true)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[700],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Nổi bật',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Badge Giảm giá - Góc trên bên trái
                  if (product.isOnSale && product.discountTag.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.discountTag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Badge Trạng thái tồn kho - Góc dưới bên trái
                  if (!product.isInStock)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800]!.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Hết hàng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else if (product.isLowStock)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[700]!.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.stock != null
                              ? 'Còn ${product.stock}'
                              : 'Sắp hết',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Nút Thêm nhanh vào giỏ - Góc dưới bên phải
                  if (product.isInStock)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          onTap: onAddToCart,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.add_shopping_cart,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // --- THÔNG TIN ---
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên sản phẩm
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Giá tiền (với discount nếu có)
                  _buildPriceSection(currencyFormat),

                  const SizedBox(height: 6),

                  // Rating và số lượng đã bán
                  Row(
                    children: [
                      // Rating
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      Text(
                        ' ${product.rating}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Số lượng đã bán (nếu có)
                      if (product.soldCount != null &&
                          product.soldCount! > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${product.soldCount} đã bán',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section hiển thị giá tiền (với discount nếu có)
  Widget _buildPriceSection(NumberFormat currencyFormat) {
    // Có giảm giá
    if (product.isOnSale) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Giá sau giảm
          Text(
            currencyFormat.format(product.discountedPrice),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          // Giá gốc (gạch ngang)
          Row(
            children: [
              Text(
                currencyFormat.format(product.originalPrice ?? product.price),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Không có giảm giá
      return Text(
        currencyFormat.format(product.price),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      );
    }
  }
}
