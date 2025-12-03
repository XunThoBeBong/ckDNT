# 📸 Hướng dẫn cấu hình Cloudinary

## 📋 Tổng quan

Cloudinary được sử dụng để lưu trữ ảnh avatar của người dùng. Ảnh sẽ được upload lên Cloudinary và URL sẽ được lưu vào MongoDB.

## 🔧 Các bước cấu hình

### 1. Tạo tài khoản Cloudinary

1. Truy cập https://cloudinary.com/
2. Đăng ký tài khoản miễn phí
3. Xác nhận email

### 2. Lấy thông tin API

Sau khi đăng nhập vào Cloudinary Dashboard:

1. Vào **Dashboard** (https://cloudinary.com/console)
2. Copy các thông tin sau:
   - **Cloud Name**: Tên cloud của bạn
   - **API Key**: Key để xác thực
   - **API Secret**: Secret key (⚠️ Bảo mật, không chia sẻ)

### 3. Cấu hình trong file `.env`

Thêm các dòng sau vào file `.env` trong thư mục root của project:

```env
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

**Ví dụ:**
```env
CLOUDINARY_CLOUD_NAME=my-ecommerce-app
CLOUDINARY_API_KEY=123456789012345
CLOUDINARY_API_SECRET=abcdefghijklmnopqrstuvwxyz123456
```

### 4. Cấu hình Upload Preset (Tùy chọn)

1. Vào **Settings** > **Upload**
2. Tạo **Upload Preset** mới:
   - **Preset name**: `avatar_upload` (hoặc tên bạn muốn)
   - **Signing mode**: `Unsigned` (cho phép upload không cần signature)
   - **Folder**: `avatars` (tự động lưu vào folder này)
   - **Transformation**: 
     - Width: 400
     - Height: 400
     - Crop: Fill
     - Gravity: Face (tự động crop theo khuôn mặt)
     - Quality: Auto
     - Format: Auto

**Lưu ý:** Nếu dùng Unsigned preset, có thể bỏ qua signature trong code, nhưng hiện tại code đang dùng Signed upload (an toàn hơn).

## 🚀 Sử dụng

### Trong ProfileScreen

1. User click vào avatar hoặc nút "Thay đổi ảnh đại diện"
2. Chọn ảnh từ Gallery hoặc Camera
3. Ảnh được upload lên Cloudinary
4. URL ảnh được lưu vào MongoDB (field `avatarUrl`)
5. Avatar được hiển thị ngay lập tức

### Flow

```
User chọn ảnh
    ↓
ImagePicker chọn file
    ↓
CloudinaryService.uploadImage()
    ↓
Upload lên Cloudinary API
    ↓
Nhận về secure_url
    ↓
AuthBloc.add(UpdateAvatarRequested(avatarUrl))
    ↓
MongoAuthRepository.updateAvatar()
    ↓
Cập nhật trong MongoDB
    ↓
AuthBloc emit AuthAuthenticated(user mới)
    ↓
ProfileScreen hiển thị avatar mới
```

## 📝 Cấu trúc dữ liệu

### UserModel

```dart
class UserModel {
  final String? avatarUrl; // URL ảnh trên Cloudinary
  // ... các field khác
}
```

### MongoDB Document

```json
{
  "_id": ObjectId("..."),
  "email": "user@example.com",
  "fullName": "Nguyễn Văn A",
  "avatarUrl": "https://res.cloudinary.com/your_cloud/image/upload/v1234567890/avatars/avatar_1234567890.jpg",
  // ... các field khác
}
```

## 🔒 Bảo mật

1. **API Secret**: Không bao giờ commit vào Git
2. **Environment Variables**: Luôn dùng `.env` file và thêm vào `.gitignore`
3. **Signed Upload**: Code hiện tại dùng signed upload (cần signature), an toàn hơn unsigned

## ⚠️ Lưu ý

1. **Free Tier**: Cloudinary free tier có giới hạn:
   - 25GB storage
   - 25GB bandwidth/tháng
   - Đủ cho development và small production

2. **Image Optimization**: Cloudinary tự động:
   - Resize ảnh về 400x400
   - Compress ảnh (quality: auto)
   - Convert format (auto: WebP nếu browser hỗ trợ)
   - Crop theo khuôn mặt (gravity: face)

3. **Error Handling**: Code đã xử lý các lỗi:
   - Không có credentials → Hiển thị cảnh báo
   - Upload thất bại → Hiển thị SnackBar
   - Network error → Catch và log

## 🐛 Troubleshooting

### Lỗi: "Cloudinary credentials chưa được cấu hình"

**Giải pháp:**
1. Kiểm tra file `.env` có tồn tại không
2. Kiểm tra các biến `CLOUDINARY_*` đã được thêm chưa
3. Restart app sau khi thêm vào `.env`

### Lỗi: "Upload ảnh thất bại: 401 Unauthorized"

**Giải pháp:**
1. Kiểm tra `API_KEY` và `API_SECRET` có đúng không
2. Kiểm tra `CLOUD_NAME` có đúng không
3. Kiểm tra signature có được tính đúng không

### Lỗi: "Upload ảnh thất bại: 400 Bad Request"

**Giải pháp:**
1. Kiểm tra file ảnh có hợp lệ không
2. Kiểm tra kích thước file (nên < 10MB)
3. Kiểm tra format ảnh (JPG, PNG, WebP)

## 📚 Tài liệu tham khảo

- [Cloudinary Documentation](https://cloudinary.com/documentation)
- [Cloudinary Flutter Upload](https://cloudinary.com/documentation/flutter_image_and_video_upload)
- [Cloudinary API Reference](https://cloudinary.com/documentation/image_upload_api_reference)

