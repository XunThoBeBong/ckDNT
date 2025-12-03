import 'dart:developer';
import 'mongo_service.dart';

/// Helper class để debug MongoDB connection
class MongoDebugHelper {
  /// Test connection và hiển thị thông tin chi tiết
  static Future<void> testConnection() async {
    log("🔍 BẮT ĐẦU TEST KẾT NỐI MONGODB");
    log("=" * 50);

    final mongoService = MongoService();

    try {
      // Không thể truy cập _connString vì nó là private
      log("📝 Đang sử dụng connection string từ MongoService");
      log("");

      log("🔄 Đang thử kết nối...");
      await mongoService.connect();

      if (mongoService.isConnected) {
        log("✅ KẾT NỐI THÀNH CÔNG!");
        log("");

        log("🏥 Đang kiểm tra health...");
        final healthCheck = await mongoService.healthCheck();
        if (healthCheck) {
          log("✅ Health check: OK");
        } else {
          log("⚠️ Health check: FAILED");
        }

        log("");
        log("📊 Thông tin kết nối:");
        log("   - Connected: ${mongoService.isConnected}");
        log("   - Health: $healthCheck");
      } else {
        log("❌ KẾT NỐI THẤT BẠI!");
        log("   Trạng thái: Không kết nối được");
      }
    } catch (e, stackTrace) {
      log("❌❌❌ LỖI KẾT NỐI ❌❌❌");
      log("📋 Chi tiết: $e");
      log("📍 Stack trace: $stackTrace");
      log("");
      log("🔍 CÁC BƯỚC KIỂM TRA:");
      log("   1. ✅ Kiểm tra connection string có đúng format không?");
      log("   2. ✅ Username/password có đúng không?");
      log("   3. ✅ IP đã được whitelist trong MongoDB Atlas chưa?");
      log("      → Vào MongoDB Atlas → Network Access → Add IP Address");
      log("      → Chọn 'Allow Access from Anywhere' (0.0.0.0/0)");
      log("   4. ✅ Cluster có đang hoạt động không?");
      log("   5. ✅ Database user có quyền truy cập không?");
      log("");

      // Phân tích lỗi cụ thể
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('authentication')) {
        log("💡 GỢI Ý: Lỗi xác thực - Kiểm tra username/password");
      } else if (errorStr.contains('timeout') ||
          errorStr.contains('connection')) {
        log(
          "💡 GỢI Ý: Lỗi timeout - Kiểm tra Network Access trong MongoDB Atlas",
        );
      } else if (errorStr.contains('dns') || errorStr.contains('host')) {
        log("💡 GỢI Ý: Lỗi DNS - Kiểm tra connection string có đúng không");
      }
    }

    log("=" * 50);
    log("🏁 KẾT THÚC TEST");
  }

  /// Kiểm tra connection string format
  static bool validateConnectionString(String connString) {
    log("🔍 Kiểm tra format connection string...");

    if (!connString.startsWith('mongodb+srv://')) {
      log("❌ Connection string phải bắt đầu với 'mongodb+srv://'");
      return false;
    }

    if (!connString.contains('@')) {
      log("❌ Connection string thiếu username/password");
      return false;
    }

    if (!connString.contains('.mongodb.net')) {
      log("❌ Connection string thiếu cluster address");
      return false;
    }

    log("✅ Format connection string: OK");
    return true;
  }
}
