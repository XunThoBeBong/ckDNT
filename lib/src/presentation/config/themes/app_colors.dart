import 'package:flutter/material.dart';

/// AppColors - Quản lý tất cả màu sắc của ứng dụng
/// 
/// Sử dụng các màu này thay vì hardcode màu để dễ dàng thay đổi theme sau này
class AppColors {
  // Private constructor để ngăn việc khởi tạo class
  AppColors._();

  // ============================================
  // Primary Colors (Màu chủ đạo)
  // ============================================
  static const Color primary = Color(0xFFE94057); // Màu đỏ cam chủ đạo
  static const Color primaryLight = Color(0xFFF5A5B3); // Màu primary nhạt hơn
  static const Color primaryDark = Color(0xFFC41E3A); // Màu primary đậm hơn
  
  // ============================================
  // Background Colors
  // ============================================
  static const Color background = Color(0xFFF2F2F2); // Màu nền chính
  static const Color backgroundLight = Color(0xFFFAFAFA); // Màu nền sáng
  static const Color surface = Color(0xFFFFFFFF); // Màu nền cho card/surface
  static const Color surfaceDark = Color(0xFFF5F5F5); // Màu nền tối hơn một chút

  // ============================================
  // Text Colors
  // ============================================
  static const Color textPrimary = Color(0xFF1A1A1A); // Màu chữ chính (gần đen)
  static const Color textSecondary = Color(0xFF666666); // Màu chữ phụ
  static const Color textTertiary = Color(0xFF999999); // Màu chữ mờ
  static const Color textHint = Color(0xFFB3B3B3); // Màu chữ placeholder
  static const Color textOnPrimary = Colors.white; // Màu chữ trên nền primary

  // ============================================
  // Status Colors (Màu trạng thái)
  // ============================================
  static const Color success = Color(0xFF4CAF50); // Màu thành công (xanh lá)
  static const Color error = Color(0xFFE53935); // Màu lỗi (đỏ)
  static const Color warning = Color(0xFFFF9800); // Màu cảnh báo (cam)
  static const Color info = Color(0xFF2196F3); // Màu thông tin (xanh dương)

  // ============================================
  // E-commerce Specific Colors
  // ============================================
  static const Color discount = Color(0xFFE53935); // Màu giảm giá (đỏ)
  static const Color newBadge = Color(0xFF4CAF50); // Màu badge "Mới"
  static const Color hotBadge = Color(0xFFFF5722); // Màu badge "Hot"
  static const Color outOfStock = Color(0xFF9E9E9E); // Màu hết hàng (xám)

  // ============================================
  // UI Element Colors
  // ============================================
  static const Color border = Color(0xFFE0E0E0); // Màu viền
  static const Color divider = Color(0xFFE0E0E0); // Màu đường phân cách
  static const Color shadow = Color(0x1A000000); // Màu đổ bóng (10% opacity)
  
  // ============================================
  // Rating & Review Colors
  // ============================================
  static const Color starFilled = Color(0xFFFFC107); // Màu sao đã chọn (vàng)
  static const Color starEmpty = Color(0xFFE0E0E0); // Màu sao chưa chọn (xám)

  // ============================================
  // Standard Colors (Shorthand)
  // ============================================
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;
  static const Color grey = Colors.grey;
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyDark = Color(0xFF616161);

  // ============================================
  // Helper Methods
  // ============================================
  
  /// Tạo màu với opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Lấy màu primary với opacity
  static Color primaryWithOpacity(double opacity) {
    return primary.withOpacity(opacity);
  }

  /// Lấy màu gradient cho primary (dùng cho buttons, cards)
  static List<Color> get primaryGradient => [
        primary,
        primaryDark,
      ];

  /// Lấy màu gradient cho background
  static List<Color> get backgroundGradient => [
        backgroundLight,
        background,
      ];
}

