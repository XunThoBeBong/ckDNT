# 🌐 Hướng dẫn chạy Flutter Ecommerce trên Web

## 📋 Tổng quan

Dự án hiện tại **KHÔNG thể chạy trực tiếp trên Flutter Web** do sử dụng `mongo_dart` - package này không hỗ trợ web platform.

## ⚠️ Vấn đề chính

### 1. **MongoDB Connection (mongo_dart)**
- ❌ `mongo_dart` **KHÔNG hỗ trợ Flutter Web**
- ❌ Chỉ hoạt động trên: Mobile (Android/iOS), Desktop (Windows/Mac/Linux)
- ❌ Web browsers không có access trực tiếp đến TCP sockets
- ❌ MongoDB driver cần native socket connections

### 2. **Platform Detection (dart:io)**
- ❌ `dart:io` Platform không hoạt động trên web
- ⚠️ Code hiện tại dùng `Platform.isAndroid`, `Platform.isWindows`, etc.

### 3. **Dependencies khác**
- ✅ `image_picker` - Đã có `web_camera_delegate` (OK)
- ✅ `http`, `dio` - Hỗ trợ web (OK)
- ✅ `flutter_bloc`, `go_router` - Hỗ trợ web (OK)
- ✅ `cached_network_image` - Hỗ trợ web (OK)
- ⚠️ `shared_preferences` - Cần kiểm tra web support
- ⚠️ `flutter_secure_storage` - Có thể có vấn đề trên web

---

## 🛠️ CÁC BƯỚC CẦN THỰC HIỆN

### **BƯỚC 1: Tạo REST API Backend (Khuyến nghị)**

#### 1.1. Tạo Backend Server

**Option A: Node.js + Express (Dễ nhất)**
```javascript
// backend/server.js
const express = require('express');
const { MongoClient } = require('mongodb');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const uri = 'mongodb+srv://xuntho:120104@products.blsi64a.mongodb.net/ecommerce';
const client = new MongoClient(uri);

// API: Lấy danh sách sản phẩm
app.get('/api/products', async (req, res) => {
  try {
    await client.connect();
    const products = await client.db('ecommerce').collection('products').find({}).toArray();
    res.json(products);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API: Đăng nhập
app.post('/api/auth/login', async (req, res) => {
  // ... implement login logic
});

// API: Tạo đơn hàng
app.post('/api/orders', async (req, res) => {
  // ... implement create order
});

app.listen(3000, () => {
  console.log('Server running on http://localhost:3000');
});
```

**Option B: Dart + Shelf (Cùng ngôn ngữ)**
```dart
// backend/server.dart
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  final db = await Db.create('mongodb+srv://...');
  await db.open();
  
  final app = Router()
    ..get('/api/products', (Request request) async {
      final products = await db.collection('products').find().toList();
      return Response.ok(products.toString(), headers: {'Content-Type': 'application/json'});
    });
  
  // Start server
}
```

#### 1.2. Deploy Backend
- **Heroku** (Free tier)
- **Railway** (Free tier)
- **Render** (Free tier)
- **VPS** (DigitalOcean, AWS, etc.)

---

### **BƯỚC 2: Tạo API Service trong Flutter**

#### 2.1. Tạo API Client
```dart
// lib/src/core/services/api_service.dart
import 'package:dio/dio.dart';
import '../../data/models/product_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/order_model.dart';

class ApiService {
  final Dio _dio;
  final String baseUrl;

  ApiService({String? baseUrl})
      : baseUrl = baseUrl ?? 'http://localhost:3000',
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? 'http://localhost:3000',
          headers: {'Content-Type': 'application/json'},
        ));

  // Products
  Future<List<ProductModel>> getProducts() async {
    final response = await _dio.get('/api/products');
    return (response.data as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  // Auth
  Future<UserModel> login(String email, String password) async {
    final response = await _dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    return UserModel.fromJson(response.data);
  }

  // Orders
  Future<OrderModel> createOrder(OrderModel order) async {
    final response = await _dio.post('/api/orders', data: order.toJson());
    return OrderModel.fromJson(response.data);
  }
}
```

#### 2.2. Tạo Service Abstraction
```dart
// lib/src/core/services/database_service.dart
abstract class DatabaseService {
  Future<List<ProductModel>> getProducts();
  Future<ProductModel?> getProductById(String id);
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String fullName, String address);
  Future<OrderModel> createOrder(OrderModel order);
  // ... các methods khác
}
```

