# 🔍 Hướng dẫn Debug Upload Ảnh trên Android

## ✅ Đã sửa

### 1. Thêm quyền vào AndroidManifest.xml
- ✅ `CAMERA` - Quyền chụp ảnh
- ✅ `READ_EXTERNAL_STORAGE` - Đọc ảnh từ gallery (Android < 13)
- ✅ `READ_MEDIA_IMAGES` - Đọc ảnh từ gallery (Android >= 13)
- ✅ `INTERNET` - Upload lên Cloudinary

### 2. Cải thiện Error Handling
- ✅ Log chi tiết từng bước upload
- ✅ Kiểm tra file tồn tại trước khi đọc
- ✅ Kiểm tra kích thước file (không được 0 bytes)
- ✅ Thông báo lỗi cụ thể cho từng trường hợp

### 3. Cải thiện CloudinaryService
- ✅ Log chi tiết quá trình upload
- ✅ Xử lý lỗi parse response
- ✅ Hiển thị error message từ Cloudinary API

## 🐛 Các lỗi thường gặp và cách xử lý

### Lỗi 1: "File không tồn tại"
**Nguyên nhân:**
- File đã bị xóa sau khi chọn
- Quyền truy cập storage chưa được cấp

**Giải pháp:**
1. Vào **Cài đặt > Ứng dụng > ecommerce > Quyền**
2. Bật quyền **Ảnh và video** (hoặc **Storage**)
3. Thử lại

### Lỗi 2: "File rỗng (0 bytes)"
**Nguyên nhân:**
- File bị corrupt
- Lỗi khi copy file từ gallery

**Giải pháp:**
1. Chọn ảnh khác
2. Kiểm tra ảnh có mở được trong gallery không

### Lỗi 3: "Không thể đọc file"
**Nguyên nhân:**
- Thiếu quyền truy cập
- File bị lock bởi app khác

**Giải pháp:**
1. Đóng các app khác đang mở ảnh
2. Cấp lại quyền storage
3. Restart app

### Lỗi 4: "Upload ảnh thất bại: 401 Unauthorized"
**Nguyên nhân:**
- Cloudinary credentials sai
- Signature không đúng

**Giải pháp:**
1. Kiểm tra file `.env` có đúng không:
   ```
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_API_KEY=your_api_key
   CLOUDINARY_API_SECRET=your_api_secret
   ```
2. Restart app sau khi sửa `.env`

### Lỗi 5: "Upload ảnh thất bại: 400 Bad Request"
**Nguyên nhân:**
- File quá lớn (> 10MB)
- Format ảnh không hỗ trợ
- Transformation string sai

**Giải pháp:**
1. Chọn ảnh nhỏ hơn (< 10MB)
2. Dùng format JPG, PNG, hoặc WebP
3. Kiểm tra log để xem lỗi cụ thể

### Lỗi 6: "Lỗi kết nối mạng"
**Nguyên nhân:**
- Không có internet
- Firewall chặn Cloudinary API
- Timeout

**Giải pháp:**
1. Kiểm tra kết nối internet
2. Thử lại sau vài giây
3. Kiểm tra firewall/antivirus

### Lỗi 7: Camera preview hiển thị pixel art/placeholder thay vì camera thực tế
**Nguyên nhân:**
- Camera app của hệ thống Android có vấn đề
- image_picker đang sử dụng fallback image
- Thiếu queries cho camera intent (Android 11+)
- Camera permission chưa được cấp đúng cách

**Giải pháp:**

#### Bước 1: Kiểm tra quyền camera
1. Vào **Cài đặt > Ứng dụng > ecommerce > Quyền**
2. Đảm bảo quyền **Camera** đã được bật
3. Nếu chưa bật, bật và restart app

#### Bước 2: Kiểm tra camera app của hệ thống
1. Mở app **Camera** mặc định của Android
2. Kiểm tra xem camera có hoạt động bình thường không
3. Nếu camera app có vấn đề:
   - Xóa cache: **Cài đặt > Ứng dụng > Camera > Lưu trữ > Xóa bộ nhớ đệm**
   - Restart thiết bị
   - Cập nhật camera app (nếu có)

#### Bước 3: Kiểm tra AndroidManifest.xml
Đảm bảo đã có các queries cho camera intent:
```xml
<queries>
    <intent>
        <action android:name="android.media.action.IMAGE_CAPTURE" />
    </intent>
</queries>
```

