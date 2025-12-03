import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

/// AuthState - Base class cho tất cả states của AuthBloc
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// AuthInitial - State khởi tạo (chưa biết đăng nhập hay chưa)
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// AuthLoading - State đang xử lý (login/register/logout)
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// AuthAuthenticated - Đã đăng nhập, có thông tin user
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// AuthUnauthenticated - Chưa đăng nhập / đã đăng xuất
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// AuthFailure - Lỗi đăng nhập / đăng ký
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}
