# 🛒 Ecommerce App - Ứng dụng Mua Sắm Trực Tuyến

Ứng dụng e-commerce Flutter được thiết kế dành cho phụ huynh mua sắm cho con cái, với giao diện thân thiện và đầy đủ tính năng quản lý sản phẩm, giỏ hàng, thanh toán và đơn hàng.

## ✨ Tính năng chính

### 👤 Quản lý người dùng
- **Đăng ký / Đăng nhập**: Xác thực người dùng với MongoDB
- **Quản lý hồ sơ**: Chỉnh sửa thông tin cá nhân (tên, địa chỉ, số điện thoại)
- **Dark Mode**: Chế độ tối để bảo vệ mắt

### 🛍️ Mua sắm
- **Trang chủ**: Banner slider tự động, danh mục sản phẩm, sản phẩm nổi bật
- **Tìm kiếm thông minh**:
  - Debounce để tối ưu hiệu suất
  - Auto-suggest từ khóa
  - Lịch sử tìm kiếm
- **Lọc theo danh mục**: Quần áo, Đồ chơi, Giày dép, Sách vở, Đồ dùng học tập, Phụ kiện, Đồ chơi giáo dục
- **Chi tiết sản phẩm**: Xem thông tin, hình ảnh, giá, đánh giá
- **Giỏ hàng**: 
  - Chọn từng sản phẩm để thanh toán
  - Chọn tất cả / Bỏ chọn tất cả
  - Cập nhật số lượng, xóa sản phẩm

### 💳 Thanh toán
- **Phương thức vận chuyển**:
  - Cơ bản (5-7 ngày): 1,000 VND/km
  - Nhanh (3-4 ngày): 2,000 VND/km
  - Hỏa tốc (1-2 ngày): 5,000 VND/km
- **Phương thức thanh toán**:
  - Thanh toán khi nhận hàng (COD)
  - Ví MoMo
  - Chuyển khoản ngân hàng (VietQR)
  - Thẻ quốc tế (Visa/Mastercard)

### 📦 Quản lý đơn hàng
- **Lịch sử đơn hàng**: Xem tất cả đơn hàng đã đặt
- **Trạng thái đơn hàng**: Tự động cập nhật (Chờ xác nhận → Đang giao → Giao thành công)

### 👨‍💼 Quản trị viên
- **Quản lý sản phẩm**:
  - Thêm sản phẩm mới (tên, giá, mô tả, hình ảnh, danh mục, số lượng tồn kho)
  - Chỉnh sửa sản phẩm
  - Xóa sản phẩm (tự động xóa ảnh trên Cloudinary)
- **Upload ảnh**: Tích hợp Cloudinary để lưu trữ và tối ưu hình ảnh

### 🎨 Giao diện
- **Skeleton Loading**: Hiệu ứng shimmer khi tải dữ liệu
- **Responsive Design**: Tối ưu cho mobile, tablet và desktop
- **Empty State**: Thông báo thân thiện khi không có dữ liệu

## 🛠️ Công nghệ sử dụng

### Frontend
- **Flutter** (SDK ^3.9.2)
- **State Management**: BLoC Pattern (`flutter_bloc`)
- **Routing**: `go_router`
- **UI Components**: Material Design 3
- **Image Loading**: `cached_network_image`
- **Fonts**: Google Fonts

### Backend & Services
- **Database**: MongoDB Atlas (`mongo_dart`)
- **Image Storage**: Cloudinary
- **Local Storage**: `shared_preferences`, `flutter_secure_storage`
- **HTTP Client**: `dio`, `http`

### Utilities
- **Dependency Injection**: `get_it`
- **Environment Variables**: `flutter_dotenv`
- **Cryptography**: `crypto` (SHA-256 cho password hashing)
- **Image Picker**: `image_picker`
- **Connectivity**: `connectivity_plus`

## 📋 Yêu cầu hệ thống

- Flutter SDK >= 3.9.2
- Dart SDK >= 3.9.2
- MongoDB Atlas account (hoặc MongoDB local)
- Cloudinary account
- Android Studio / Xcode (cho mobile development)
- VS Code / Android Studio (IDE)

## 🚀 Cài đặt

### 1. Clone repository

```bash
git clone <repository-url>
cd ecommerce
```

### 2. Cài đặt dependencies

```bash
flutter pub get
```

### 3. Cấu hình Environment Variables

Tạo file `.env` trong thư mục `ecommerce/` với nội dung:

```env
# MongoDB Connection String
MONGO_CONNECTION_STRING=mongodb+srv://username:password@cluster.mongodb.net/database?retryWrites=true&w=majority

# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
CLOUDINARY_UPLOAD_PRESET=your_upload_preset

# VietQR Configuration (Optional - cho thanh toán QR)
VIETQR_BANK_CODE=970422
VIETQR_ACCOUNT_NO=your_account_number
VIETQR_ACCOUNT_NAME=your_account_name
```

