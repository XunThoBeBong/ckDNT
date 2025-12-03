# Hướng dẫn sử dụng MongoService

## 📋 Tổng quan

`MongoService` là service quản lý kết nối và thao tác với MongoDB, sử dụng Singleton pattern để đảm bảo chỉ có 1 kết nối duy nhất trong suốt app.

## ✅ Đánh giá Code ban đầu

### Điểm mạnh:
- ✅ Singleton pattern đúng cách
- ✅ Có error handling cơ bản
- ✅ Code rõ ràng, dễ đọc

### Điểm cần cải thiện:
- ⚠️ Connection string hardcode (nên dùng env variables)
- ⚠️ Thiếu retry logic khi kết nối thất bại
- ⚠️ Thiếu health check
- ⚠️ Thiếu các method CRUD generic
- ⚠️ Thiếu pagination, sorting, filtering
- ⚠️ Chưa tích hợp với get_it

## 🚀 Các cải tiến đã thực hiện

### 1. **Retry Logic**
- Tự động thử lại kết nối nếu thất bại (mặc định 3 lần)
- Có thể tùy chỉnh số lần thử và thời gian chờ

### 2. **Connection Management**
- Kiểm tra trạng thái kết nối trước khi thao tác
- Tự động kết nối lại nếu chưa kết nối
- Method `disconnect()` để đóng kết nối
- Method `healthCheck()` để kiểm tra sức khỏe connection

### 3. **Enhanced Product Methods**
- `getProducts()`: Hỗ trợ pagination, sorting, filtering
- `getProductById()`: Lấy sản phẩm theo ID
- `searchProducts()`: Tìm kiếm sản phẩm theo tên
- `getProductsByCategory()`: Lấy sản phẩm theo danh mục
- `getFeaturedProducts()`: Lấy sản phẩm nổi bật
- `getPopularProducts()`: Lấy sản phẩm phổ biến

### 4. **Generic CRUD Methods**
- `find()`: Tìm kiếm trong bất kỳ collection nào
- `insert()`: Thêm document mới
- `update()`: Cập nhật document
- `delete()`: Xóa document

### 5. **Tích hợp get_it**
- Đăng ký service trong `service_locator.dart`
- Tự động kết nối khi app khởi động

## 📖 Cách sử dụng

### 1. Cấu hình Connection String

**Quan trọng**: Di chuyển connection string ra khỏi code!

#### Option 1: Sử dụng flutter_dotenv (Khuyến nghị)

```yaml
# pubspec.yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

```dart
// .env file (không commit vào git!)
MONGO_CONNECTION_STRING=mongodb+srv://admin:password@cluster0...mongodb.net/ecommerce_db?retryWrites=true&w=majority
```

```dart
// mongo_service.dart
static String get _connString => dotenv.env['MONGO_CONNECTION_STRING'] ?? '';
```

#### Option 2: Sử dụng build_config

Tạo file `build_config.yaml` và sử dụng package `build_config`.

### 2. Sử dụng trong Code

#### Cách 1: Dùng get_it (Khuyến nghị)

```dart
import 'package:get_it/get_it.dart';
import 'src/core/injection/service_locator.dart';

// Lấy service
final mongoService = getIt<MongoService>();

// Sử dụng
final products = await mongoService.getProducts(limit: 10);
```

#### Cách 2: Dùng Singleton trực tiếp

```dart
import 'src/core/services/mongo_service.dart';

// Lấy instance
final mongoService = MongoService();

// Sử dụng
final products = await mongoService.getProducts(limit: 10);
```

### 3. Ví dụ sử dụng các methods

```dart
// Lấy tất cả sản phẩm
final allProducts = await mongoService.getProducts();

// Lấy sản phẩm với pagination
final products = await mongoService.getProducts(
  limit: 20,
  skip: 0,
  sortBy: 'price',
  sortOrder: 1, // 1 = tăng dần, -1 = giảm dần
);

// Tìm kiếm sản phẩm
final searchResults = await mongoService.searchProducts('iPhone');

// Lấy sản phẩm theo danh mục
final categoryProducts = await mongoService.getProductsByCategory('category_id');

// Lấy sản phẩm nổi bật
final featured = await mongoService.getFeaturedProducts(limit: 5);

// Lấy sản phẩm phổ biến
final popular = await mongoService.getPopularProducts(limit: 10);

// Lấy sản phẩm theo ID
final product = await mongoService.getProductById('product_id');

