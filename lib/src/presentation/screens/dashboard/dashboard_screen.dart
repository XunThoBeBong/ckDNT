import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../logic/cart/cart_bloc.dart';
import '../../../logic/cart/cart_state.dart';
import '../home/home_screen.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';

/// DashboardScreen - Màn hình chính chứa Navigation
///
/// Quản lý việc chuyển đổi giữa các tab: Home, Cart, Profile
///
/// TRƯỜNG HỢP CẦN ResponsiveBuilder: Cấu trúc navigation thay đổi hoàn toàn
/// - Mobile: BottomNavigationBar (thanh tab ở dưới)
/// - Desktop: NavigationRail (thanh menu bên trái)
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ============================================
  // Constants
  // ============================================
  static const int _homeIndex = 0;
  static const int _cartIndex = 1;
  static const int _profileIndex = 2;

  // ============================================
  // State Variables
  // ============================================
  int _currentIndex = _homeIndex;

  // ============================================
  // Pages List
  // ============================================
  /// Danh sách các màn hình con
  /// Sử dụng IndexedStack để giữ trạng thái khi chuyển tab
  late final List<Widget> _pages = [
    const HomeScreen(), // Tab 0: Trang chủ
    const CartScreen(), // Tab 1: Giỏ hàng
    const ProfileScreen(), // Tab 2: Tài khoản
  ];

  // ============================================
  // Build Method
  // ============================================
  @override
  Widget build(BuildContext context) {
    // TRƯỜNG HỢP CẦN ResponsiveBuilder: Cấu trúc navigation thay đổi
    if (ResponsiveHelper.isMobile(context)) {
      // Mobile: BottomNavigationBar
      return Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: _buildBottomNavigationBar(),
      );
    } else {
      // Desktop/Tablet: NavigationRail
      return Scaffold(
        body: Row(
          children: [
            _buildNavigationRail(),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _pages),
            ),
          ],
        ),
      );
    }
  }

  // ============================================
  // Navigation - Mobile: BottomNavigationBar
  // ============================================
  /// Xây dựng Bottom Navigation Bar với theme và icons (Mobile)
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTabTapped,
      type: BottomNavigationBarType.fixed, // Fixed để hiển thị tất cả labels
      elevation: 8,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Trang chủ',
          tooltip: 'Trang chủ',
        ),
        // Giỏ hàng với badge hiển thị số lượng
        BottomNavigationBarItem(
          icon: _buildCartIconWithBadge(),
          activeIcon: _buildCartIconWithBadge(isActive: true),
          label: 'Giỏ hàng',
          tooltip: 'Giỏ hàng',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Tài khoản',
          tooltip: 'Tài khoản',
        ),
      ],
    );
  }

  // ============================================
  // Navigation - Desktop: NavigationRail
  // ============================================
  /// Xây dựng Navigation Rail (Desktop/Tablet)
  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: _onTabTapped,
      labelType: NavigationRailLabelType.all,
      destinations: [
        const NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Trang chủ'),
        ),
        // Giỏ hàng với badge hiển thị số lượng
        NavigationRailDestination(
          icon: _buildCartIconWithBadge(),
          selectedIcon: _buildCartIconWithBadge(isActive: true),
          label: const Text('Giỏ hàng'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Tài khoản'),
        ),
      ],
    );
  }

  // ============================================
  // Event Handlers
  // ============================================
  /// Xử lý khi người dùng tap vào tab
  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // Nếu tap vào tab đang active, có thể scroll to top hoặc refresh
      _handleTabReselected(index);
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  /// Xử lý khi tap vào tab đang active
  /// Có thể dùng để scroll to top hoặc refresh màn hình
  void _handleTabReselected(int index) {
    // TODO: Implement scroll to top hoặc refresh logic
    // Ví dụ: ScrollController của HomeScreen scroll to top
    switch (index) {
      case _homeIndex:
        // Scroll to top của HomeScreen
        break;
      case _cartIndex:
        // Refresh CartScreen
        break;
      case _profileIndex:
        // Refresh ProfileScreen
        break;
    }
  }

  // ============================================
  // Helper Methods - Badge cho icon giỏ hàng
  // ============================================
  /// Xây dựng icon giỏ hàng với badge hiển thị số lượng
  Widget _buildCartIconWithBadge({bool isActive = false}) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        int itemCount = 0;
        if (state is CartLoaded) {
          itemCount = state.itemCount;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(isActive ? Icons.shopping_cart : Icons.shopping_cart_outlined),
            if (itemCount > 0)
              Positioned(
                right: -8,
                top: -8,
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
    );
  }
}