### 4. Chạy ứng dụng

```bash
# Chạy trên Android/iOS
flutter run

# Chạy trên Web
flutter run -d chrome

# Build APK
flutter build apk --release
```

## 📁 Cấu trúc dự án

```
ecommerce/
├── lib/
│   ├── main.dart                    # Entry point
│   └── src/
│       ├── core/                    # Core services & utilities
│       │   ├── constants/          # App constants
│       │   ├── errors/              # Error handling
│       │   ├── injection/          # Dependency injection
│       │   ├── services/           # Services (MongoDB, Cloudinary, Storage)
│       │   └── utils/               # Utilities
│       ├── data/                    # Data layer
│       │   ├── datasources/         # Data sources
│       │   ├── models/              # Data models
│       │   └── repositories/        # Repository pattern
│       ├── logic/                   # Business logic (BLoC)
│       │   ├── auth/                # Authentication BLoC
│       │   ├── cart/                # Cart BLoC
│       │   ├── product/            # Product BLoC
│       │   └── theme/               # Theme BLoC
│       └── presentation/            # UI layer
│           ├── config/              # App configuration
│           │   ├── routes/          # Routing
│           │   └── themes/          # App themes
│           ├── screens/            # App screens
│           │   ├── admin/          # Admin screens
│           │   ├── auth/           # Auth screens
│           │   ├── cart/           # Cart screen
│           │   ├── checkout/      # Checkout screens
│           │   ├── home/           # Home screen & widgets
│           │   ├── orders/        # Order history
│           │   ├── payment/       # Payment screens
│           │   ├── product_detail/ # Product detail
│           │   └── profile/        # Profile screens
│           └── widgets/           # Reusable widgets
├── assets/                          # Assets (images, fonts, translations)
├── .env                             # Environment variables (không commit)
└── pubspec.yaml                     # Dependencies
```

## 🎯 Hướng dẫn sử dụng

### Đăng ký / Đăng nhập
1. Mở ứng dụng, chọn "Đăng ký" hoặc "Đăng nhập"
2. Nhập email và mật khẩu
3. Nếu đăng ký, điền thêm thông tin cá nhân

### Mua sắm
1. Trang chủ hiển thị banner, danh mục và sản phẩm
2. Chọn danh mục để lọc sản phẩm
3. Sử dụng thanh tìm kiếm để tìm sản phẩm
4. Nhấn vào sản phẩm để xem chi tiết
5. Thêm vào giỏ hàng

### Thanh toán
1. Vào giỏ hàng, chọn sản phẩm muốn mua
2. Nhấn "Thanh toán"
3. Chọn phương thức vận chuyển
4. Chọn phương thức thanh toán
5. Nhấn "Đặt hàng"
6. Hoàn tất thanh toán (nếu cần)
7. Xem màn hình cảm ơn

### Quản trị (Admin)
1. Đăng nhập với tài khoản có role = "admin"
2. Vào trang quản lý sản phẩm
3. Thêm/Sửa/Xóa sản phẩm
4. Upload hình ảnh từ gallery hoặc camera

### Xem lịch sử đơn hàng
1. Vào trang "Hồ sơ"
2. Nhấn "Đơn hàng của tôi"
3. Xem danh sách đơn hàng và trạng thái

## 🔒 Bảo mật

- Password được hash bằng SHA-256 trước khi lưu vào database
- Sử dụng `flutter_secure_storage` cho dữ liệu nhạy cảm
- Environment variables được lưu trong `.env` (không commit vào Git)

## 🐛 Xử lý lỗi

### Lỗi kết nối MongoDB
- Kiểm tra `MONGO_CONNECTION_STRING` trong file `.env`
- Đảm bảo IP whitelist trên MongoDB Atlas đã thêm IP của bạn
- Kiểm tra network connection

### Lỗi upload ảnh
- Kiểm tra Cloudinary credentials trong `.env`
- Đảm bảo file ảnh không vượt quá 10MB (giới hạn Cloudinary free tier)

### Lỗi build
- Chạy `flutter clean` và `flutter pub get`
- Đảm bảo Flutter SDK version đúng
- Kiểm tra `pubspec.yaml` dependencies

## 📝 Ghi chú

- Dự án sử dụng MongoDB Atlas (cloud database), không cần cài đặt MongoDB local
- Cloudinary free tier có giới hạn 10MB/file và 25GB storage
- Thanh toán hiện tại là simulation (demo), chưa tích hợp thực tế
- Order status simulation tự động cập nhật sau mỗi 10-20 giây

## 🤝 Đóng góp

Mọi đóng góp đều được chào đón! Vui lòng:
1. Fork repository
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Dự án này được phát triển cho mục đích học tập và demo.

## 👨‍💻 Tác giả

Phát triển bởi [Tên của bạn]

---

**Lưu ý**: Đây là dự án demo/đồ án, một số tính năng có thể chưa hoàn thiện hoặc chỉ ở mức simulation.

