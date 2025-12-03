import 'package:mongo_dart/mongo_dart.dart';

class UserModel {
  final String? id;
  final String email;
  final String password;
  final String fullName;
  final String address;
  final String? phone; // ✅ Thêm trường này cho E-commerce
  final String? avatarUrl; // ✅ URL ảnh avatar trên Cloudinary
  final String role; // ✅ Role của user: 'admin' hoặc 'user'

  const UserModel({
    this.id,
    required this.email,
    required this.password,
    required this.fullName,
    required this.address,
    this.phone,
    this.avatarUrl,
    this.role = 'user', // Mặc định là 'user' nếu không có
  });

  /// Tạo UserModel từ JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Xử lý _id cực chuẩn (giữ nguyên logic tốt của bạn)
    String? id;
    if (json['_id'] != null) {
      if (json['_id'] is ObjectId) {
        id = (json['_id'] as ObjectId)
            .toHexString(); // Dùng toHexString() chuẩn hơn toString()
      } else {
        id = json['_id'].toString();
      }
    } else if (json['id'] != null) {
      id = json['id'].toString();
    }

    return UserModel(
      id: id,
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'No Name',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString(), // ✅ Parse SĐT
      avatarUrl: json['avatarUrl']?.toString(), // ✅ Parse avatarUrl
      role:
          json['role']?.toString() ??
          'user', // ✅ Lấy role từ Mongo, mặc định 'user'
    );
  }

  /// Convert sang JSON
  Map<String, dynamic> toJson({bool includeId = false}) {
    final json = <String, dynamic>{
      'email': email,
      'password': password,
      'fullName': fullName,
      'address': address,
      if (phone != null) 'phone': phone, // ✅ Lưu SĐT
      if (avatarUrl != null) 'avatarUrl': avatarUrl, // ✅ Lưu avatarUrl
      'role': role, // ✅ Lưu role
    };

    // Fix lỗi crash nếu ID không chuẩn format MongoDB
    if (includeId && id != null && id!.isNotEmpty) {
      try {
        json['_id'] = ObjectId.fromHexString(id!);
      } catch (e) {
        // Nếu id không đúng chuẩn HexString thì bỏ qua, không gửi _id lên
        // (MongoDB sẽ tự tạo id mới nếu thiếu)
      }
    }

    return json;
  }

  /// CopyWith (Giữ nguyên, thêm phone và role)
  UserModel copyWith({
    String? id,
    String? email,
    String? password,
    String? fullName,
    String? address,
    String? phone,
    String? avatarUrl,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
    );
  }

  /// Helper check admin
  bool get isAdmin => role == 'admin';
}