// Generic CRUD
final users = await mongoService.find('users', {'status': 'active'});
final userId = await mongoService.insert('users', {'name': 'John', 'email': 'john@example.com'});
await mongoService.update('users', {'_id': userId}, {'name': 'John Doe'});
await mongoService.delete('users', {'_id': userId});
```

## 🔒 Bảo mật

### ⚠️ QUAN TRỌNG: Không commit connection string vào Git!

1. Thêm `.env` vào `.gitignore`
2. Sử dụng environment variables
3. Hoặc sử dụng secrets management service (AWS Secrets Manager, Azure Key Vault, etc.)

## 🎯 Đề xuất phát triển tiếp

### 1. **Caching Layer**
```dart
// Thêm cache cho các query thường dùng
class MongoService {
  final Map<String, CachedData> _cache = {};
  
  Future<List<ProductModel>> getProducts({bool useCache = true}) async {
    if (useCache && _cache.containsKey('products')) {
      return _cache['products']!.data;
    }
    // ... fetch from DB
  }
}
```

### 2. **Connection Pooling**
MongoDB driver đã có connection pooling tự động, nhưng có thể tùy chỉnh:
```dart
_db = await Db.create(
  _connString,
  options: DbOptions(
    maxPoolSize: 10,
    minPoolSize: 2,
  ),
);
```

### 3. **Transaction Support**
```dart
Future<bool> updateWithTransaction(
  String collectionName,
  Map<String, dynamic> query,
  Map<String, dynamic> updateData,
) async {
  final session = await _db!.startSession();
  try {
    await session.startTransaction();
    // ... perform operations
    await session.commitTransaction();
    return true;
  } catch (e) {
    await session.abortTransaction();
    return false;
  }
}
```

### 4. **Index Management**
```dart
Future<void> createIndexes() async {
  await _db!.collection('products').createIndex({'name': 1});
  await _db!.collection('products').createIndex({'categoryId': 1});
  await _db!.collection('products').createIndex({'price': 1});
}
```

### 5. **Aggregation Pipeline**
```dart
Future<List<Map<String, dynamic>>> getProductStats() async {
  return await _db!.collection('products').aggregate([
    {'\$group': {
      '_id': '\$categoryId',
      'total': {'\$sum': 1},
      'avgPrice': {'\$avg': '\$price'},
    }},
  ]).toList();
}
```

### 6. **Real-time với Change Streams**
```dart
Stream<List<ProductModel>> watchProducts() {
  return _db!.collection('products')
    .watch()
    .map((change) => ProductModel.fromJson(change.fullDocument));
}
```

### 7. **Error Handling nâng cao**
```dart
class MongoException implements Exception {
  final String message;
  final int? code;
  MongoException(this.message, [this.code]);
}

// Sử dụng trong service
throw MongoException('Lỗi kết nối', 500);
```

### 8. **Logging nâng cao**
Sử dụng `logger` package thay vì `log`:
```yaml
dependencies:
  logger: ^2.0.0
```

### 9. **Unit Testing**
```dart
// test/mongo_service_test.dart
void main() {
  group('MongoService', () {
    test('should connect successfully', () async {
      final service = MongoService();
      await service.connect();
      expect(service.isConnected, true);
    });
  });
}
```

### 10. **Monitoring & Metrics**
```dart
class MongoService {
  int _queryCount = 0;
  Duration _totalQueryTime = Duration.zero;
  
  Future<List<ProductModel>> getProducts() async {
    final stopwatch = Stopwatch()..start();
    try {
      // ... query
      _queryCount++;
      return result;
    } finally {
      stopwatch.stop();
      _totalQueryTime += stopwatch.elapsed;
    }
  }
}
```

## 📝 Checklist trước khi deploy

- [ ] Di chuyển connection string ra environment variables
- [ ] Thêm `.env` vào `.gitignore`
- [ ] Test tất cả methods
- [ ] Thêm error handling cho production
- [ ] Setup connection pooling phù hợp
- [ ] Thêm logging cho monitoring
- [ ] Test với large dataset
- [ ] Setup health check endpoint
- [ ] Document API methods

## 🐛 Troubleshooting

### Lỗi kết nối
- Kiểm tra connection string
- Kiểm tra network/firewall
- Kiểm tra MongoDB Atlas IP whitelist

### Lỗi query
- Kiểm tra collection name
- Kiểm tra field names
- Kiểm tra data types

### Performance issues
- Thêm indexes
- Sử dụng pagination
- Cache các query thường dùng