#### 2.3. Tạo Conditional Imports
```dart
// lib/src/core/services/database_service_stub.dart
export 'database_service_io.dart' if (dart.library.html) 'database_service_web.dart';
```

```dart
// lib/src/core/services/database_service_io.dart (Mobile/Desktop)
import 'mongo_service.dart';

class DatabaseService implements DatabaseService {
  final MongoService _mongoService = MongoService();
  
  @override
  Future<List<ProductModel>> getProducts() {
    return _mongoService.getProducts();
  }
  // ... implement các methods khác
}
```

```dart
// lib/src/core/services/database_service_web.dart (Web)
import 'api_service.dart';

class DatabaseService implements DatabaseService {
  final ApiService _apiService = ApiService();
  
  @override
  Future<List<ProductModel>> getProducts() {
    return _apiService.getProducts();
  }
  // ... implement các methods khác
}
```

---

### **BƯỚC 3: Cập nhật Service Locator**

```dart
// lib/src/core/injection/service_locator.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/database_service_stub.dart';

Future<void> setupServiceLocator() async {
  // Conditional registration
  if (kIsWeb) {
    getIt.registerLazySingleton<DatabaseService>(() => DatabaseService());
  } else {
    getIt.registerLazySingleton<DatabaseService>(() => DatabaseService());
    getIt.registerLazySingleton<MongoService>(() => MongoService());
  }
}
```

---

### **BƯỚC 4: Cập nhật các Repository**

```dart
// lib/src/data/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<UserModel> login({required String email, required String password});
  // ...
}

// lib/src/data/repositories/api_auth_repository.dart (cho Web)
class ApiAuthRepository implements AuthRepository {
  final ApiService _apiService;
  
  ApiAuthRepository(this._apiService);
  
  @override
  Future<UserModel> login({required String email, required String password}) {
    return _apiService.login(email, password);
  }
}
```

---

### **BƯỚC 5: Xử lý Platform Detection**

```dart
// lib/src/core/utils/platform_helper.dart
import 'package:flutter/foundation.dart' show kIsWeb;

bool get isWeb => kIsWeb;
bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
```

---

### **BƯỚC 6: Cấu hình CORS (nếu chạy local)**

Nếu backend chạy local, cần cấu hình CORS:

```javascript
// backend/server.js
const cors = require('cors');
app.use(cors({
  origin: 'http://localhost:8080', // Flutter web dev server
  credentials: true,
}));
```

---

### **BƯỚC 7: Environment Variables cho Web**

```dart
// lib/src/core/config/app_config.dart
class AppConfig {
  static String get apiBaseUrl {
    if (kIsWeb) {
      // Production: 'https://your-api.com'
      // Development: 'http://localhost:3000'
      return const String.fromEnvironment('API_BASE_URL', 
        defaultValue: 'http://localhost:3000');
    } else {
      // Mobile/Desktop: dùng MongoDB trực tiếp
      return '';
    }
  }
}
```

---

## ⚠️ RỦI RO VÀ THÁCH THỨC

### 🔴 **Rủi ro cao**

#### 1. **Bảo mật**
- ❌ **API Keys/Secrets lộ ra client-side**
  - MongoDB connection string không nên expose trên web
  - Cloudinary API secret không nên expose
  - **Giải pháp**: Chỉ expose public keys, secrets phải ở backend

#### 2. **CORS (Cross-Origin Resource Sharing)**
- ❌ Backend phải cấu hình CORS đúng
- ❌ Có thể bị chặn bởi browser security
- **Giải pháp**: Cấu hình CORS đúng domain

#### 3. **Performance**
- ⚠️ Web chậm hơn native apps
- ⚠️ Bundle size lớn (JavaScript)
- ⚠️ First load time có thể chậm
- **Giải pháp**: Code splitting, lazy loading, caching

#### 4. **Browser Compatibility**
- ⚠️ Một số tính năng không hoạt động trên tất cả browsers
- ⚠️ Camera API cần HTTPS
- ⚠️ LocalStorage có giới hạn
- **Giải pháp**: Test trên nhiều browsers, polyfills

---

### 🟡 **Rủi ro trung bình**

#### 5. **State Management**
- ⚠️ State có thể mất khi refresh page
- ⚠️ Cần lưu state vào localStorage/sessionStorage
- **Giải pháp**: Hydrate state từ localStorage

#### 6. **File System Access**
- ⚠️ Web không có access trực tiếp đến file system
- ⚠️ Upload files phải qua browser APIs
- **Giải pháp**: Đã xử lý với `image_picker` và `http`

