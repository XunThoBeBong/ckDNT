import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../../core/services/mongo_service.dart';
import '../../core/injection/service_locator.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

/// MongoAuthRepository - Implement AuthRepository sử dụng MongoDB
///
/// Lưu trữ user trong collection "users" trên MongoDB Atlas
/// Password được hash bằng SHA-256 trước khi lưu vào database
class MongoAuthRepository implements AuthRepository {
  final MongoService _mongoService;
  final String _collectionName = 'users';

  MongoAuthRepository({MongoService? mongoService})
    : _mongoService = mongoService ?? getIt<MongoService>();

  /// Hash password bằng SHA-256
  ///
  /// ⚠️ LƯU Ý: SHA-256 không phải là cách tốt nhất để hash password.
  /// Nên dùng bcrypt hoặc argon2 trong production, nhưng để đơn giản
  /// cho demo, tôi dùng SHA-256.
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// So sánh password với hash đã lưu
  bool _verifyPassword(String password, String hashedPassword) {
    return _hashPassword(password) == hashedPassword;
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      // Đảm bảo đã kết nối MongoDB
      if (!_mongoService.isConnected) {
        await _mongoService.connect();
      }

      // Tìm user theo email
      final users = await _mongoService.find(_collectionName, {
        'email': email,
      }, limit: 1);

      if (users.isEmpty) {
        throw Exception('Email hoặc mật khẩu không đúng');
      }

      final userData = users.first;
      final storedPasswordHash = userData['password']?.toString() ?? '';

      // So sánh password đã hash
      if (!_verifyPassword(password, storedPasswordHash)) {
        throw Exception('Email hoặc mật khẩu không đúng');
      }

      // Tạo UserModel từ dữ liệu MongoDB
      final user = UserModel.fromJson(userData);
      return user;
    } catch (e) {
      // Nếu là Exception từ code trên, throw lại
      if (e is Exception) {
        rethrow;
      }
      // Nếu là lỗi khác (network, database, etc.), wrap trong Exception
      throw Exception('Lỗi đăng nhập: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String address,
  }) async {
    try {
      print("🔵 [REGISTER] Bắt đầu đăng ký với email: $email");

      // Đảm bảo đã kết nối MongoDB
      print("🔵 [REGISTER] Kiểm tra kết nối MongoDB...");
      if (!_mongoService.isConnected) {
        print("⚠️ [REGISTER] Chưa kết nối, đang thử kết nối...");
        await _mongoService.connect();
      }

      if (!_mongoService.isConnected) {
        throw Exception(
          'Không thể kết nối đến database. Vui lòng kiểm tra kết nối mạng.',
        );
      }
      print("✅ [REGISTER] Đã kết nối MongoDB");

      // Kiểm tra email đã tồn tại chưa
      print("🔵 [REGISTER] Kiểm tra email đã tồn tại...");
      final existingUsers = await _mongoService.find(_collectionName, {
        'email': email,
      }, limit: 1);

      if (existingUsers.isNotEmpty) {
        print("❌ [REGISTER] Email đã tồn tại");
        throw Exception('Email này đã được sử dụng');
      }
      print("✅ [REGISTER] Email chưa tồn tại, có thể đăng ký");

      // Hash password trước khi lưu
      print("🔵 [REGISTER] Đang hash password...");
      final hashedPassword = _hashPassword(password);
      print("✅ [REGISTER] Đã hash password");

      // Tạo user mới
      final userData = {
        'email': email,
        'password': hashedPassword, // Lưu password đã hash
        'fullName': fullName,
        'address': address,
        'createdAt': DateTime.now().toIso8601String(),
      };
      print("🔵 [REGISTER] Dữ liệu user: $userData");

      // Insert vào MongoDB
      print("🔵 [REGISTER] Đang insert vào collection: $_collectionName");
      final userId = await _mongoService.insert(_collectionName, userData);
      print("🔵 [REGISTER] Kết quả insert - userId: $userId");

      if (userId == null) {
        print("❌ [REGISTER] Insert trả về null!");
        throw Exception('Không thể tạo tài khoản. Vui lòng thử lại.');
      }
      print("✅ [REGISTER] Insert thành công với ID: $userId");

      // Lấy lại user vừa tạo để trả về (query bằng email vì đã biết email là unique)
      print("🔵 [REGISTER] Đang query lại user vừa tạo...");
      final newUserData = await _mongoService.find(_collectionName, {
        'email': email,
      }, limit: 1);

      if (newUserData.isEmpty) {
        print("❌ [REGISTER] Không tìm thấy user sau khi insert!");
        throw Exception('Đã tạo tài khoản nhưng không thể lấy thông tin');
      }
      print("✅ [REGISTER] Đã tìm thấy user: ${newUserData.first}");

      print("🔵 [REGISTER] Đang parse UserModel...");
      final user = UserModel.fromJson(newUserData.first);
      print("✅ [REGISTER] Đăng ký thành công!");
      return user;
    } catch (e, stackTrace) {
      print("❌❌❌ [REGISTER] LỖI ĐĂNG KÝ ❌❌❌");
      print("Error: $e");
      print("Stack trace: $stackTrace");

      // Nếu là Exception từ code trên, throw lại
      if (e is Exception) {
        rethrow;
      }
      // Nếu là lỗi khác, wrap trong Exception
      throw Exception('Lỗi đăng ký: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    // Với MongoDB, logout chỉ là xóa session/token ở client
    // Không cần thao tác gì với database
    // Nếu sau này có session management, có thể xóa session ở đây
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    // Với MongoDB, không có session tự động
    // Cần lưu userId/token ở client (SharedPreferences/FlutterSecureStorage)
    // và query lại từ DB khi cần
    //
    // Hiện tại trả về null, sau này có thể:
    // 1. Lưu userId trong SharedPreferences sau khi login
    // 2. Query lại user từ DB dựa trên userId đó
    // 3. Hoặc dùng JWT token và decode để lấy userId

    // TODO: Implement session management với SharedPreferences
    return null;
  }

  @override
  Future<UserModel> updateAvatar({
    required String userId,
    required String avatarUrl,
  }) async {
    try {
      print("🔵 [UPDATE_AVATAR] Bắt đầu cập nhật avatar...");

      // Đảm bảo đã kết nối MongoDB
      if (!_mongoService.isConnected) {
        await _mongoService.connect();
      }

      if (!_mongoService.isConnected) {
        throw Exception('Không thể kết nối đến database');
      }

      // Cập nhật avatarUrl trong database
      final updated = await _mongoService.update(
        _collectionName,
        {'_id': ObjectId.fromHexString(userId)},
        {'avatarUrl': avatarUrl},
      );

      if (!updated) {
        throw Exception('Không thể cập nhật avatar');
      }

      // Lấy lại user đã cập nhật
      final userData = await _mongoService.find(_collectionName, {
        '_id': ObjectId.fromHexString(userId),
      }, limit: 1);

      if (userData.isEmpty) {
        throw Exception('Không tìm thấy user sau khi cập nhật');
      }

      print("✅ [UPDATE_AVATAR] Cập nhật avatar thành công");
      return UserModel.fromJson(userData.first);
    } catch (e, stackTrace) {
      print("❌❌❌ [UPDATE_AVATAR] LỖI ❌❌❌");
      print("Error: $e");
      print("Stack trace: $stackTrace");

      if (e is Exception) {
        rethrow;
      }
      throw Exception('Lỗi cập nhật avatar: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateUserInfo({
    required String userId,
    required String fullName,
    required String address,
    String? phone,
  }) async {
    try {
      print("🔵 [UPDATE_USER_INFO] Bắt đầu cập nhật thông tin...");

      // Đảm bảo đã kết nối MongoDB
      if (!_mongoService.isConnected) {
        await _mongoService.connect();
      }

      if (!_mongoService.isConnected) {
        throw Exception('Không thể kết nối đến database');
      }

      // Tạo update data
      final updateData = <String, dynamic>{
        'fullName': fullName,
        'address': address,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Thêm phone nếu có
      if (phone != null && phone.isNotEmpty) {
        updateData['phone'] = phone;
      }

      // Cập nhật thông tin trong database
      final updated = await _mongoService.update(_collectionName, {
        '_id': ObjectId.fromHexString(userId),
      }, updateData);

      if (!updated) {
        throw Exception('Không thể cập nhật thông tin');
      }

      // Lấy lại user đã cập nhật
      final userData = await _mongoService.find(_collectionName, {
        '_id': ObjectId.fromHexString(userId),
      }, limit: 1);

      if (userData.isEmpty) {
        throw Exception('Không tìm thấy user sau khi cập nhật');
      }

      print("✅ [UPDATE_USER_INFO] Cập nhật thông tin thành công");
      return UserModel.fromJson(userData.first);
    } catch (e, stackTrace) {
      print("❌❌❌ [UPDATE_USER_INFO] LỖI ❌❌❌");
      print("Error: $e");
      print("Stack trace: $stackTrace");

      if (e is Exception) {
        rethrow;
      }
      throw Exception('Lỗi cập nhật thông tin: ${e.toString()}');
    }
  }
}
