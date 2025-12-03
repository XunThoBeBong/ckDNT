import 'package:equatable/equatable.dart';

/// AuthEvent - Base class cho tất cả events của AuthBloc
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// LoginRequested - Event yêu cầu đăng nhập
class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// RegisterRequested - Event yêu cầu đăng ký tài khoản mới
class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String address;

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.address,
  });

  @override
  List<Object?> get props => [email, password, fullName, address];
}

/// LogoutRequested - Event yêu cầu đăng xuất
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// CheckAuthStatusRequested - Event kiểm tra trạng thái đăng nhập (vd: lúc mở app)
class CheckAuthStatusRequested extends AuthEvent {
  const CheckAuthStatusRequested();
}

/// UpdateAvatarRequested - Event cập nhật avatar của user
class UpdateAvatarRequested extends AuthEvent {
  final String avatarUrl;

  const UpdateAvatarRequested({required this.avatarUrl});

  @override
  List<Object?> get props => [avatarUrl];
}

/// UpdateUserInfoRequested - Event cập nhật thông tin cá nhân của user
class UpdateUserInfoRequested extends AuthEvent {
  final String fullName;
  final String address;
  final String? phone;

  const UpdateUserInfoRequested({
    required this.fullName,
    required this.address,
    this.phone,
  });

  @override
  List<Object?> get props => [fullName, address, phone];
}
