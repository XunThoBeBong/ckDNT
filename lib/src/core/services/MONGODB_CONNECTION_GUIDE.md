# 🔧 Hướng dẫn kết nối MongoDB

## ❌ Vấn đề hiện tại

Connection string trong code vẫn là **placeholder**, chưa phải connection string thật:

```dart
static const String _connString =
    "mongodb+srv://admin:<password>@cluster0.....mongodb.net/ecommerce_db?retryWrites=true&w=majority";
```

## ✅ Giải pháp

### Cách 1: Thay trực tiếp trong code (Nhanh, nhưng không an toàn)

1. **Lấy connection string từ MongoDB Atlas:**
   - Đăng nhập vào [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
   - Vào **Database** → **Connect**
   - Chọn **Connect your application**
   - Copy connection string (dạng: `mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority`)

2. **Sửa file `mongo_service.dart`:**
   ```dart
   static const String _connString =
       "mongodb+srv://YOUR_USERNAME:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/ecommerce_db?retryWrites=true&w=majority";
   ```
   
   ⚠️ **Lưu ý:**
   - Thay `YOUR_USERNAME` và `YOUR_PASSWORD` bằng thông tin thật
   - Thay `cluster0.xxxxx` bằng cluster của bạn
   - Thay `ecommerce_db` bằng tên database bạn muốn dùng

3. **Kiểm tra Network Access:**
   - Vào **Network Access** trong MongoDB Atlas
   - Thêm IP của bạn hoặc chọn **Allow Access from Anywhere** (0.0.0.0/0) cho development

### Cách 2: Sử dụng flutter_dotenv (Khuyến nghị - An toàn hơn)

#### Bước 1: Tạo file `.env`

Tạo file `.env` ở thư mục root của project (`ecommerce/.env`):

```env
MONGO_CONNECTION_STRING=mongodb+srv://YOUR_USERNAME:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/ecommerce_db?retryWrites=true&w=majority
```

#### Bước 2: Thêm `.env` vào `.gitignore`

Đảm bảo file `.env` không bị commit lên Git:

```gitignore
# Environment variables
.env
.env.local
.env.*.local
```

#### Bước 3: Cấu hình pubspec.yaml

Đảm bảo đã có `flutter_dotenv` trong `pubspec.yaml`:

```yaml
dependencies:
  flutter_dotenv: ^6.0.0
```

Và thêm `.env` vào assets:

```yaml
flutter:
  assets:
    - .env
```

#### Bước 4: Load .env trong main.dart

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  await dotenv.load(fileName: ".env");
  
  await setupServiceLocator();
  runApp(const MyApp());
}
```

#### Bước 5: Sửa mongo_service.dart

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MongoService {
  // ...
  
  // Lấy connection string từ .env
  static String get _connString {
    final connStr = dotenv.env['MONGO_CONNECTION_STRING'];
    if (connStr == null || connStr.isEmpty) {
      throw Exception('MONGO_CONNECTION_STRING không được tìm thấy trong .env');
    }
    return connStr;
  }
  
  // ...
}
```

## 🧪 Test kết nối

### Cách 1: Kiểm tra log khi app khởi động

Khi chạy app, bạn sẽ thấy log trong console:
- ✅ `KẾT NỐI MONGODB THÀNH CÔNG!` → Kết nối thành công
- ❌ `Lỗi kết nối MongoDB: ...` → Có lỗi, xem chi tiết bên dưới

### Cách 2: Tạo test screen

Tạo một màn hình test để kiểm tra kết nối:

```dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../core/injection/service_locator.dart';
import '../../core/services/mongo_service.dart';

class TestMongoScreen extends StatefulWidget {
  const TestMongoScreen({super.key});

  @override
  State<TestMongoScreen> createState() => _TestMongoScreenState();
}

class _TestMongoScreenState extends State<TestMongoScreen> {
  String _status = 'Đang kiểm tra...';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      final mongoService = getIt<MongoService>();
      
      setState(() {
        _status = 'Đang kết nối...';
      });

      await mongoService.connect();
      
      final isConnected = mongoService.isConnected;
      final healthCheck = await mongoService.healthCheck();

      setState(() {
        _isConnected = isConnected;
        if (isConnected && healthCheck) {
          _status = '✅ Kết nối thành công và database hoạt động tốt!';
        } else if (isConnected) {
          _status = '⚠️ Đã kết nối nhưng health check thất bại';
        } else {
          _status = '❌ Không thể kết nối';
        }
      });
    } catch (e) {
      setState(() {
        _status = '❌ Lỗi: $e';
        _isConnected = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test MongoDB Connection')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isConnected ? Icons.check_circle : Icons.error,
                size: 64,
                color: _isConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkConnection,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 🐛 Troubleshooting

### Lỗi 1: "authentication failed"
**Nguyên nhân:** Username/password sai
**Giải pháp:** Kiểm tra lại username và password trong connection string

### Lỗi 2: "connection timeout"
**Nguyên nhân:** 
- IP chưa được whitelist trong MongoDB Atlas
- Firewall chặn kết nối
**Giải pháp:** 
- Vào MongoDB Atlas → Network Access → Add IP Address
- Hoặc chọn "Allow Access from Anywhere" (0.0.0.0/0) cho development

### Lỗi 3: "invalid connection string"
**Nguyên nhân:** Connection string không đúng format
**Giải pháp:** 
- Kiểm tra lại connection string
- Đảm bảo có đầy đủ: `mongodb+srv://username:password@cluster/database?options`

### Lỗi 4: "database name not found"
**Nguyên nhân:** Database chưa được tạo
**Giải pháp:** 
- Database sẽ tự động được tạo khi insert document đầu tiên
- Hoặc tạo database thủ công trong MongoDB Atlas

### Lỗi 5: "SSL/TLS connection error"
**Nguyên nhân:** Vấn đề với SSL certificate
**Giải pháp:** 
- Kiểm tra kết nối internet
- Thử lại sau vài phút (có thể là vấn đề tạm thời của MongoDB Atlas)

## 📝 Checklist

- [ ] Đã thay connection string thật (không còn `<password>` và `.....`)
- [ ] Đã whitelist IP trong MongoDB Atlas Network Access
- [ ] Đã kiểm tra username/password đúng
- [ ] Đã test kết nối và thấy log "KẾT NỐI MONGODB THÀNH CÔNG!"
- [ ] Đã test health check thành công

## 🔒 Bảo mật

⚠️ **QUAN TRỌNG:**
- **KHÔNG** commit connection string vào Git
- **KHÔNG** share connection string công khai
- **NÊN** dùng `.env` file và thêm vào `.gitignore`
- **NÊN** tạo user riêng cho app (không dùng admin user)
- **NÊN** giới hạn quyền của user trong MongoDB Atlas

## 📞 Cần hỗ trợ?

Nếu vẫn gặp vấn đề, hãy:
1. Kiểm tra log chi tiết trong console
2. Copy toàn bộ error message
3. Kiểm tra lại các bước trên
4. Xem [MongoDB Atlas Documentation](https://docs.atlas.mongodb.com/)

