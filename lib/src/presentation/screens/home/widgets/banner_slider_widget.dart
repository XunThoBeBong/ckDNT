import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/themes/app_colors.dart';

/// BannerSliderWidget - Widget hiển thị banner slider với 3 hình ảnh
///
/// Tính năng:
/// - Swipe để lướt qua lại giữa các banner
/// - Auto-play tự động chuyển banner sau 3 giây
/// - Indicator dots hiển thị banner hiện tại
class BannerSliderWidget extends StatefulWidget {
  const BannerSliderWidget({super.key});

  @override
  State<BannerSliderWidget> createState() => _BannerSliderWidgetState();
}

class _BannerSliderWidgetState extends State<BannerSliderWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  // Danh sách 3 banner images
  // Bạn có thể thay đổi URLs này thành URLs thực tế từ Cloudinary hoặc assets
  final List<String> _bannerImages = [
    // Banner 1: Toy Store Sale (từ mô tả hình ảnh)
    'https://res.cloudinary.com/dl7v1hhr7/image/upload/images_o3rvsa.jpg',
    // Banner 2: Kids Fashion (từ mô tả hình ảnh)
    'https://res.cloudinary.com/dl7v1hhr7/image/upload/download_l4pj9s.jpg',
    // Banner 3: Flash Sale (từ mô tả hình ảnh)
    'https://res.cloudinary.com/dl7v1hhr7/image/upload/v1764797666/download_efldnn.jpg',
  ];

  @override
  void initState() {
    super.initState();
    // Bắt đầu auto-play sau khi widget được build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoPlay();
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Bắt đầu auto-play: tự động chuyển banner sau 3 giây
  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _bannerImages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  /// Dừng auto-play (khi user đang swipe)
  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
  }

  /// Tiếp tục auto-play
  void _resumeAutoPlay() {
    _startAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Height responsive: mobile 180px, desktop lớn hơn
        final height = constraints.maxWidth < 600 ? 180.0 : 250.0;

        return Column(
          children: [
            SizedBox(
              height: height,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  // Restart auto-play sau khi user swipe
                  _resumeAutoPlay();
                },
                itemCount: _bannerImages.length,
                itemBuilder: (context, index) {
                  return _buildBannerItem(_bannerImages[index], context);
                },
              ),
            ),
            const SizedBox(height: 8),
            // Indicator dots
            _buildPageIndicator(),
          ],
        );
      },
    );
  }

  /// Widget hiển thị một banner item
  Widget _buildBannerItem(String imageUrl, BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _stopAutoPlay(), // Dừng auto-play khi tap
      onTapUp: (_) => _resumeAutoPlay(), // Tiếp tục auto-play khi thả
      onTapCancel: () => _resumeAutoPlay(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            placeholder: (context, url) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    AppColors.primaryDark.withOpacity(0.3),
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_not_supported,
                      color: AppColors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Không thể tải hình ảnh',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget hiển thị indicator dots
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _bannerImages.length,
        (index) => _buildDot(index == _currentPage),
      ),
    );
  }

  /// Widget hiển thị một dot indicator
  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.greyLight,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
