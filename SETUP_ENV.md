# 🔧 Hướng dẫn setup .env

## ✅ Đã cập nhật code

Code đã được cập nhật để đọc connection string từ file `.env` thay vì hardcode.

## 📝 Bước 1: Tạo file .env

Tạo file `.env` ở thư mục root của project (`ecommerce/.env`) với nội dung:

```env
MONGO_CONNECTION_STRING=mongodb+srv://xuntho:120104@products.blsi64a.mongodb.net/
```

## 📝 Bước 2: Kiểm tra .gitignore

File `.env` đã được thêm vào `.gitignore` để không commit lên Git.

## 📝 Bước 3: Chạy lại app

```bash
flutter run -d windows
```

## 🔍 Kiểm tra

Khi app chạy, bạn sẽ thấy trong console:
- `✅ Đã load file .env thành công` → OK
- `⚠️ Không thể load file .env: ...` → Cần tạo file .env

## 📋 File .env.example

Đã tạo file `.env.example` làm mẫu. Bạn có thể:
1. Copy `.env.example` thành `.env`
2. Điền thông tin thật của bạn

## 🔒 Bảo mật

⚠️ **QUAN TRỌNG:**
- File `.env` đã được thêm vào `.gitignore`
- **KHÔNG** commit file `.env` lên Git
- Chỉ commit file `.env.example` (không có thông tin nhạy cảm)

## 🎯 Lợi ích

✅ Bảo mật hơn (không hardcode connection string)
✅ Dễ quản lý (thay đổi không cần sửa code)
✅ Hỗ trợ nhiều môi trường (dev, staging, production)

