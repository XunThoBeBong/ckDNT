import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../core/services/mongo_service.dart';
import '../../../core/injection/service_locator.dart';
import '../../../data/models/order_model.dart';
import '../../config/themes/app_colors.dart';

/// OrderHistoryScreen - Màn hình lịch sử đơn hàng
///
/// Hiển thị danh sách các đơn hàng đã mua với:
/// - Trạng thái đơn hàng (màu sắc)
/// - Simulation tự động đổi trạng thái (Chờ xác nhận -> Đang giao -> Giao thành công)
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final MongoService _mongoService = getIt<MongoService>();
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _error;
  final Map<String, Timer> _statusTimers = {}; // Map để quản lý timers

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    // Hủy tất cả timers khi dispose
    for (var timer in _statusTimers.values) {
      timer.cancel();
    }
    _statusTimers.clear();
    super.dispose();
  }

  /// Load danh sách đơn hàng từ MongoDB
  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Lấy user ID từ AuthBloc
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        setState(() {
          _isLoading = false;
          _error = 'Bạn cần đăng nhập để xem đơn hàng';
        });
        return;
      }

      final userId = authState.user.id ?? '';
      if (userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Không tìm thấy thông tin người dùng';
        });
        return;
      }

      // Lấy danh sách đơn hàng
      final orders = await _mongoService.getOrdersByUserId(
        userId,
        sortBy: 'createdAt',
        sortOrder: -1, // Mới nhất trước
      );

      setState(() {
        _orders = orders;
        _isLoading = false;
      });

      // Bắt đầu simulation cho các đơn hàng mới (status = 'pending')
      _startStatusSimulation();
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải danh sách đơn hàng: $e';
        _isLoading = false;
      });
    }
  }

  /// Bắt đầu simulation tự động đổi trạng thái đơn hàng
  void _startStatusSimulation() {
    for (var order in _orders) {
      // Chỉ simulation cho đơn hàng có status 'pending' hoặc 'confirmed'
      if (order.status == 'pending' || order.status == 'confirmed') {
        _startTimerForOrder(order);
      }
    }
  }

  /// Tạo timer để tự động đổi trạng thái cho một đơn hàng
  void _startTimerForOrder(OrderModel order) {
    // Hủy timer cũ nếu có
    _statusTimers[order.id ?? '']?.cancel();

    // Tính toán thời gian còn lại dựa trên createdAt
    final now = DateTime.now();
    final elapsed = now.difference(order.createdAt);

    // Simulation timeline:
    // - Sau 10 giây: pending -> confirmed (Đang giao hàng)
    // - Sau 20 giây: confirmed -> shipping (Đang giao hàng)
    // - Sau 30 giây: shipping -> delivered (Giao thành công)

    Timer? timer;

    if (order.status == 'pending') {
      // Chuyển sang 'confirmed' sau 10 giây (tính từ khi tạo đơn)
      final delay1 = Duration(seconds: 10) - elapsed;
      if (delay1.isNegative) {
        // Đã quá 10 giây, chuyển luôn sang confirmed
        _updateOrderStatus(order, 'confirmed');
        // Tiếp tục với confirmed -> shipping
        final delay2 = Duration(seconds: 20) - elapsed;
        if (delay2.isNegative) {
          _updateOrderStatus(order, 'shipping');
          // Tiếp tục với shipping -> delivered
          final delay3 = Duration(seconds: 30) - elapsed;
          if (delay3.isNegative) {
            _updateOrderStatus(order, 'delivered');
          } else {
            timer = Timer(delay3, () {
              _updateOrderStatus(order, 'delivered');
            });
          }
        } else {
          timer = Timer(delay2, () {
            _updateOrderStatus(order, 'shipping');
            // Sau khi shipping, chờ thêm 10 giây để delivered
            Timer(const Duration(seconds: 10), () {
              _updateOrderStatus(order, 'delivered');
            });
          });
        }
      } else {
        timer = Timer(delay1, () {
          _updateOrderStatus(order, 'confirmed');
          // Sau 10 giây nữa, chuyển sang shipping
          Timer(const Duration(seconds: 10), () {
            _updateOrderStatus(order, 'shipping');
            // Sau 10 giây nữa, chuyển sang delivered
            Timer(const Duration(seconds: 10), () {
              _updateOrderStatus(order, 'delivered');
            });
          });
        });
      }
    } else if (order.status == 'confirmed') {
      // Chuyển sang 'shipping' sau 10 giây
      final delay = Duration(seconds: 20) - elapsed;
      if (delay.isNegative) {
        _updateOrderStatus(order, 'shipping');
        Timer(const Duration(seconds: 10), () {
          _updateOrderStatus(order, 'delivered');
        });
      } else {
        timer = Timer(delay, () {
          _updateOrderStatus(order, 'shipping');
          Timer(const Duration(seconds: 10), () {
            _updateOrderStatus(order, 'delivered');
          });
        });
      }
    } else if (order.status == 'shipping') {
      // Chuyển sang 'delivered' sau 10 giây
      final delay = Duration(seconds: 30) - elapsed;
      if (delay.isNegative) {
        _updateOrderStatus(order, 'delivered');
      } else {
        timer = Timer(delay, () {
          _updateOrderStatus(order, 'delivered');
        });
      }
    }

    if (timer != null) {
      _statusTimers[order.id ?? ''] = timer;
    }
  }

  /// Cập nhật trạng thái đơn hàng (chỉ trong UI, không lưu DB)
  void _updateOrderStatus(OrderModel order, String newStatus) {
    setState(() {
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _orders[index] = order.copyWith(status: newStatus);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrders,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có đơn hàng nào',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy mua sắm để xem đơn hàng ở đây',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Mua sắm ngay'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(_orders[index]);
        },
      ),
    );
  }

  /// Widget hiển thị một đơn hàng
  Widget _buildOrderCard(OrderModel order) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Mã đơn và trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã đơn: ${order.orderNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const Divider(height: 24),
            // Thông tin sản phẩm
            Text(
              '${order.totalItems} sản phẩm',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            // Danh sách sản phẩm (hiển thị tối đa 3 sản phẩm)
            ...order.items.take(3).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.product.name} x${item.quantity}',
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      currencyFormat.format(item.totalPrice),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (order.items.length > 3)
              Text(
                '... và ${order.items.length - 3} sản phẩm khác',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            const Divider(height: 24),
            // Tổng tiền
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng tiền:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormat.format(order.totalAmount),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Nút xem chi tiết
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Navigate to order detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Chi tiết đơn hàng ${order.orderNumber}'),
                    ),
                  );
                },
                child: const Text('Xem chi tiết'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget hiển thị badge trạng thái đơn hàng với màu sắc
  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;
    IconData icon;

    switch (status) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        displayText = 'Chờ xác nhận';
        icon = Icons.access_time;
        break;
      case 'confirmed':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        displayText = 'Đã xác nhận';
        icon = Icons.check_circle_outline;
        break;
      case 'shipping':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        displayText = 'Đang giao hàng';
        icon = Icons.local_shipping;
        break;
      case 'delivered':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        displayText = 'Giao thành công';
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        displayText = 'Đã hủy';
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        displayText = status;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
