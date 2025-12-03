import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../config/themes/app_colors.dart';
import '../../../widgets/product_card.dart';
import '../../../../data/models/product_model.dart';
import '../../../screens/product_detail/product_detail_screen.dart';

/// ProductSectionWidget - Widget hiển thị section sản phẩm
///
/// Sử dụng ResponsiveBuilder để thay đổi layout:
/// - Mobile: ListView ngang (horizontal scroll)
/// - Desktop: GridView (2-4 cột tùy màn hình)
class ProductSectionWidget extends StatelessWidget {
  final String title;
  final List<ProductModel> products;

  const ProductSectionWidget({
    super.key,
    required this.title,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return _buildEmptyState(context);
    }

    // TRƯỜNG HỢP CẦN ResponsiveBuilder: Cấu trúc layout thay đổi hoàn toàn
    // Mobile: ListView ngang, Desktop: GridView
    if (ResponsiveHelper.isMobile(context)) {
      // Mobile: ListView ngang (giữ nguyên UX mobile)
      return SizedBox(
        height: 280,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 160, // Width cố định cho ListView ngang
                child: ProductCard(
                  product: product,
                  onTap: () {
                    _navigateToProductDetail(context, product);
                  },
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Desktop/Tablet: GridView với số cột responsive
      final crossAxisCount = ResponsiveHelper.getProductGridColumns(context);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7, // Tỷ lệ width/height của card
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            onTap: () {
              _navigateToProductDetail(context, product);
            },
          );
        },
      );
    }
  }

  /// Navigate đến màn hình chi tiết sản phẩm
  void _navigateToProductDetail(BuildContext context, ProductModel product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có sản phẩm',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
