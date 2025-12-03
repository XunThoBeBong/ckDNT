# ⚠️ Vấn đề: MongoDB không hoạt động trên Flutter Web

## 🔴 Lỗi hiện tại

```
Unsupported operation: Platform._operatingSystem
```

## 📋 Nguyên nhân

**`mongo_dart` KHÔNG hỗ trợ Flutter Web!**

Package `mongo_dart` chỉ hoạt động trên:
- ✅ Flutter Mobile (Android/iOS)
- ✅ Flutter Desktop (Windows/Mac/Linux)
- ✅ Dart VM (server-side)

❌ **KHÔNG hoạt động trên Flutter Web** vì:
1. Flutter Web chạy trên JavaScript, không có access trực tiếp đến TCP sockets
2. MongoDB driver cần native socket connections
3. Web browsers có CORS restrictions

## ✅ Giải pháp

### Giải pháp 1: Chạy trên Desktop/Mobile (Nhanh nhất)

**Thay vì chạy trên Chrome (web), chạy trên Windows Desktop:**

```bash
flutter run -d windows
```

Hoặc chọn option `[1]: Windows (windows)` khi chạy `flutter run`

### Giải pháp 2: Tạo REST API Backend (Khuyến nghị cho production)

Tạo một backend server (Node.js, Dart, Python, etc.) để:
1. Kết nối MongoDB
2. Expose REST API endpoints
3. Flutter Web gọi API này thay vì kết nối trực tiếp MongoDB

**Kiến trúc:**
```
Flutter Web → HTTP/REST API → MongoDB
```

**Ví dụ với Dart backend:**
```dart
// backend/server.dart
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  final db = await Db.create('mongodb+srv://...');
  await db.open();
  
  final app = Router()
    ..get('/products', (Request request) async {
      final products = await db.collection('products').find().toList();
      return Response.ok(products.toString());
    });
  
  // Start server
}
```

**Flutter Web gọi API:**
```dart
// Thay vì MongoService, dùng HTTP client
final response = await http.get(Uri.parse('http://localhost:8080/products'));
```

### Giải pháp 3: Sử dụng MongoDB Atlas Data API (HTTP-based)

MongoDB Atlas cung cấp Data API (HTTP) cho phép truy cập từ web:

1. Vào MongoDB Atlas → App Services
2. Enable Data API
3. Sử dụng HTTP requests thay vì mongo_dart

**Ví dụ:**
```dart
final response = await http.post(
  Uri.parse('https://data.mongodb-api.com/app/.../endpoint/data/v1/action/find'),
  headers: {
    'Content-Type': 'application/json',
    'api-key': 'YOUR_API_KEY',
  },
  body: jsonEncode({
    'dataSource': 'Cluster0',
    'database': 'ecommerce_db',
    'collection': 'products',
  }),
);
```

### Giải pháp 4: Conditional Import (Chỉ dùng MongoDB trên Mobile/Desktop)

Tạo một service wrapper để chỉ dùng MongoDB trên non-web platforms:

```dart
// lib/src/core/services/database_service.dart
import 'database_service_stub.dart'
    if (dart.library.io) 'database_service_io.dart'
    if (dart.library.html) 'database_service_web.dart';

abstract class DatabaseService {
  Future<List<ProductModel>> getProducts();
  // ...
}
```

```dart
// database_service_io.dart (cho Mobile/Desktop)
import 'mongo_service.dart';

class DatabaseService extends MongoService {
  // Implement với MongoDB
}
```

```dart
// database_service_web.dart (cho Web)
import 'api_client.dart';

class DatabaseService {
  Future<List<ProductModel>> getProducts() async {
    // Gọi REST API thay vì MongoDB
    final response = await apiClient.get('/products');
    // ...
  }
}
```

## 🎯 Khuyến nghị

### Cho Development:
- **Chạy trên Windows Desktop** thay vì Web
- Command: `flutter run -d windows`

### Cho Production:
- **Tạo REST API Backend** để kết nối MongoDB
- Flutter Web gọi API qua HTTP
- Đây là cách tiếp cận chuẩn và an toàn hơn

## 📝 Quick Fix ngay bây giờ

**Chạy app trên Windows Desktop:**

```bash
cd ecommerce
flutter run -d windows
```

Hoặc khi chạy `flutter run`, chọn option `[1]` thay vì `[2]`.

## 🔗 Tài liệu tham khảo

- [MongoDB Atlas Data API](https://www.mongodb.com/docs/atlas/api/data-api/)
- [Flutter Platform Channels](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [Shelf (Dart HTTP Server)](https://pub.dev/packages/shelf)

