import 'package:mongo_dart/mongo_dart.dart';
import 'cart_item_model.dart';

/// OrderModel - Model đại diện cho đơn hàng
///
/// Cấu trúc đầy đủ để lưu thông tin đơn hàng vào MongoDB
class OrderModel {
  // ============================================
  // IDENTIFICATION
  // ============================================
  final String? id; // MongoDB ObjectId
  final String orderNumber; // Mã đơn hàng (VD: ORD-20240101-001)

  // ============================================
  // USER & CUSTOMER INFO
  // ============================================
  final String userId; // ID của user đặt hàng (có thể rỗng nếu chưa đăng nhập)
  final String customerName; // Tên người nhận
  final String customerPhone; // Số điện thoại người nhận
  final String customerAddress; // Địa chỉ giao hàng
  final String? customerEmail; // Email người nhận (tùy chọn)

  // ============================================
  // ORDER ITEMS
  // ============================================
  final List<CartItemModel> items; // Danh sách sản phẩm trong đơn hàng

  // ============================================
  // PRICING
  // ============================================
  final double
  subtotal; // Tổng tiền sản phẩm (chưa tính phí vận chuyển, giảm giá)
  final double shippingFee; // Phí vận chuyển
  final double discount; // Giảm giá (nếu có)
  final double
  totalAmount; // Tổng tiền cuối cùng (subtotal + shippingFee - discount)

  // ============================================
  // PAYMENT & SHIPPING
  // ============================================
  final String
  paymentMethod; // Phương thức thanh toán: 'cod', 'bank_transfer', 'credit_card', 'e_wallet'
  final String
  paymentStatus; // Trạng thái thanh toán: 'pending', 'paid', 'failed', 'refunded'
  final String
  shippingMethod; // Phương thức vận chuyển: 'standard', 'express', 'same_day'
  final String? trackingNumber; // Mã vận đơn (nếu có)

  // ============================================
  // STATUS & NOTES
  // ============================================
  final String
  status; // Trạng thái đơn hàng: 'pending', 'confirmed', 'processing', 'shipping', 'delivered', 'cancelled', 'returned'
  final String? note; // Ghi chú từ khách hàng (tùy chọn)
  final String? adminNote; // Ghi chú từ admin (tùy chọn)

  // ============================================
  // DATES
  // ============================================
  final DateTime createdAt; // Ngày tạo đơn hàng
  final DateTime? confirmedAt; // Ngày xác nhận đơn hàng
  final DateTime? shippedAt; // Ngày giao hàng
  final DateTime? deliveredAt; // Ngày nhận hàng
  final DateTime? cancelledAt; // Ngày hủy đơn hàng
  final DateTime? updatedAt; // Ngày cập nhật

  OrderModel({
    this.id,
    String? orderNumber,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    this.customerEmail,
    required this.items,
    required this.subtotal,
    this.shippingFee = 0.0,
    this.discount = 0.0,
    required this.totalAmount,
    this.paymentMethod = 'cod',
    this.paymentStatus = 'pending',
    this.shippingMethod = 'standard',
    this.trackingNumber,
    this.status = 'pending',
    this.note,
    this.adminNote,
    required this.createdAt,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.updatedAt,
  }) : orderNumber = orderNumber ?? _generateOrderNumber();

