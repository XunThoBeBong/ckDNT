import 'package:flutter/material.dart';

/// PaymentMethodModel - Model đại diện cho phương thức thanh toán
class PaymentMethodModel {
  final String id; // 'cod', 'e_wallet', 'bank_transfer', 'credit_card'
  final String name; // Tên hiển thị
  final String description; // Mô tả ngắn
  final IconData icon; // Icon cho UI

  const PaymentMethodModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  /// Lấy danh sách các phương thức thanh toán mặc định
  static List<PaymentMethodModel> getDefaultMethods() {
    return [
      const PaymentMethodModel(
        id: 'cod',
        name: 'Thanh toán khi nhận hàng',
        description: 'Thanh toán bằng tiền mặt khi nhận hàng',
        icon: Icons.money,
      ),
      const PaymentMethodModel(
        id: 'e_wallet',
        name: 'Ví MoMo',
        description: 'Thanh toán qua ứng dụng MoMo',
        icon: Icons.account_balance_wallet,
      ),
      const PaymentMethodModel(
        id: 'bank_transfer',
        name: 'Chuyển khoản ngân hàng',
        description: 'Quét QR code để chuyển khoản',
        icon: Icons.qr_code,
      ),
      const PaymentMethodModel(
        id: 'credit_card',
        name: 'Thẻ quốc tế',
        description: 'Visa, Mastercard, JCB',
        icon: Icons.credit_card,
      ),
    ];
  }

  /// Tìm phương thức thanh toán theo ID
  static PaymentMethodModel? findById(String id) {
    return getDefaultMethods().firstWhere(
      (method) => method.id == id,
      orElse: () => getDefaultMethods().first,
    );
  }
}
