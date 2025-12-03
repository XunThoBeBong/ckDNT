import '../../data/models/user_model.dart';

/// AuthRepository - Interface trừu tượng cho logic đăng nhập/đăng ký
///
/// Hiện tại demo dùng InMemoryAuthRepository (lưu tạm trong RAM),
/// sau này bạn có thể:
/// - Implement class khác dùng REST API / MongoDB
/// - Đăng ký qua get_it và inject vào AuthBloc.
abstract class AuthRepository {
  /// Đăng nhập, throw Exception nếu sai email/password
  Future<UserModel> login({required String email, required String password});

  /// Đăng ký tài khoản mới, trả về UserModel đã tạo
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String address,
  });

  /// Đăng xuất
  Future<void> logout();

  /// Lấy user hiện tại (nếu đã đăng nhập), ngược lại trả về null
  Future<UserModel?> getCurrentUser();

  /// Cập nhật avatar của user
  Future<UserModel> updateAvatar({
    required String userId,
    required String avatarUrl,
  });

  /// Cập nhật thông tin cá nhân của user
  Future<UserModel> updateUserInfo({
    required String userId,
    required String fullName,
    required String address,
    String? phone,
  });
}

/// Implement demo: lưu user trong bộ nhớ (RAM) để tập trung vào logic Bloc.
class InMemoryAuthRepository implements AuthRepository {
  UserModel? _currentUser;

  // Demo: một tài khoản mặc định
  final _demoUser = UserModel(
    email: 'demo@example.com',
    password: '123456',
    fullName: 'Demo User',
    address: 'Hà Nội',
  );

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // Giả lập call API
    await Future.delayed(const Duration(milliseconds: 500));

    // Logic demo:
    // - Nếu email/password khớp với demoUser -> đăng nhập ok
    // - Nếu _currentUser đã đăng ký trước đó -> check theo _currentUser
    final userToCheck = _currentUser ?? _demoUser;

    if (email == userToCheck.email && password == userToCheck.password) {
      _currentUser = userToCheck;
      return _currentUser!;
    }

    throw Exception('Email hoặc mật khẩu không đúng');
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String address,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Demo: không check trùng email, chỉ tạo user mới trong RAM
    _currentUser = UserModel(
      email: email,
      password: password,
      fullName: fullName,
      address: address,
    );
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _currentUser;
  }

  @override
  Future<UserModel> updateAvatar({
    required String userId,
    required String avatarUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_currentUser == null) {
      throw Exception('User chưa đăng nhập');
    }
    _currentUser = _currentUser!.copyWith(avatarUrl: avatarUrl);
    return _currentUser!;
  }

  @override
  Future<UserModel> updateUserInfo({
    required String userId,
    required String fullName,
    required String address,
    String? phone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_currentUser == null) {
      throw Exception('User chưa đăng nhập');
    }
    _currentUser = _currentUser!.copyWith(
      fullName: fullName,
      address: address,
      phone: phone,
    );
    return _currentUser!;
  }
}