  /// Tạo mã đơn hàng tự động (format: ORD-YYYYMMDD-HHMMSS)
  static String _generateOrderNumber() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'ORD-$dateStr-$timeStr';
  }

  /// Tạo OrderModel từ JSON (ví dụ dữ liệu từ MongoDB / REST API)
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Xử lý _id từ MongoDB
    String? id;
    if (json['_id'] != null) {
      if (json['_id'] is ObjectId) {
        id = (json['_id'] as ObjectId).toString();
      } else {
        id = json['_id'].toString();
      }
    } else if (json['id'] != null) {
      id = json['id'].toString();
    }

    // Xử lý items (danh sách CartItemModel)
    List<CartItemModel> items = [];
    if (json['items'] != null && json['items'] is List) {
      items = (json['items'] as List)
          .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Xử lý dates
    DateTime createdAt = DateTime.now();
    if (json['createdAt'] != null) {
      if (json['createdAt'] is DateTime) {
        createdAt = json['createdAt'] as DateTime;
      } else {
        createdAt = DateTime.parse(json['createdAt'].toString());
      }
    }

    DateTime? updatedAt;
    if (json['updatedAt'] != null) {
      if (json['updatedAt'] is DateTime) {
        updatedAt = json['updatedAt'] as DateTime;
      } else {
        updatedAt = DateTime.parse(json['updatedAt'].toString());
      }
    }

    // Xử lý các dates khác
    DateTime? confirmedAt;
    if (json['confirmedAt'] != null) {
      if (json['confirmedAt'] is DateTime) {
        confirmedAt = json['confirmedAt'] as DateTime;
      } else {
        confirmedAt = DateTime.parse(json['confirmedAt'].toString());
      }
    }

    DateTime? shippedAt;
    if (json['shippedAt'] != null) {
      if (json['shippedAt'] is DateTime) {
        shippedAt = json['shippedAt'] as DateTime;
      } else {
        shippedAt = DateTime.parse(json['shippedAt'].toString());
      }
    }

    DateTime? deliveredAt;
    if (json['deliveredAt'] != null) {
      if (json['deliveredAt'] is DateTime) {
        deliveredAt = json['deliveredAt'] as DateTime;
      } else {
        deliveredAt = DateTime.parse(json['deliveredAt'].toString());
      }
    }

    DateTime? cancelledAt;
    if (json['cancelledAt'] != null) {
      if (json['cancelledAt'] is DateTime) {
        cancelledAt = json['cancelledAt'] as DateTime;
      } else {
        cancelledAt = DateTime.parse(json['cancelledAt'].toString());
      }
    }

    return OrderModel(
      id: id,
      orderNumber: json['orderNumber']?.toString() ?? _generateOrderNumber(),
      userId: json['userId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString() ?? '',
      customerAddress: json['customerAddress']?.toString() ?? '',
      customerEmail: json['customerEmail']?.toString(),
      items: items,
      subtotal:
          (json['subtotal'] as num?)?.toDouble() ??
          (json['totalAmount'] as num?)?.toDouble() ??
          0.0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'cod',
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      shippingMethod: json['shippingMethod']?.toString() ?? 'standard',
      trackingNumber: json['trackingNumber']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      note: json['note']?.toString(),
      adminNote: json['adminNote']?.toString(),
      createdAt: createdAt,
      confirmedAt: confirmedAt,
      shippedAt: shippedAt,
      deliveredAt: deliveredAt,
      cancelledAt: cancelledAt,
      updatedAt: updatedAt,
    );
  }

  /// Convert OrderModel sang JSON để lưu DB / gửi API
  Map<String, dynamic> toJson({bool includeId = false}) {
    final json = <String, dynamic>{
      'orderNumber': orderNumber,
      'userId': userId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'discount': discount,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'shippingMethod': shippingMethod,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };

    if (customerEmail != null && customerEmail!.isNotEmpty) {
      json['customerEmail'] = customerEmail;
    }

    if (trackingNumber != null && trackingNumber!.isNotEmpty) {
      json['trackingNumber'] = trackingNumber;
    }

    if (note != null && note!.isNotEmpty) {
      json['note'] = note;
    }

    if (adminNote != null && adminNote!.isNotEmpty) {
      json['adminNote'] = adminNote;
    }

    if (confirmedAt != null) {
      json['confirmedAt'] = confirmedAt!.toIso8601String();
    }

    if (shippedAt != null) {
      json['shippedAt'] = shippedAt!.toIso8601String();
    }

    if (deliveredAt != null) {
      json['deliveredAt'] = deliveredAt!.toIso8601String();
    }

    if (cancelledAt != null) {
      json['cancelledAt'] = cancelledAt!.toIso8601String();
    }

    if (updatedAt != null) {
      json['updatedAt'] = updatedAt!.toIso8601String();
    }

    // Chỉ thêm _id nếu có và includeId = true
    if (includeId && id != null) {
      json['_id'] = ObjectId.fromHexString(id!) as dynamic;
    }

    return json;
  }

  /// Hỗ trợ copy để cập nhật một vài field
  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? userId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? customerEmail,
    List<CartItemModel>? items,
    double? subtotal,
    double? shippingFee,
    double? discount,
    double? totalAmount,
    String? paymentMethod,
    String? paymentStatus,
    String? shippingMethod,
    String? trackingNumber,
    String? status,
    String? note,
    String? adminNote,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      customerEmail: customerEmail ?? this.customerEmail,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      discount: discount ?? this.discount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      status: status ?? this.status,
      note: note ?? this.note,
      adminNote: adminNote ?? this.adminNote,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ============================================
  // GETTERS & COMPUTED PROPERTIES
  // ============================================

  /// Tổng số lượng sản phẩm trong đơn hàng
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Kiểm tra đơn hàng đã được thanh toán chưa
  bool get isPaid => paymentStatus == 'paid';

  /// Kiểm tra đơn hàng đã được giao chưa
  bool get isDelivered => status == 'delivered';

  /// Kiểm tra đơn hàng đã bị hủy chưa
  bool get isCancelled => status == 'cancelled';

  /// Kiểm tra đơn hàng có thể hủy không (chỉ hủy được khi pending hoặc confirmed)
  bool get canCancel => status == 'pending' || status == 'confirmed';

  /// Lấy tên trạng thái đơn hàng (tiếng Việt)
  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'processing':
        return 'Đang xử lý';
      case 'shipping':
        return 'Đang giao hàng';
      case 'delivered':
        return 'Đã giao hàng';
      case 'cancelled':
        return 'Đã hủy';
      case 'returned':
        return 'Đã trả hàng';
      default:
        return status;
    }
  }

  /// Lấy tên phương thức thanh toán (tiếng Việt)
  String get paymentMethodDisplayName {
    switch (paymentMethod) {
      case 'cod':
        return 'Thanh toán khi nhận hàng';
      case 'bank_transfer':
        return 'Chuyển khoản ngân hàng';
      case 'credit_card':
        return 'Thẻ tín dụng';
      case 'e_wallet':
        return 'Ví điện tử';
      default:
        return paymentMethod;
    }
  }

  /// Lấy tên phương thức vận chuyển (tiếng Việt)
  String get shippingMethodDisplayName {
    switch (shippingMethod) {
      case 'standard':
        return 'Giao hàng tiêu chuẩn';
      case 'express':
        return 'Giao hàng nhanh';
      case 'same_day':
        return 'Giao hàng trong ngày';
      default:
        return shippingMethod;
    }
  }
}
