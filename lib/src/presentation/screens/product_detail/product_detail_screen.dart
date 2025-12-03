import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/responsive_helper.dart';
import '../../../core/services/product_refresh_service.dart';
import '../../../core/services/mongo_service.dart';
import '../../../core/injection/service_locator.dart';
import '../../config/themes/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../logic/cart/cart_bloc.dart';
import '../../../logic/cart/cart_event.dart';
import '../../../logic/cart/cart_state.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkmarkAnimation;
  bool _isAddingToCart = false;
  bool _showSuccess = false;
  ProductModel? _currentProduct;
  StreamSubscription<bool>? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;

    // Khởi tạo AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Scale animation cho nút khi bấm
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Checkmark animation
    _checkmarkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // Lắng nghe refresh event để reload product data
    _refreshSubscription = ProductRefreshService().refreshStream.listen((_) {
      _reloadProduct();
    });
  }

  /// Reload product data từ DB
  Future<void> _reloadProduct() async {
    final productId = widget.product.id;
    if (productId == null || productId.isEmpty) return;

    try {
      final mongoService = getIt<MongoService>();
      final updatedProduct = await mongoService.getProductById(productId);
      if (updatedProduct != null && mounted) {
        setState(() {
          _currentProduct = updatedProduct;
        });
      }
    } catch (e) {
      // Silent fail - giữ nguyên product cũ nếu không load được
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng _currentProduct nếu có, nếu không dùng widget.product
    final product = _currentProduct ?? widget.product;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          // Hiển thị số lượng items trong giỏ hàng
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              int itemCount = 0;
              if (state is CartLoaded) {
                itemCount = state.itemCount;
              }
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      // TODO: Navigate to Cart Screen
                    },
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          itemCount > 99 ? '99+' : itemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocListener<CartBloc, CartState>(
        listener: (context, state) {
          if (state is CartLoaded && _isAddingToCart) {
            // Hiển thị animation thành công
            setState(() {
              _showSuccess = true;
            });
            _animationController.forward().then((_) {
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) {
                  setState(() {
                    _showSuccess = false;
                    _isAddingToCart = false;
                  });
                  _animationController.reset();
                }
              });
            });
          } else if (state is CartError && _isAddingToCart) {
            setState(() {
              _isAddingToCart = false;
            });
            _animationController.reset();
          }
        },
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildProductInfo(context),
            ),
          ],
        ),
      );
    } else {
      // Desktop: Row layout
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: _buildProductImage(context)),
                const SizedBox(width: 40),
                Expanded(flex: 1, child: _buildProductInfo(context)),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildProductImage(BuildContext context) {
    // Nếu có nhiều ảnh, hiển thị gallery
    if (widget.product.images != null && widget.product.images!.isNotEmpty) {
      return _buildImageGallery(context);
    }

    // Chỉ có 1 ảnh chính
    return Hero(
      tag: widget.product.id,
      child: Container(
        width: double.infinity,
        height: ResponsiveHelper.isMobile(context) ? 350 : 500,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: widget.product.image.isNotEmpty
                ? widget.product.image
                : 'https://via.placeholder.com/500',
            fit: BoxFit.contain,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) =>
                const Icon(Icons.broken_image, size: 50, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  /// Xây dựng image gallery với PageView
  Widget _buildImageGallery(BuildContext context) {
    final allImages = [
      if (widget.product.imageUrl != null &&
          widget.product.imageUrl!.isNotEmpty)
        widget.product.imageUrl!,
      ...?widget.product.images,
    ];

    return Column(
      children: [
        // Ảnh chính với PageView
        SizedBox(
          height: ResponsiveHelper.isMobile(context) ? 350 : 500,
          child: PageView.builder(
            itemCount: allImages.length,
            itemBuilder: (context, index) {
              return Hero(
                tag: '${widget.product.id}_$index',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: allImages[index],
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Dots indicator
        if (allImages.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                allImages.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    final product = _currentProduct ?? widget.product;
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tên sản phẩm
          Text(
            product.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Brand & SKU
          _buildBrandAndSku(context),

          const SizedBox(height: 12),

          // Rating & Reviews
          _buildRatingSection(context),

          const SizedBox(height: 16),

          // Stock Status
          _buildStockStatus(context),

          const SizedBox(height: 24),

          // Giá tiền với hiển thị giảm giá nếu có
          _buildPriceSection(context, currencyFormat),

          const SizedBox(height: 24),

          // Màu sắc & Kích cỡ (nếu có)
          if (widget.product.hasVariants) _buildVariantsSection(context),

          const SizedBox(height: 24),

          // Thông tin kỹ thuật
          _buildTechnicalInfo(context),

          const SizedBox(height: 24),

          // Mô tả ngắn
          _buildShortDescription(context),

          const SizedBox(height: 24),

          // Mô tả chi tiết
          _buildLongDescription(context),

          const SizedBox(height: 24),

          // Tags (nếu có)
          if (widget.product.tags != null && widget.product.tags!.isNotEmpty)
            _buildTagsSection(context),

          const SizedBox(height: 24),

          // Thống kê
          _buildStatsSection(context),

          const SizedBox(height: 40),

          // Nút Thêm vào giỏ với Animation
          _buildAddToCartButton(context),
        ],
      ),
    );
  }

  /// Section hiển thị Brand và SKU
  Widget _buildBrandAndSku(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (widget.product.brand != null && widget.product.brand!.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.business, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                widget.product.brand!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        if (widget.product.sku != null && widget.product.sku!.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'SKU: ${widget.product.sku}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
      ],
    );
  }

  /// Section hiển thị Rating
  Widget _buildRatingSection(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 20),
        const SizedBox(width: 4),
        Text(
          '${widget.product.rating}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Text(
          '(${widget.product.ratingCount} đánh giá)',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  /// Section hiển thị trạng thái tồn kho
  Widget _buildStockStatus(BuildContext context) {
    if (!widget.product.isInStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, size: 16, color: Colors.red[700]),
            const SizedBox(width: 8),
            Text(
              'Hết hàng',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.product.isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: Colors.orange[700],
            ),
            const SizedBox(width: 8),
            Text(
              widget.product.stock != null
                  ? 'Sắp hết hàng (Còn ${widget.product.stock} sản phẩm)'
                  : 'Sắp hết hàng',
              style: TextStyle(
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.product.stock != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 16,
              color: Colors.green[700],
            ),
            const SizedBox(width: 8),
            Text(
              'Còn hàng (${widget.product.stock} sản phẩm)',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPriceSection(BuildContext context, NumberFormat currencyFormat) {
    // Có discount
    if (widget.product.isOnSale) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                currencyFormat.format(widget.product.discountedPrice),
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
              const SizedBox(width: 16),
              if (widget.product.originalPrice != null)
                Text(
                  currencyFormat.format(widget.product.originalPrice!),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    decoration: TextDecoration.lineThrough,
                  ),
                )
              else
                Text(
                  currencyFormat.format(widget.product.price),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.product.discountTag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (widget.product.discountEndDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Giảm giá đến ${DateFormat('dd/MM/yyyy').format(widget.product.discountEndDate!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
        ],
      );
    } else {
      // Không có giảm giá
      return Text(
        currencyFormat.format(widget.product.price),
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
      );
    }
  }

  /// Section hiển thị màu sắc và kích cỡ
  Widget _buildVariantsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.product.availableColors.isNotEmpty) ...[
          Text(
            'Màu sắc:',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.product.availableColors.map((color) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(color, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (widget.product.availableSizes.isNotEmpty) ...[
          Text(
            'Kích cỡ:',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.product.availableSizes.map((size) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(size, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  /// Section hiển thị thông tin kỹ thuật
  Widget _buildTechnicalInfo(BuildContext context) {
    final hasInfo =
        widget.product.weight != null ||
        widget.product.length != null ||
        widget.product.width != null ||
        widget.product.height != null ||
        widget.product.barcode != null;

    if (!hasInfo) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin kỹ thuật:',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              if (widget.product.weight != null)
                _buildInfoRow('Trọng lượng', '${widget.product.weight} kg'),
              if (widget.product.length != null ||
                  widget.product.width != null ||
                  widget.product.height != null)
                _buildInfoRow(
                  'Kích thước',
                  '${widget.product.length ?? '-'} x ${widget.product.width ?? '-'} x ${widget.product.height ?? '-'} cm',
                ),
              if (widget.product.volume != null)
                _buildInfoRow(
                  'Thể tích',
                  '${widget.product.volume!.toStringAsFixed(2)} cm³',
                ),
              if (widget.product.barcode != null)
                _buildInfoRow('Mã vạch', widget.product.barcode!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Section hiển thị mô tả ngắn
  Widget _buildShortDescription(BuildContext context) {
    final description = widget.product.displayDescription;
    if (description.isEmpty || description == 'Chưa có mô tả') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mô tả:',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[700], height: 1.5),
        ),
      ],
    );
  }

  /// Section hiển thị mô tả chi tiết
  Widget _buildLongDescription(BuildContext context) {
    if (widget.product.longDescription == null ||
        widget.product.longDescription!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mô tả chi tiết:',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.product.longDescription!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  /// Section hiển thị tags
  Widget _buildTagsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags:',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.product.tags!.map((tag) {
            return Chip(
              label: Text(tag),
              backgroundColor: Colors.blue[50],
              labelStyle: TextStyle(color: Colors.blue[700]),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Section hiển thị thống kê
  Widget _buildStatsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (widget.product.soldCount != null && widget.product.soldCount! > 0)
            _buildStatItem(
              Icons.shopping_bag,
              'Đã bán',
              '${widget.product.soldCount}',
            ),
          if (widget.product.viewCount != null && widget.product.viewCount! > 0)
            _buildStatItem(
              Icons.visibility,
              'Lượt xem',
              '${widget.product.viewCount}',
            ),
          if (widget.product.ratingCount > 0)
            _buildStatItem(
              Icons.star,
              'Đánh giá',
              '${widget.product.ratingCount}',
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  /// Widget nút "Thêm vào giỏ hàng" với animation
  Widget _buildAddToCartButton(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Nút chính
                ElevatedButton.icon(
                  onPressed: _isAddingToCart
                      ? null
                      : () {
                          _handleAddToCart(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showSuccess
                        ? Colors.green
                        : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _showSuccess ? 8 : 0,
                  ),
                  icon: _showSuccess
                      ? ScaleTransition(
                          scale: _checkmarkAnimation,
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                          ),
                        )
                      : _isAddingToCart
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.add_shopping_cart,
                          color: Colors.white,
                        ),
                  label: Text(
                    _showSuccess
                        ? 'Đã thêm vào giỏ!'
                        : _isAddingToCart
                        ? 'Đang thêm...'
                        : 'Thêm vào giỏ hàng',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Ripple effect khi thành công
                if (_showSuccess)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.5,
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Xử lý logic thêm vào giỏ hàng
  void _handleAddToCart(BuildContext context) {
    // Lấy product hiện tại
    final currentProduct = _currentProduct ?? widget.product;

    // Bắt đầu animation
    setState(() {
      _isAddingToCart = true;
    });

    // Trigger scale animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Gọi CartBloc event
    context.read<CartBloc>().add(
      AddProductToCartEvent(
        currentProduct,
        quantity: 1,
        category: currentProduct.categoryId,
      ),
    );

    // Hiển thị Snackbar với animation đẹp
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Đã thêm ${(_currentProduct ?? widget.product).name} vào giỏ hàng!",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
