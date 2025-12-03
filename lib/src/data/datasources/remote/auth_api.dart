// File này dành cho future: call API thật (REST / GraphQL / v.v.)
// Hiện tại AuthBloc đang dùng InMemoryAuthRepository để demo logic đăng nhập.
//
// Sau này bạn có thể:
// - Tạo class AuthApi dùng http/dio để call backend
// - Implement AuthRepository dựa trên AuthApi
// - Đăng ký implementation đó vào get_it và inject vào AuthBloc.

class AuthApi {
  // Ví dụ stub:
  // Future<UserModel> login(String email, String password) async { ... }
}
