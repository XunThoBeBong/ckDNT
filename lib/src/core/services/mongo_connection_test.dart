import 'dart:developer';
import 'mongo_service.dart';

/// Script test kết nối MongoDB - Chạy độc lập để debug
///
/// Cách sử dụng:
/// 1. Gọi hàm này từ main() hoặc từ một button
/// 2. Xem log trong console để biết lỗi cụ thể
Future<void> testMongoConnection() async {
  log("=" * 60);
  log("🔍 BẮT ĐẦU TEST KẾT NỐI MONGODB");
  log("=" * 60);
  log("");

  final mongoService = MongoService();

  try {
    log("📝 Bước 1: Kiểm tra connection string...");
    // Connection string hiện tại (cần kiểm tra trong code)
    log("   ⚠️ Vui lòng kiểm tra connection string trong mongo_service.dart");
    log("");

    log("📝 Bước 2: Đang thử kết nối...");
    await mongoService.connect(
      retryCount: 1, // Chỉ thử 1 lần để xem lỗi nhanh
      retryDelay: Duration(seconds: 1),
    );

    log("");
    log("📝 Bước 3: Kiểm tra trạng thái kết nối...");
    final isConnected = mongoService.isConnected;
    log("   Trạng thái: ${isConnected ? '✅ Đã kết nối' : '❌ Chưa kết nối'}");

    if (isConnected) {
      log("");
      log("📝 Bước 4: Kiểm tra health check...");
      final healthCheck = await mongoService.healthCheck();
      log("   Health check: ${healthCheck ? '✅ OK' : '❌ FAILED'}");

      if (healthCheck) {
        log("");
        log("📝 Bước 5: Test query...");
        final products = await mongoService.getProducts(limit: 1);
        log("   ✅ Query thành công! Tìm thấy ${products.length} sản phẩm");
      }
    } else {
      log("");
      log("❌ KHÔNG THỂ KẾT NỐI!");
      log("");
      log("🔍 CÁC BƯỚC KIỂM TRA:");
      log("   1. Kiểm tra connection string trong mongo_service.dart");
      log("   2. Kiểm tra username/password có đúng không");
      log("   3. Kiểm tra IP đã được whitelist trong MongoDB Atlas chưa");
      log("   4. Kiểm tra cluster có đang hoạt động không");
    }
  } catch (e, stackTrace) {
    log("");
    log("❌❌❌ LỖI KẾT NỐI ❌❌❌");
    log("Chi tiết lỗi: $e");
    log("");
    log("Stack trace:");
    log("$stackTrace");
    log("");

    // Phân tích lỗi
    final errorStr = e.toString().toLowerCase();
    log("🔍 PHÂN TÍCH LỖI:");

    if (errorStr.contains('authentication') ||
        errorStr.contains('auth') ||
        errorStr.contains('invalid credentials')) {
      log("   💡 Đây là lỗi XÁC THỰC");
      log("   → Kiểm tra username và password trong connection string");
      log("   → Vào MongoDB Atlas → Database Access để reset password nếu cần");
    } else if (errorStr.contains('timeout') ||
        errorStr.contains('connection') ||
        errorStr.contains('network')) {
      log("   💡 Đây là lỗi KẾT NỐI/TIMEOUT");
      log("   → Kiểm tra Network Access trong MongoDB Atlas");
      log("   → Thêm IP của bạn hoặc chọn 'Allow Access from Anywhere'");
      log("   → Kiểm tra firewall/antivirus có chặn không");
    } else if (errorStr.contains('dns') ||
        errorStr.contains('host') ||
        errorStr.contains('resolve')) {
      log("   💡 Đây là lỗi DNS/HOST");
      log("   → Kiểm tra connection string có đúng format không");
      log("   → Kiểm tra cluster name có đúng không");
      log("   → Kiểm tra kết nối internet");
    } else if (errorStr.contains('ssl') ||
        errorStr.contains('tls') ||
        errorStr.contains('certificate')) {
      log("   💡 Đây là lỗi SSL/TLS");
      log("   → Có thể là vấn đề tạm thời của MongoDB Atlas");
      log("   → Thử lại sau vài phút");
    } else {
      log("   💡 Lỗi không xác định");
      log("   → Copy toàn bộ error message và stack trace");
      log("   → Kiểm tra MongoDB Atlas dashboard");
    }
  }

  log("");
  log("=" * 60);
  log("🏁 KẾT THÚC TEST");
  log("=" * 60);
}
