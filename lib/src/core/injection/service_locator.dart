import 'package:get_it/get_it.dart';
import '../services/api_client.dart';
import '../services/mongo_service.dart';
import '../services/storage_service.dart';
import '../services/cloudinary_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/mongo_auth_repository.dart';

/// ServiceLocator - Quản lý Dependency Injection với get_it
///
/// Đăng ký tất cả các service và dependencies của ứng dụng
final getIt = GetIt.instance;

/// Khởi tạo tất cả services
Future<void> setupServiceLocator() async {
  // ============================================
  // 1. Storage Service (Singleton)
  // ============================================
  await StorageService.init();

  // ============================================
  // 2. API Client (Singleton)
  // ============================================
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());

  // ============================================
  // 3. MongoDB Service (Singleton)
  // ============================================
  // Đăng ký instance của MongoService (đã là singleton)
  getIt.registerLazySingleton<MongoService>(() => MongoService());

  // ============================================
  // 4. Cloudinary Service (Singleton)
  // ============================================
  getIt.registerLazySingleton<CloudinaryService>(() => CloudinaryService());
  // Khởi tạo CloudinaryService
  await getIt<CloudinaryService>().initialize();

  // ============================================
  // 5. Auth Repository (Singleton)
  // ============================================
  // Đăng ký MongoAuthRepository để lưu user vào MongoDB
  getIt.registerLazySingleton<AuthRepository>(() => MongoAuthRepository());

  // Kết nối MongoDB khi khởi động app
  // Có thể bỏ qua nếu muốn lazy connect
  print("=" * 60);
  print("🔍 ĐANG KHỞI TẠO MONGODB SERVICE...");
  print("=" * 60);
  try {
    print("📝 Đang thử kết nối MongoDB...");
    await getIt<MongoService>().connect();

    // Kiểm tra trạng thái sau khi kết nối
    final isConnected = getIt<MongoService>().isConnected;
    if (isConnected) {
      print("✅✅✅ KẾT NỐI MONGODB THÀNH CÔNG! ✅✅✅");
      print("📊 Trạng thái: Đã kết nối");

      // Test health check
      print("🏥 Đang kiểm tra health...");
      final healthCheck = await getIt<MongoService>().healthCheck();
      if (healthCheck) {
        print("✅ Health check: OK");
      } else {
        print("⚠️ Health check: FAILED (có thể database chưa có collection)");
      }
    } else {
      print("❌ KẾT NỐI THẤT BẠI!");
      print("📊 Trạng thái: Chưa kết nối được");
    }
  } catch (e, stackTrace) {
    // Log lỗi chi tiết
    print("❌❌❌ KHÔNG THỂ KẾT NỐI MONGODB ❌❌❌");
    print("📋 Chi tiết lỗi: $e");
    print("📍 Stack trace: $stackTrace");
    print("");
    print("🔍 CÁC BƯỚC KIỂM TRA:");
    print("   1. Kiểm tra connection string trong mongo_service.dart");
    print("   2. Kiểm tra username/password có đúng không");
    print("   3. Kiểm tra IP đã được whitelist trong MongoDB Atlas chưa");
    print("   4. Kiểm tra cluster có đang hoạt động không");
    print("");
    print("📝 Sẽ thử kết nối lại khi cần sử dụng");
  }
  print("=" * 60);
}

/// Đóng tất cả connections khi app tắt
Future<void> disposeServiceLocator() async {
  // Đóng MongoDB connection
  if (getIt.isRegistered<MongoService>()) {
    await getIt<MongoService>().disconnect();
  }

  // Reset GetIt (optional, thường không cần)
  // getIt.reset();
}
