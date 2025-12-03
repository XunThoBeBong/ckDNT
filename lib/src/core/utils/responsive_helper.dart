import 'package:flutter/material.dart';

/// ResponsiveHelper - Utility cho responsive design
///
/// CHỈ dùng khi cấu trúc layout thay đổi hoàn toàn (20% trường hợp)
/// Ví dụ: Grid sản phẩm, Navigation, Product Detail
class ResponsiveHelper {
  ResponsiveHelper._();

  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  /// Kiểm tra xem có phải mobile không (< 600px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Kiểm tra xem có phải tablet không (600px - 1024px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Kiểm tra xem có phải desktop không (>= 1024px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Lấy số cột cho grid sản phẩm
  /// Mobile: 2 cột, Tablet: 3 cột, Desktop: 4-5 cột
  static int getProductGridColumns(BuildContext context) {
    if (isMobile(context)) {
      return 2;
    } else if (isTablet(context)) {
      return 3;
    } else {
      return 4; // Desktop: 4-5 cột (có thể điều chỉnh)
    }
  }

  /// Lấy crossAxisCount cho GridView
  static int getGridCrossAxisCount(BuildContext context) {
    return getProductGridColumns(context);
  }
}
