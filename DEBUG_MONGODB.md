# 🐛 Debug MongoDB Connection - Hướng dẫn từng bước

## 📋 Connection String hiện tại

```
mongodb+srv://xuntho:120104@products.blsi64a.mongodb.net/ecommerce_db?retryWrites=true&w=majority
```

## ✅ Checklist kiểm tra (Làm theo thứ tự)

### Bước 1: Xem log chi tiết khi app chạy

1. **Mở terminal/console** khi chạy app
2. **Tìm các dòng log** bắt đầu bằng:
   - `🔄 Đang kết nối MongoDB...`
   - `❌ Lỗi kết nối MongoDB: ...`
3. **Copy toàn bộ error message** (rất quan trọng!)

### Bước 2: Test kết nối với script debug

**Cách 1: Uncomment trong main.dart**

Mở file `lib/main.dart`, tìm dòng:
```dart
// await testMongoConnection();
```

Sửa thành:
```dart
await testMongoConnection();
```

Chạy app và xem log chi tiết.

**Cách 2: Sử dụng màn hình test**

Thêm route vào `app_router.dart`:
```dart
GoRoute(
  path: '/test-mongo',
  builder: (context, state) => const MongoTestScreen(),
),
```

Truy cập `/test-mongo` trong app.

### Bước 3: Kiểm tra MongoDB Atlas

#### 3.1. Kiểm tra Network Access (QUAN TRỌNG NHẤT!)

1. Đăng nhập [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Vào **Network Access** (menu bên trái)
3. Kiểm tra xem có IP nào được whitelist chưa
4. **Nếu chưa có:**
   - Click **"Add IP Address"**
   - Chọn **"Allow Access from Anywhere"** (0.0.0.0/0)
   - Click **"Confirm"**
   - ⚠️ Đợi 1-2 phút để thay đổi có hiệu lực

#### 3.2. Kiểm tra Database Access

1. Vào **Database Access** (menu bên trái)
2. Tìm user `xuntho`
3. Kiểm tra:
   - User có tồn tại không?
   - Password có đúng không? (reset nếu cần)
   - User có quyền truy cập database không?

#### 3.3. Kiểm tra Cluster

1. Vào **Database** (menu bên trái)
2. Kiểm tra cluster `products` có đang chạy không
3. Cluster name có đúng `products.blsi64a` không?

### Bước 4: Kiểm tra Connection String

Connection string phải có format:
```
mongodb+srv://USERNAME:PASSWORD@CLUSTER.mongodb.net/DATABASE?OPTIONS
```

**Kiểm tra:**
- ✅ `USERNAME`: `xuntho`
- ✅ `PASSWORD`: `120104` (có thể cần reset nếu sai)
- ✅ `CLUSTER`: `products.blsi64a.mongodb.net`
- ✅ `DATABASE`: `ecommerce_db`
- ✅ `OPTIONS`: `retryWrites=true&w=majority`

### Bước 5: Test với MongoDB Compass (Nếu có)

1. Tải [MongoDB Compass](https://www.mongodb.com/products/compass)
2. Dùng connection string để kết nối
3. Nếu Compass kết nối được → Vấn đề ở code Flutter
4. Nếu Compass không kết nối được → Vấn đề ở MongoDB Atlas

## 🔍 Phân tích lỗi thường gặp

### Lỗi 1: "authentication failed" hoặc "invalid credentials"

**Nguyên nhân:** Username/password sai

**Giải pháp:**
1. Vào MongoDB Atlas → Database Access
2. Tìm user `xuntho`
3. Click **"Edit"** → **"Edit Password"**
4. Tạo password mới
5. Cập nhật password trong connection string

### Lỗi 2: "connection timeout" hoặc "network error"

**Nguyên nhân:** IP chưa được whitelist

**Giải pháp:**
1. Vào MongoDB Atlas → Network Access
2. Click **"Add IP Address"**
3. Chọn **"Allow Access from Anywhere"** (0.0.0.0/0)
4. Click **"Confirm"**
5. Đợi 1-2 phút
6. Thử lại

### Lỗi 3: "DNS resolution failed" hoặc "host not found"

**Nguyên nhân:** Cluster name sai hoặc cluster không tồn tại

**Giải pháp:**
1. Vào MongoDB Atlas → Database
2. Click **"Connect"** trên cluster
3. Chọn **"Connect your application"**
4. Copy connection string mới
5. Cập nhật trong code

### Lỗi 4: "SSL/TLS error"

**Nguyên nhân:** Vấn đề với certificate

**Giải pháp:**
1. Kiểm tra kết nối internet
2. Thử lại sau vài phút
3. Kiểm tra firewall/antivirus

## 🧪 Test nhanh

### Test 1: Kiểm tra connection string format

Connection string hiện tại:
```
mongodb+srv://xuntho:120104@products.blsi64a.mongodb.net/ecommerce_db?retryWrites=true&w=majority
```

✅ Format: Đúng
✅ Có username: `xuntho`
✅ Có password: `120104`
✅ Có cluster: `products.blsi64a.mongodb.net`
✅ Có database: `ecommerce_db`
✅ Có options: `retryWrites=true&w=majority`

### Test 2: Kiểm tra trong MongoDB Atlas

1. ✅ Cluster `products` có tồn tại?
2. ✅ User `xuntho` có tồn tại?
3. ✅ IP đã được whitelist?

## 📞 Cần hỗ trợ?

Nếu vẫn không kết nối được, vui lòng cung cấp:

1. **Toàn bộ error message** từ console (copy/paste)
2. **Screenshot** MongoDB Atlas:
   - Network Access page
   - Database Access page (user `xuntho`)
3. **Đã làm các bước nào** trong checklist trên?

## 🎯 Quick Fix

Nếu muốn test nhanh, thử:

1. **Reset password user `xuntho`:**
   - MongoDB Atlas → Database Access → Edit user → Edit Password

2. **Whitelist IP:**
   - MongoDB Atlas → Network Access → Add IP → Allow from Anywhere

3. **Cập nhật connection string** với password mới

4. **Chạy lại app** và xem log

