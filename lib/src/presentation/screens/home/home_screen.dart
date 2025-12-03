import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/injection/service_locator.dart';
import '../../../core/services/mongo_service.dart';
import '../../../core/services/product_refresh_service.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../data/models/product_model.dart';
import '../../config/themes/app_colors.dart';
import '../../widgets/product_card.dart';
import '../../widgets/skeletons/product_card_skeleton.dart';
import '../../widgets/skeletons/category_skeleton.dart';
import '../../widgets/skeletons/banner_skeleton.dart';
import '../product_detail/product_detail_screen.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/banner_slider_widget.dart';
import 'widgets/category_list_widget.dart';
import 'widgets/product_section_widget.dart';

/// HomeScreen - Màn hình trang chủ của ứng dụng ecommerce
///
/// Bao gồm:
/// - Search bar
/// - Banner slider
/// - Categories
/// - Featured products
/// - Popular products
/// - Tất cả sản phẩm (GridView)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ============================================
  // State Variables
  // ============================================
  List<ProductModel> _allProducts = [];
  List<ProductModel> _featuredProducts = [];
  List<ProductModel> _popularProducts = [];
  List<ProductModel> _searchResults = [];
  List<ProductModel> _filteredProducts =
      []; // Sản phẩm sau khi filter theo category
  bool _isLoading = true;
  bool _isSearching = false;
  String? _selectedCategory; // Category được chọn
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<bool>? _refreshSubscription;

  // ============================================
  // Lifecycle
  // ============================================
  @override
  void initState() {
    super.initState();
    _loadProducts();
    // Lắng nghe refresh event từ ProductRefreshService
    _refreshSubscription = ProductRefreshService().refreshStream.listen((_) {
      if (mounted) {
        _loadProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshSubscription?.cancel();
    super.dispose();
  }

  // ============================================
  // Data Loading
  // ============================================
  /// Load tất cả sản phẩm từ MongoDB
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mongoService = getIt<MongoService>();

      // Load song song các loại sản phẩm
      final results = await Future.wait([
        mongoService.getProducts(
          limit: 50, // Lấy 50 sản phẩm đầu tiên
          inStock: true, // Chỉ lấy sản phẩm còn hàng
          status: 'active', // Chỉ lấy sản phẩm active
          sortBy: 'createdAt',
          sortOrder: -1, // Mới nhất trước
        ),
        mongoService.getFeaturedProducts(limit: 10, inStock: true),
        mongoService.getPopularProducts(limit: 10, inStock: true),
      ]);

      if (mounted) {
        setState(() {
          _allProducts = results[0];
          _featuredProducts = results[1];
          _popularProducts = results[2];
          _isLoading = false;
          // Khởi tạo filtered products
          if (_selectedCategory != null) {
            _filterProductsByCategory(_selectedCategory);
          } else {
            _filteredProducts = _allProducts;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải sản phẩm: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  // ============================================
  // AppBar
  // ============================================
  /// Xây dựng AppBar với search bar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Ecommerce App'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SearchBarWidget(
            onSearchResults: (results) {
              setState(() {
                _searchResults = results;
                _isSearching = results.isNotEmpty;
              });
            },
          ),
        ),
      ),
    );
  }

  // ============================================
  // Body
  // ============================================
  /// Xây dựng body với các sections
  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return _buildSkeletonLoading(context);
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nếu đang search, chỉ hiển thị kết quả tìm kiếm
            if (_isSearching) ...[
              _buildSearchResultsSection(context),
            ] else ...[
              // Banner Slider
              const BannerSliderWidget(),

              const SizedBox(height: 16),

              // Categories Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Danh mục',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 12),
              CategoryListWidget(
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                    _filterProductsByCategory(category);
                  });
                },
              ),

              const SizedBox(height: 24),

              // Featured Products Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sản phẩm nổi bật',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to all featured products
                      },
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ProductSectionWidget(
                title: 'Sản phẩm nổi bật',
                products: _featuredProducts,
              ),

              const SizedBox(height: 24),

              // Popular Products Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sản phẩm phổ biến',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to all popular products
                      },
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ProductSectionWidget(
                title: 'Sản phẩm phổ biến',
                products: _popularProducts,
              ),

              const SizedBox(height: 24),

              // Tất cả sản phẩm - GridView (hoặc filtered products)
              _selectedCategory != null
                  ? _buildFilteredProductsSection(context)
                  : _buildAllProductsSection(context),

              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================
  // All Products Grid Section
  // ============================================
  /// Section hiển thị tất cả sản phẩm dưới dạng GridView
  Widget _buildAllProductsSection(BuildContext context) {
    if (_allProducts.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.inventory_2_outlined,
        title: 'Chưa có sản phẩm',
        message: 'Hiện tại chưa có sản phẩm nào trong cửa hàng',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tất cả sản phẩm',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                '${_allProducts.length} sản phẩm',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // GridView
        _buildProductsGrid(context),
      ],
    );
  }

  /// Xây dựng GridView hiển thị sản phẩm
  Widget _buildProductsGrid(BuildContext context) {
    // Responsive: Mobile dùng 2 cột, Tablet 3 cột, Desktop 4 cột
    final crossAxisCount = ResponsiveHelper.getProductGridColumns(context);

    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // Disable scroll riêng vì đã có SingleChildScrollView
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7, // Tỷ lệ width/height của card
      ),
      itemCount: _allProducts.length,
      itemBuilder: (context, index) {
        final product = _allProducts[index];
        return ProductCard(
          product: product,
          onTap: () {
            _navigateToProductDetail(context, product);
          },
        );
      },
    );
  }

  // ============================================
  // Search Results Section
  // ============================================
  /// Section hiển thị kết quả tìm kiếm
  Widget _buildSearchResultsSection(BuildContext context) {
    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.search_off,
        title: 'Không tìm thấy kết quả',
        message: 'Không có sản phẩm nào phù hợp với từ khóa tìm kiếm của bạn',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            'Kết quả tìm kiếm (${_searchResults.length})',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        // GridView với kích cỡ giống như _buildProductsGrid
        _buildSearchResultsGrid(context),
      ],
    );
  }

  /// Xây dựng GridView cho kết quả tìm kiếm
  Widget _buildSearchResultsGrid(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getProductGridColumns(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7, // Giống như _buildProductsGrid
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return ProductCard(
          product: product,
          onTap: () {
            _navigateToProductDetail(context, product);
          },
        );
      },
    );
  }

  // ============================================
  // Category Filtering
  // ============================================
  /// Filter sản phẩm theo category
  void _filterProductsByCategory(String? category) {
    if (category == null) {
      _filteredProducts = _allProducts;
      return;
    }

    setState(() {
      _filteredProducts = _allProducts.where((product) {
        // So sánh categoryName với category được chọn (case-insensitive)
        return product.categoryName?.toLowerCase() == category.toLowerCase();
      }).toList();
    });
  }

  // ============================================
  // Filtered Products Section
  // ============================================
  /// Section hiển thị sản phẩm đã filter theo category
  Widget _buildFilteredProductsSection(BuildContext context) {
    if (_filteredProducts.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.category_outlined,
        title: 'Không có sản phẩm',
        message:
            'Không tìm thấy sản phẩm nào trong danh mục "$_selectedCategory"',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header với nút Clear filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Danh mục: $_selectedCategory',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _filteredProducts = _allProducts;
                  });
                },
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Xóa bộ lọc'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // GridView
        _buildFilteredProductsGrid(context),
      ],
    );
  }

  /// Xây dựng GridView cho filtered products
  Widget _buildFilteredProductsGrid(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getProductGridColumns(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return ProductCard(
          product: product,
          onTap: () {
            _navigateToProductDetail(context, product);
          },
        );
      },
    );
  }

  // ============================================
  // Empty State
  // ============================================
  /// Xây dựng empty state đẹp
  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon với animation effect
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Message
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Action button (nếu cần)
            if (_selectedCategory != null)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _filteredProducts = _allProducts;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Xem tất cả sản phẩm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // Skeleton Loading
  // ============================================
  /// Xây dựng skeleton loading cho HomeScreen
  Widget _buildSkeletonLoading(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Skeleton
          const SizedBox(height: 16),
          const BannerSkeleton(),
          const SizedBox(height: 16),

          // Categories Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Danh mục',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 8,
              itemBuilder: (context, index) {
                return const CategorySkeleton();
              },
            ),
          ),
          const SizedBox(height: 24),

          // Featured Products Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sản phẩm nổi bật',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                TextButton(onPressed: null, child: const Text('Xem tất cả')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(width: 160, child: ProductCardSkeleton()),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Popular Products Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sản phẩm phổ biến',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                TextButton(onPressed: null, child: const Text('Xem tất cả')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(width: 160, child: ProductCardSkeleton()),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // All Products Grid Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tất cả sản phẩm',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '... sản phẩm',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildProductsGridSkeleton(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Xây dựng GridView skeleton cho products
  Widget _buildProductsGridSkeleton(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getProductGridColumns(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: 6, // Hiển thị 6 skeleton items
      itemBuilder: (context, index) {
        return const ProductCardSkeleton();
      },
    );
  }

  /// Navigate đến màn hình chi tiết sản phẩm
  void _navigateToProductDetail(BuildContext context, ProductModel product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }
}
