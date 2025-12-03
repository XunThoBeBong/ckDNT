import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../config/themes/app_colors.dart';

/// CategoryListWidget - Widget hiển thị danh sách danh mục
class CategoryListWidget extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  const CategoryListWidget({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    // Danh mục phù hợp với shopping cho trẻ em
    // Sử dụng AppConstants.productCategories để đảm bảo đồng bộ với dropdown trong AddEditProductScreen
    final List<CategoryItem> categories = _buildCategoryItems();

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return _buildCategoryItem(categories[index], context);
        },
      ),
    );
  }

  Widget _buildCategoryItem(CategoryItem category, BuildContext context) {
    final isSelected = selectedCategory == category.label;

    return GestureDetector(
      onTap: () {
        // Nếu click vào category đang được chọn, thì bỏ chọn (show all)
        if (isSelected) {
          onCategorySelected(null);
        } else {
          onCategorySelected(category.label);
        }
      },
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isSelected
                    ? category.iconColor.withOpacity(
                        0.2,
                      ) // Active state: màu đậm hơn
                    : category.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(
                        color: category.iconColor,
                        width: 3, // Border đậm khi active
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? category.iconColor.withOpacity(
                            0.4,
                          ) // Shadow đậm hơn khi active
                        : category.iconColor.withOpacity(0.2),
                    blurRadius: isSelected ? 12 : 8, // Blur lớn hơn khi active
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                category.icon,
                color: isSelected
                    ? category
                          .iconColor // Màu đậm hơn khi active
                    : category.iconColor,
                size: isSelected ? 36 : 32, // Icon lớn hơn khi active
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? category
                          .iconColor // Màu chữ giống icon khi active
                    : AppColors.textPrimary,
                fontWeight: isSelected
                    ? FontWeight
                          .bold // Chữ đậm hơn khi active
                    : FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Xây dựng danh sách CategoryItem từ AppConstants.productCategories
  /// Đảm bảo label khớp 100% với category names trong dropdown
  List<CategoryItem> _buildCategoryItems() {
    // Map category name -> CategoryItem với icon và màu sắc
    final categoryConfig = {
      'Quần áo': CategoryItem(
        icon: Icons.child_care,
        label: 'Quần áo',
        backgroundColor: const Color(0xFFFFE5E5),
        iconColor: const Color(0xFFFF6B9D),
      ),
      'Đồ chơi': CategoryItem(
        icon: Icons.toys,
        label: 'Đồ chơi',
        backgroundColor: const Color(0xFFFFF4E5),
        iconColor: const Color(0xFFFFB84D),
      ),
      'Giày dép': CategoryItem(
        icon: Icons.shopping_bag,
        label: 'Giày dép',
        backgroundColor: const Color(0xFFE5F5FF),
        iconColor: const Color(0xFF4DA6FF),
      ),
      'Sách vở': CategoryItem(
        icon: Icons.menu_book,
        label: 'Sách vở',
        backgroundColor: const Color(0xFFE5FFE5),
        iconColor: const Color(0xFF4DFF4D),
      ),
      'Đồ dùng học tập': CategoryItem(
        icon: Icons.school,
        label: 'Đồ dùng học tập',
        backgroundColor: const Color(0xFFFFF0E5),
        iconColor: const Color(0xFFFFA64D),
      ),
      'Phụ kiện': CategoryItem(
        icon: Icons.auto_awesome,
        label: 'Phụ kiện',
        backgroundColor: const Color(0xFFF0E5FF),
        iconColor: const Color(0xFF9D6BFF),
      ),
      'Đồ chơi giáo dục': CategoryItem(
        icon: Icons.psychology,
        label: 'Đồ chơi giáo dục',
        backgroundColor: const Color(0xFFFFE5F5),
        iconColor: const Color(0xFFFF6BC4),
      ),
      'Khác': CategoryItem(
        icon: Icons.more_horiz,
        label: 'Khác',
        backgroundColor: const Color(0xFFE5E5E5),
        iconColor: const Color(0xFF999999),
      ),
    };

    // Build list từ AppConstants để đảm bảo thứ tự và tên khớp nhau
    return AppConstants.productCategories
        .map((categoryName) => categoryConfig[categoryName]!)
        .toList();
  }
}

/// CategoryItem - Model cho category
class CategoryItem {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;

  CategoryItem({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
  });
}
