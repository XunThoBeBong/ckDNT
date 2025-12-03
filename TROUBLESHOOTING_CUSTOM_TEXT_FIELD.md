# 🔧 Khắc phục: CustomTextField không hiển thị thay đổi

## 📋 Danh sách các lỗi có thể xảy ra:

### 1. ⚠️ **Hot Reload không hoạt động**
**Triệu chứng:** Code đã thay đổi nhưng UI không cập nhật

**Giải pháp:**
```bash
# Trong terminal đang chạy flutter run, nhấn:
R  # Hot Restart (khởi động lại app)
# Hoặc
r  # Hot Reload (nếu chỉ thay đổi UI nhỏ)
```

**Hoặc dừng và chạy lại:**
```bash
# Dừng app (Ctrl+C)
flutter run
```

---

### 2. 🔄 **App đang chạy version cũ từ cache**
**Triệu chứng:** Thay đổi không được compile

**Giải pháp:**
```bash
# Xóa build cache
flutter clean
flutter pub get
flutter run
```

---

### 3. ❌ **Lỗi compile nhưng không hiển thị rõ**
**Triệu chứng:** App không chạy hoặc crash ngay khi mở

**Giải pháp:**
```bash
# Kiểm tra lỗi compile
flutter analyze

# Hoặc build để xem lỗi chi tiết
flutter build apk --debug  # Android
flutter build ios --debug   # iOS
flutter build windows      # Windows
```

---

### 4. 📱 **Đang xem màn hình khác (không phải Login/Register/Checkout)**
**Triệu chứng:** Đang ở màn hình Home/Dashboard, không thấy form

**Giải pháp:**
- Điều hướng đến màn hình Login: `/login`
- Điều hướng đến màn hình Register: `/register`
- Điều hướng đến màn hình Checkout: `/checkout` (cần có sản phẩm trong giỏ)

---

### 5. 🎯 **Import path sai**
**Triệu chứng:** Lỗi "Target of URI doesn't exist"

**Kiểm tra:**
```dart
// Trong login_screen.dart, register_screen.dart, checkout_screen.dart
import '../../widgets/inputs/custom_text_field.dart';
```

**Giải pháp:**
- Đảm bảo file `custom_text_field.dart` tồn tại tại:
  `lib/src/presentation/widgets/inputs/custom_text_field.dart`

---

### 6. 🎨 **AppColors.border không tồn tại**
**Triệu chứng:** Lỗi "The getter 'border' isn't defined"

**Kiểm tra:**
```dart
// Trong app_colors.dart phải có:
static const Color border = Color(0xFFE0E0E0);
```

**Giải pháp:**
- Kiểm tra file `lib/src/presentation/config/themes/app_colors.dart`
- Đảm bảo có đầy đủ: `primary`, `error`, `surface`, `border`

---

### 7. 🔌 **Device/Emulator không kết nối**
**Triệu chứng:** App không chạy trên device

**Giải pháp:**
```bash
# Kiểm tra devices
flutter devices

# Chọn device cụ thể
flutter run -d windows
flutter run -d chrome
flutter run -d <device-id>
```

---

### 8. 🧹 **Build cache bị lỗi**
**Triệu chứng:** Thay đổi không được áp dụng dù đã hot restart

**Giải pháp:**
```bash
# Xóa toàn bộ cache
flutter clean
cd android && ./gradlew clean && cd ..  # Nếu là Android
flutter pub get
flutter run
```

---

### 9. 📦 **Dependencies chưa được cài đặt**
**Triệu chứng:** Lỗi import hoặc class không tìm thấy

**Giải pháp:**
```bash
flutter pub get
flutter pub upgrade
```

---

### 10. 🔍 **Đang chạy trên Web (mongo_dart không hỗ trợ)**
**Triệu chứng:** App crash khi khởi động trên web

**Giải pháp:**
- Chạy trên Desktop (Windows/Mac/Linux) hoặc Mobile
- Hoặc tạm thời comment code MongoDB khi test UI

---

## ✅ **Các bước kiểm tra nhanh:**

1. **Kiểm tra file tồn tại:**
   ```bash
   ls lib/src/presentation/widgets/inputs/custom_text_field.dart
   ```

2. **Kiểm tra import:**
   ```bash
   grep -r "custom_text_field" lib/src/presentation/screens/
   ```

3. **Kiểm tra lỗi compile:**
   ```bash
   flutter analyze
   ```

4. **Hot Restart:**
   - Trong terminal: Nhấn `R`
   - Hoặc dừng và chạy lại `flutter run`

5. **Kiểm tra màn hình đang xem:**
   - Đảm bảo đang ở `/login`, `/register`, hoặc `/checkout`

---

## 🚀 **Giải pháp nhanh nhất:**

```bash
# 1. Dừng app (Ctrl+C)
# 2. Clean và rebuild
flutter clean
flutter pub get
flutter run
```

---

## 📝 **Ghi chú:**

- **Hot Reload (r)**: Chỉ áp dụng cho thay đổi UI nhỏ, không reload state
- **Hot Restart (R)**: Khởi động lại app, áp dụng mọi thay đổi
- **Full Restart**: Dừng và chạy lại `flutter run`, đảm bảo 100% thay đổi được áp dụng

---

## 🐛 **Nếu vẫn không được:**

1. Kiểm tra console output khi chạy `flutter run`
2. Kiểm tra DevTools (F12 trên web, hoặc `flutter pub global run devtools`)
3. Kiểm tra log trong terminal
4. Thử chạy trên device/emulator khác

