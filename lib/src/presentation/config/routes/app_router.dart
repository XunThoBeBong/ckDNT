import 'package:go_router/go_router.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/checkout/checkout_screen.dart';
import '../../screens/product_detail/product_detail_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/payment/qr_code_screen.dart';
import '../../screens/payment/credit_card_screen.dart';
import '../../screens/payment/momo_screen.dart';
import '../../screens/checkout/thank_you_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/orders/order_history_screen.dart';
import '../../../data/models/product_model.dart';

class AppRouter {
  static final router = GoRouter(
    // 1. SỬA DÒNG NÀY: Đổi từ '/' thành '/login'
    initialLocation: '/login',

    routes: [
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),

      // 2. THÊM ROUTE NÀY: Để xem chi tiết sản phẩm
      GoRoute(
        path: '/product-detail',
        builder: (context, state) {
          // Lấy object product được truyền từ màn hình Home
          final product = state.extra as ProductModel;
          return ProductDetailScreen(product: product);
        },
      ),
      // 3. Route cho Profile Screen
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      // 4. Routes cho Payment Screens
      GoRoute(
        path: '/payment/qr-code',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return QRCodeScreen(
            orderTotal: data['orderTotal'] as double,
            orderNumber: data['orderNumber'] as String,
            orderId: data['orderId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/payment/credit-card',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return CreditCardScreen(
            orderTotal: data['orderTotal'] as double,
            orderNumber: data['orderNumber'] as String,
            orderId: data['orderId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/payment/momo',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return MoMoScreen(
            orderTotal: data['orderTotal'] as double,
            orderNumber: data['orderNumber'] as String,
            orderId: data['orderId'] as String?,
          );
        },
      ),
      // 5. Route cho Thank You Screen
      GoRoute(
        path: '/thank-you',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return ThankYouScreen(
            orderNumber: data['orderNumber'] as String,
            totalAmount: data['totalAmount'] as double,
          );
        },
      ),
      // 6. Route cho Search Screen
      GoRoute(
        path: '/search',
        builder: (context, state) {
          // Lấy query từ URL parameters
          final query = state.uri.queryParameters['query'] ?? '';
          return SearchScreen(initialQuery: query);
        },
      ),
      // 7. Route cho Order History Screen
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
    ],
  );
}