#### Bước 4: Thử các giải pháp thay thế
1. **Sử dụng camera app khác:**
   - Cài đặt camera app khác (như Open Camera, Camera FV-5)
   - image_picker sẽ sử dụng camera app mặc định của hệ thống

2. **Chọn ảnh từ gallery thay vì chụp:**
   - Nếu camera preview vẫn lỗi, có thể chọn ảnh từ gallery
   - Ảnh từ gallery vẫn upload được bình thường

3. **Kiểm tra log:**
   ```bash
   adb logcat | grep -E "(image_picker|camera|Camera)"
   ```
   Xem có lỗi gì liên quan đến camera không

#### Bước 5: Nếu vẫn không được
1. **Clear app data:**
   - Vào **Cài đặt > Ứng dụng > ecommerce > Lưu trữ**
   - Chọn **Xóa dữ liệu** và **Xóa bộ nhớ đệm**
   - Restart app

2. **Reinstall app:**
   ```bash
   flutter clean
   flutter pub get
   flutter run -d <device_id>
   ```

3. **Kiểm tra Android version:**
   - Một số thiết bị Android cũ có thể có vấn đề với camera preview
   - Thử trên thiết bị Android khác hoặc emulator

**Lưu ý:** Nếu camera preview vẫn hiển thị pixel art nhưng sau khi chụp ảnh vẫn lấy được ảnh thực tế, thì vấn đề chỉ là ở preview, không ảnh hưởng đến chức năng upload.

## 📱 Kiểm tra trên Android

### Bước 1: Kiểm tra quyền
1. Mở app **Cài đặt** trên Android
2. Vào **Ứng dụng > ecommerce > Quyền**
3. Đảm bảo các quyền sau đã được bật:
   - ✅ **Camera**
   - ✅ **Ảnh và video** (Android 13+) hoặc **Storage** (Android < 13)

### Bước 2: Kiểm tra log
1. Kết nối Android device qua USB
2. Chạy lệnh:
   ```bash
   flutter run -d <device_id>
   ```
3. Xem log trong terminal khi upload ảnh:
   - `📸 Đã chọn ảnh: ...`
   - `📱 Đang kiểm tra file: ...`
   - `📤 Đang upload lên Cloudinary...`
   - `✅ Upload thành công: ...`

### Bước 3: Test các trường hợp
1. ✅ Chọn ảnh từ gallery
2. ✅ Chụp ảnh mới
3. ✅ Upload ảnh nhỏ (< 1MB)
4. ✅ Upload ảnh lớn (1-5MB)
5. ❌ Upload ảnh rất lớn (> 10MB) - nên báo lỗi

## 🔧 Debug nâng cao

### Xem log chi tiết
```bash
# Android
adb logcat | grep -E "(CloudinaryService|ProfileScreen|image_picker)"

# Hoặc xem tất cả log Flutter
adb logcat | grep flutter
```

### Test Cloudinary credentials
1. Mở file `.env`
2. Kiểm tra 3 biến:
   - `CLOUDINARY_CLOUD_NAME`
   - `CLOUDINARY_API_KEY`
   - `CLOUDINARY_API_SECRET`
3. Test trên Cloudinary Dashboard:
   - Vào https://console.cloudinary.com/
   - Upload ảnh thử nghiệm
   - Nếu thành công → credentials đúng

### Kiểm tra network
```bash
# Test kết nối đến Cloudinary
curl -X GET https://api.cloudinary.com/v1_1/<cloud_name>/resources/image/upload
```

## 📝 Checklist khi gặp lỗi

- [ ] Đã cấp quyền Camera và Storage?
- [ ] File `.env` có đúng credentials?
- [ ] Có kết nối internet?
- [ ] File ảnh có hợp lệ không? (mở được trong gallery)
- [ ] Kích thước file < 10MB?
- [ ] Đã xem log chi tiết trong terminal?
- [ ] Đã restart app sau khi sửa `.env`?
- [ ] Đã test trên device thật (không phải emulator)?

## 🆘 Vẫn không được?

1. **Copy log lỗi đầy đủ** từ terminal
2. **Chụp màn hình** thông báo lỗi trên app
3. **Gửi thông tin:**
   - Android version
   - Device model
   - Log từ terminal
   - Screenshot lỗi

## 📚 Tài liệu tham khảo

- [Android Permissions](https://developer.android.com/training/permissions/requesting)
- [image_picker Documentation](https://pub.dev/packages/image_picker)
- [Cloudinary Upload API](https://cloudinary.com/documentation/image_upload_api_reference)

