import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../logic/cart/cart_bloc.dart';
import '../../../logic/cart/cart_event.dart';
import '../../../logic/cart/cart_state.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../core/utils/validators.dart';
import '../../../core/services/mongo_service.dart';
import '../../../core/services/product_refresh_service.dart';
import '../../../core/injection/service_locator.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/shipping_method_model.dart';
import '../../../data/models/payment_method_model.dart';
import '../../config/themes/app_colors.dart';
import '../../widgets/inputs/custom_text_field.dart';

/// CheckoutScreen - Màn hình thanh toán
///
/// Form nhập thông tin giao hàng: Tên, SĐT, Địa chỉ
/// Hiển thị thông tin giỏ hàng và tổng tiền
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _distanceController = TextEditingController(
    text: '10',
  ); // Khoảng cách mặc định 10km

  // Shipping method
  ShippingMethodModel? _selectedShippingMethod;
  final List<ShippingMethodModel> _shippingMethods =
      ShippingMethodModel.getDefaultMethods();
  double _shippingFee = 0.0;

  // Payment method
  PaymentMethodModel? _selectedPaymentMethod;
  final List<PaymentMethodModel> _paymentMethods =
      PaymentMethodModel.getDefaultMethods();

  @override
  void initState() {
    super.initState();
    // Load giỏ hàng khi màn hình được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartBloc>().add(const LoadCartEvent());
    });
    // Tự động điền thông tin nếu user đã đăng nhập
    _loadUserInfo();
  }

  void _loadUserInfo() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _nameController.text = user.fullName;
      _addressController.text = user.address;
      if (user.phone != null && user.phone!.isNotEmpty) {
        _phoneController.text = user.phone!;
      }
    }
    // Mặc định chọn phương thức vận chuyển đầu tiên
    _selectedShippingMethod = _shippingMethods.first;
    _calculateShippingFee();
    // Mặc định chọn phương thức thanh toán đầu tiên (COD)
    _selectedPaymentMethod = _paymentMethods.first;
  }

  void _calculateShippingFee() {
    if (_selectedShippingMethod == null) return;
    final distance = double.tryParse(_distanceController.text) ?? 10.0;
    setState(() {
      _shippingFee = _selectedShippingMethod!.calculateShippingFee(distance);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Lấy thông tin giỏ hàng
    final cartState = context.read<CartBloc>().state;
    if (cartState is! CartLoaded || cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giỏ hàng trống. Vui lòng thêm sản phẩm vào giỏ hàng.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Lấy userId từ AuthBloc (nếu đã đăng nhập)
    String userId = '';
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      userId = authState.user.id ?? '';
    }

    // Tạo OrderModel
    final order = OrderModel(
      userId: userId,
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      customerAddress: _addressController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      items: cartState.items
          .where((item) => item.isSelected)
          .toList(), // Chỉ lấy items được chọn
      subtotal: cartState.totalPrice, // Tổng tiền sản phẩm
      shippingFee: _shippingFee, // Phí vận chuyển đã tính
      discount: 0.0, // Giảm giá (nếu có)
      totalAmount:
          cartState.totalPrice +
          _shippingFee, // Tổng tiền cuối cùng (subtotal + shipping)
      paymentMethod: _selectedPaymentMethod?.id ?? 'cod',
      paymentStatus: 'pending',
      shippingMethod:
          _selectedShippingMethod?.id ??
          'basic', // Phương thức vận chuyển đã chọn
      status: 'pending',
      createdAt: DateTime.now(),
    );

    // Hiển thị loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Gọi MongoService để tạo đơn hàng với kiểm tra tồn kho
      print("🛒 [CHECKOUT] Bắt đầu gọi createOrderWithStockCheck...");
      final mongoService = getIt<MongoService>();
      final result = await mongoService.createOrderWithStockCheck(order);
      print(
        "🛒 [CHECKOUT] Kết quả từ createOrderWithStockCheck: orderId=${result['orderId']}, error=${result['error']}",
      );

      // Đóng loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      final orderId = result['orderId'] as String?;
      final error = result['error'] as String?;

      if (orderId != null) {
        // Đặt hàng thành công
        // Xóa giỏ hàng sau khi đặt hàng thành công
        if (context.mounted) {
          context.read<CartBloc>().add(const ClearCartEvent());
        }

        // Notify refresh products để cập nhật stock trong UI
        ProductRefreshService().notifyRefresh();

        // Kiểm tra payment method để điều hướng
        final paymentMethod = _selectedPaymentMethod?.id ?? 'cod';

        if (context.mounted) {
          if (paymentMethod == 'cod') {
            // COD: Chuyển thẳng sang trang cảm ơn
            context.pushReplacement(
              '/thank-you',
              extra: {
                'orderNumber': order.orderNumber,
                'totalAmount': order.totalAmount,
              },
            );
          } else {
            // Các phương thức khác: Chuyển sang trang thanh toán
            switch (paymentMethod) {
              case 'bank_transfer':
                context.pushReplacement(
                  '/payment/qr-code',
                  extra: {
                    'orderTotal': order.totalAmount,
                    'orderNumber': order.orderNumber,
                    'orderId': orderId,
                  },
                );
                break;
              case 'credit_card':
                context.pushReplacement(
                  '/payment/credit-card',
                  extra: {
                    'orderTotal': order.totalAmount,
                    'orderNumber': order.orderNumber,
                    'orderId': orderId,
                  },
                );
                break;
              case 'e_wallet':
                context.pushReplacement(
                  '/payment/momo',
                  extra: {
                    'orderTotal': order.totalAmount,
                    'orderNumber': order.orderNumber,
                    'orderId': orderId,
                  },
                );
                break;
            }
          }
        }
      } else {
        // Đặt hàng thất bại - Hiển thị lỗi rõ ràng
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Không thể đặt hàng. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Đóng loading dialog nếu có lỗi
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Hiển thị lỗi
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi đặt hàng: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          if (cartState is CartLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartState is CartError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    cartState.message,
                    style: TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Quay lại'),
                  ),
                ],
              ),
            );
          }

          if (cartState is CartLoaded) {
            // Kiểm tra xem có sản phẩm nào được chọn không
            final selectedItems = cartState.items
                .where((item) => item.isSelected)
                .toList();
            if (selectedItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 100,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có sản phẩm nào được chọn',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hãy thêm sản phẩm vào giỏ hàng',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Quay lại giỏ hàng'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thông tin giao hàng
                  _buildShippingInfoSection(),
                  const SizedBox(height: 24),
                  // Phương thức thanh toán
                  _buildPaymentMethodSection(),
                  const SizedBox(height: 24),
                  // Tóm tắt đơn hàng
                  _buildOrderSummarySection(cartState),
                  const SizedBox(height: 24),
                  // Nút đặt hàng
                  _buildPlaceOrderButton(),
                ],
              ),
            );
          }

          return const Center(child: Text('Không có dữ liệu'));
        },
      ),
    );
  }

  /// Section thông tin giao hàng
  Widget _buildShippingInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Thông tin giao hàng',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Tên người nhận
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Họ và tên người nhận',
                    hintText: 'Nhập họ và tên',
                    prefixIcon: Icons.person_outlined,
                    textInputAction: TextInputAction.next,
                    validator: validateFullName,
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),
                  // Số điện thoại
                  CustomTextField(
                    controller: _phoneController,
                    labelText: 'Số điện thoại',
                    hintText: 'Nhập số điện thoại',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: validatePhone,
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),
                  // Địa chỉ
                  CustomTextField(
                    controller: _addressController,
                    labelText: 'Địa chỉ giao hàng',
                    hintText:
                        'Nhập địa chỉ chi tiết (số nhà, tên đường, phường/xã, quận/huyện, tỉnh/thành phố)',
                    prefixIcon: Icons.location_on_outlined,
                    keyboardType: TextInputType.streetAddress,
                    maxLines: 3,
                    textInputAction: TextInputAction.next,
                    validator: validateAddress,
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),
                  // Phương thức vận chuyển
                  _buildShippingMethodDropdown(),
                  const SizedBox(height: 16),
                  // Khoảng cách (ẩn, chỉ dùng để tính phí)
                  // Có thể mở rộng sau để tính từ địa chỉ
                  // CustomTextField(
                  //   controller: _distanceController,
                  //   labelText: 'Khoảng cách (km)',
                  //   hintText: 'Nhập khoảng cách',
                  //   prefixIcon: Icons.straighten_outlined,
                  //   keyboardType: TextInputType.number,
                  //   onChanged: (_) => _calculateShippingFee(),
                  // ),
                  // Ghi chú (tùy chọn)
                  CustomTextField(
                    controller: _noteController,
                    labelText: 'Ghi chú (tùy chọn)',
                    hintText: 'Ghi chú thêm cho đơn hàng',
                    prefixIcon: Icons.note_outlined,
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget dropdown chọn phương thức vận chuyển
  Widget _buildShippingMethodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_shipping, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Phương thức vận chuyển *',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonFormField<ShippingMethodModel>(
            value: _selectedShippingMethod,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.local_shipping_outlined),
            ),
            selectedItemBuilder: (BuildContext context) {
              return _shippingMethods.map((method) {
                return Row(
                  children: [
                    Text(
                      method.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        method.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList();
            },
            menuMaxHeight: 300,
            items: _shippingMethods.map((method) {
              return DropdownMenuItem<ShippingMethodModel>(
                value: method,
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            method.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              method.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(method.pricePerKm)}/km',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (ShippingMethodModel? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedShippingMethod = newValue;
                  _calculateShippingFee();
                });
              }
            },
            validator: (value) {
              if (value == null) {
                return 'Vui lòng chọn phương thức vận chuyển';
              }
              return null;
            },
          ),
        ),
        if (_shippingFee > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Phí vận chuyển (${_distanceController.text}km):',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: '₫',
                    decimalDigits: 0,
                  ).format(_shippingFee),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Section chọn phương thức thanh toán
  Widget _buildPaymentMethodSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Phương thức thanh toán',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Button để mở dialog chọn payment method
            InkWell(
              onTap: () => _showPaymentMethodDialog(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedPaymentMethod?.icon ?? Icons.payment_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPaymentMethod?.name ??
                                'Chọn phương thức thanh toán',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_selectedPaymentMethod != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _selectedPaymentMethod!.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hiển thị dialog chọn phương thức thanh toán
  Future<void> _showPaymentMethodDialog() async {
    final selectedMethod = await showDialog<PaymentMethodModel>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chọn phương thức thanh toán',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _paymentMethods.length,
                    itemBuilder: (context, index) {
                      final method = _paymentMethods[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(method),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  method.icon,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        method.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        method.description,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedMethod != null) {
      setState(() {
        _selectedPaymentMethod = selectedMethod;
      });
      // Chỉ lưu selection, không tự động chuyển trang
    }
  }

  /// Lấy tổng tiền đơn hàng
  double _getOrderTotal() {
    final cartState = context.read<CartBloc>().state;
    if (cartState is CartLoaded) {
      return cartState.totalPrice + _shippingFee;
    }
    return 0.0;
  }

  /// Tạo mã đơn hàng tạm thời (sẽ được tạo lại khi đặt hàng)
  String _generateOrderNumber() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'ORD-$dateStr-$timeStr';
  }

  /// Section tóm tắt đơn hàng
  Widget _buildOrderSummarySection(CartLoaded cartState) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Tóm tắt đơn hàng',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Danh sách sản phẩm (chỉ hiển thị các sản phẩm đã được chọn)
            ...cartState.items
                .where((item) => item.isSelected)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tên sản phẩm và số lượng
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Số lượng: ${item.quantity}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Giá
                        Text(
                          currencyFormat.format(
                            item.product.discountedPrice * item.quantity,
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const Divider(height: 24),
            // Tổng tiền sản phẩm
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng tiền sản phẩm:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  currencyFormat.format(cartState.totalPrice),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Phí vận chuyển
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Phí vận chuyển:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  currencyFormat.format(_shippingFee),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Divider(height: 24),
            // Tổng cộng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng cộng:',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormat.format(cartState.totalPrice + _shippingFee),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Nút đặt hàng
  Widget _buildPlaceOrderButton() {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final isLoading = state is CartLoading;
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handlePlaceOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white,
                      ),
                    ),
                  )
                : const Text(
                    'Đặt hàng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        );
      },
    );
  }
}
