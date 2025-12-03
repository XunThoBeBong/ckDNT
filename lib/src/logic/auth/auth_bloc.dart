import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_event.dart';
import 'auth_state.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/injection/service_locator.dart';

/// AuthBloc - Quản lý logic đăng nhập / đăng ký / đăng xuất
///
/// Trách nhiệm chính:
/// - Nhận event LoginRequested / RegisterRequested / LogoutRequested / CheckAuthStatusRequested
/// - Gọi AuthRepository để kiểm tra mật khẩu / đăng ký
/// - Phát ra state AuthAuthenticated / AuthUnauthenticated / AuthFailure
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({AuthRepository? authRepository})
    : _authRepository = authRepository ?? getIt<AuthRepository>(),
      super(const AuthInitial()) {
    /// Đăng nhập
    on<LoginRequested>(_onLoginRequested);

    /// Đăng ký
    on<RegisterRequested>(_onRegisterRequested);

    /// Đăng xuất
    on<LogoutRequested>(_onLogoutRequested);

    /// Kiểm tra trạng thái đăng nhập (ví dụ: lúc mở app)
    on<CheckAuthStatusRequested>(_onCheckAuthStatusRequested);

    /// Cập nhật avatar
    on<UpdateAvatarRequested>(_onUpdateAvatarRequested);

    /// Cập nhật thông tin cá nhân
    on<UpdateUserInfoRequested>(_onUpdateUserInfoRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      final UserModel user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      final UserModel user = await _authRepository.register(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
        address: event.address,
      );

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      await _authRepository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onCheckAuthStatusRequested(
    CheckAuthStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onUpdateAvatarRequested(
    UpdateAvatarRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Lấy user hiện tại từ state
      final currentState = state;
      if (currentState is! AuthAuthenticated) {
        emit(AuthFailure('Bạn cần đăng nhập để cập nhật avatar'));
        return;
      }

      emit(const AuthLoading());

      // Cập nhật avatar
      final updatedUser = await _authRepository.updateAvatar(
        userId: currentState.user.id!,
        avatarUrl: event.avatarUrl,
      );

      emit(AuthAuthenticated(updatedUser));
    } catch (e) {
      emit(AuthFailure(e.toString()));
      // Giữ nguyên state hiện tại nếu lỗi
      if (state is AuthAuthenticated) {
        emit(state);
      }
    }
  }

  Future<void> _onUpdateUserInfoRequested(
    UpdateUserInfoRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Lấy user hiện tại từ state
      final currentState = state;
      if (currentState is! AuthAuthenticated) {
        emit(AuthFailure('Bạn cần đăng nhập để cập nhật thông tin'));
        return;
      }

      emit(const AuthLoading());

      // Cập nhật thông tin
      final updatedUser = await _authRepository.updateUserInfo(
        userId: currentState.user.id!,
        fullName: event.fullName,
        address: event.address,
        phone: event.phone,
      );

      emit(AuthAuthenticated(updatedUser));
    } catch (e) {
      emit(AuthFailure(e.toString()));
      // Giữ nguyên state hiện tại nếu lỗi
      if (state is AuthAuthenticated) {
        emit(state);
      }
    }
  }
}