#### 7. **Network Issues**
- ⚠️ Mất kết nối mạng thường xuyên hơn
- ⚠️ Cần offline support
- **Giải pháp**: Service workers, caching strategies

---

### 🟢 **Rủi ro thấp**

#### 8. **SEO (Search Engine Optimization)**
- ⚠️ Flutter Web render client-side, SEO kém
- **Giải pháp**: SSR (Server-Side Rendering) với Flutter Web

#### 9. **Deep Linking**
- ⚠️ URL routing có thể phức tạp
- **Giải pháp**: `go_router` đã hỗ trợ tốt

---

## 📊 So sánh: Web vs Mobile/Desktop

| Tính năng | Mobile/Desktop | Web |
|-----------|----------------|-----|
| MongoDB | ✅ Trực tiếp (mongo_dart) | ❌ Cần REST API |
| Performance | ✅ Tốt | ⚠️ Chậm hơn |
| Bundle Size | ✅ Nhỏ | ❌ Lớn (JS) |
| Bảo mật | ✅ Tốt hơn | ⚠️ Phải cẩn thận |
| Deployment | ⚠️ App stores | ✅ Chỉ cần hosting |
| SEO | N/A | ⚠️ Kém |
| Offline | ✅ Tốt | ⚠️ Cần service workers |

---

## 🎯 Khuyến nghị

### **Cho Development:**
1. ✅ **Tiếp tục dùng Mobile/Desktop** (Windows/Mac/Linux)
2. ✅ Command: `flutter run -d windows`

### **Cho Production Web:**
1. ✅ **Tạo REST API Backend** (Node.js hoặc Dart)
2. ✅ **Deploy backend** lên cloud (Heroku, Railway, Render)
3. ✅ **Tạo API Service** trong Flutter
4. ✅ **Dùng conditional imports** để switch giữa MongoDB và API
5. ✅ **Test kỹ** trên nhiều browsers
6. ✅ **Cấu hình CORS** đúng
7. ✅ **Bảo mật** - không expose secrets

---

## 📝 Checklist triển khai Web

- [ ] Tạo REST API Backend
- [ ] Deploy backend lên cloud
- [ ] Tạo `ApiService` trong Flutter
- [ ] Tạo `DatabaseService` abstraction
- [ ] Cập nhật Service Locator với conditional imports
- [ ] Cập nhật tất cả Repository để dùng DatabaseService
- [ ] Thay thế `Platform` bằng `kIsWeb`
- [ ] Test trên Chrome, Firefox, Safari, Edge
- [ ] Cấu hình CORS
- [ ] Kiểm tra bảo mật (không expose secrets)
- [ ] Test performance và optimize
- [ ] Setup error handling cho network issues
- [ ] Deploy Flutter Web lên hosting (Firebase Hosting, Netlify, Vercel)

---

## 🚀 Quick Start (Nếu muốn test ngay)

### Option 1: Dùng MongoDB Atlas Data API
1. Vào MongoDB Atlas → App Services
2. Enable Data API
3. Tạo API Service trong Flutter để gọi HTTP endpoints

### Option 2: Mock API (Development)
```dart
// lib/src/core/services/mock_api_service.dart
class MockApiService implements DatabaseService {
  @override
  Future<List<ProductModel>> getProducts() async {
    // Return mock data
    return [];
  }
}
```

---

## 📚 Tài liệu tham khảo

- [Flutter Web Documentation](https://docs.flutter.dev/platform-integration/web)
- [MongoDB Atlas Data API](https://www.mongodb.com/docs/atlas/app-services/data-api/)
- [Flutter Web Best Practices](https://docs.flutter.dev/platform-integration/web/best-practices)
- [CORS Guide](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)

---

## ⏱️ Ước tính thời gian

- **Tạo REST API Backend**: 2-3 ngày
- **Tạo API Service trong Flutter**: 1-2 ngày
- **Refactor code để support cả Web và Mobile**: 2-3 ngày
- **Testing và Debug**: 1-2 ngày
- **Tổng cộng**: **6-10 ngày** (tùy kinh nghiệm)

---

## 💡 Kết luận

**Chạy trên Web là KHẢ THI** nhưng cần:
1. ✅ Tạo REST API Backend (bắt buộc)
2. ✅ Refactor code để support cả Web và Mobile
3. ✅ Chú ý bảo mật và performance
4. ✅ Test kỹ trên nhiều browsers

**Khuyến nghị**: Nếu không cần web ngay, tiếp tục phát triển trên Mobile/Desktop. Khi cần web, tạo backend và refactor code.

