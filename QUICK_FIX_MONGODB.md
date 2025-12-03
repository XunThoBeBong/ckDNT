# 🚀 Sửa nhanh kết nối MongoDB

## ⚠️ Vấn đề

Connection string trong code vẫn là **placeholder**:
```
mongodb+srv://admin:<password>@cluster0.....mongodb.net/ecommerce_db?retryWrites=true&w=majority
```

## ✅ Giải pháp nhanh (2 phút)

### Bước 1: Lấy Connection String từ MongoDB Atlas

1. Đăng nhập [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Vào **Database** → Click **Connect** trên cluster của bạn
3. Chọn **Connect your application**
4. Copy connection string (sẽ có dạng):
   ```
   mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```

### Bước 2: Sửa file `lib/src/core/services/mongo_service.dart`

Tìm dòng 26-27 và thay thế:

**TRƯỚC:**
```dart
static const String _connString =
    "mongodb+srv://admin:<password>@cluster0.....mongodb.net/ecommerce_db?retryWrites=true&w=majority";
```

**SAU:**
```dart
static const String _connString =
    "mongodb+srv://YOUR_USERNAME:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/ecommerce_db?retryWrites=true&w=majority";
```

**Lưu ý:**
- Thay `YOUR_USERNAME` bằng username MongoDB của bạn
- Thay `YOUR_PASSWORD` bằng password MongoDB của bạn  
- Thay `cluster0.xxxxx` bằng cluster thật của bạn
- Giữ nguyên `ecommerce_db` hoặc thay bằng tên database bạn muốn

### Bước 3: Whitelist IP trong MongoDB Atlas

1. Vào **Network Access** trong MongoDB Atlas
2. Click **Add IP Address**
3. Chọn **Allow Access from Anywhere** (0.0.0.0/0) cho development
   - Hoặc thêm IP cụ thể của bạn

### Bước 4: Test kết nối

Chạy app và xem log:
- ✅ Thấy `KẾT NỐI MONGODB THÀNH CÔNG!` → OK
- ❌ Thấy lỗi → Xem phần Troubleshooting bên dưới

## 🐛 Troubleshooting

### Lỗi: "authentication failed"
→ Username/password sai. Kiểm tra lại trong MongoDB Atlas → Database Access

### Lỗi: "connection timeout"  
→ IP chưa được whitelist. Vào Network Access → Add IP Address

### Lỗi: "invalid connection string"
→ Format connection string sai. Copy lại từ MongoDB Atlas

## 📝 Ví dụ Connection String đúng

```
mongodb+srv://myuser:mypassword123@cluster0.abc123.mongodb.net/ecommerce_db?retryWrites=true&w=majority
```

## 🔒 Lưu ý bảo mật

Sau khi test xong, nên:
1. Di chuyển connection string ra file `.env` (xem `MONGODB_CONNECTION_GUIDE.md`)
2. Thêm `.env` vào `.gitignore`
3. Không commit connection string lên Git

