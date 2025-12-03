# 📊 MongoDB Collections trong dự án E-commerce

## 📋 Danh sách Collections

Dự án này sử dụng **3 collections** chính trong MongoDB:

1. **`users`** - Lưu thông tin người dùng
2. **`products`** - Lưu thông tin sản phẩm
3. **`orders`** - Lưu thông tin đơn hàng

---

## 1. Collection: `users`

### Mô tả
Lưu trữ thông tin tài khoản người dùng, bao gồm email, password (đã hash), thông tin cá nhân.

### Cấu trúc Document

```json
{
  "_id": ObjectId("..."),           // MongoDB tự động tạo
  "email": "user@example.com",      // String, REQUIRED, UNIQUE
  "password": "hashed_password",     // String, REQUIRED (SHA-256 hash)
  "fullName": "Nguyễn Văn A",       // String, REQUIRED
  "address": "123 Đường ABC",       // String, REQUIRED
  "phone": "0123456789",            // String, OPTIONAL
  "createdAt": "2025-12-02T22:42:37.762782"  // String (ISO 8601)
}
```

### Indexes (Khuyến nghị)

```javascript
// Tạo unique index cho email để đảm bảo email không trùng lặp
db.users.createIndex({ "email": 1 }, { unique: true })

// Index cho tìm kiếm nhanh
db.users.createIndex({ "email": 1 })
```

### Ví dụ Document

```json
{
  "_id": ObjectId("507f1f77bcf86cd799439011"),
  "email": "luankkk1@gmail.com",
  "password": "96cae35ce8a9b0244178bf28e4966c2ce1b8385723a96a6b838858cdd6ca0a1e",
  "fullName": "Hoàng Luân",
  "address": "111 Hòa Hải",
  "createdAt": "2025-12-02T22:42:37.762782"
}
```

---

## 2. Collection: `products`

### Mô tả
Lưu trữ thông tin sản phẩm trong cửa hàng, bao gồm tên, giá, mô tả, hình ảnh, danh mục, v.v.

### Cấu trúc Document

```json
{
  "_id": ObjectId("..."),                    // MongoDB tự động tạo
  "name": "iPhone 15 Pro",                   // String, REQUIRED
  "price": 29990000,                         // Number (Double), REQUIRED
  "originalPrice": 32990000,                 // Number (Double), OPTIONAL
  "imageUrl": "https://...",                 // String, REQUIRED
  "images": ["https://...", "https://..."],  // Array<String>, OPTIONAL
  "description": "Mô tả ngắn",              // String, OPTIONAL
  "longDescription": "Mô tả chi tiết...",   // String, OPTIONAL
  "shortDescription": "Mô tả ngắn",         // String, OPTIONAL
  "categoryId": "category_id_123",          // String, OPTIONAL
  "categoryName": "Điện thoại",             // String, OPTIONAL
  "discountPercent": 10,                     // Number (Double), OPTIONAL
  "discountStartDate": "2025-01-01",        // String (ISO 8601), OPTIONAL
  "discountEndDate": "2025-12-31",          // String (ISO 8601), OPTIONAL
  "soldCount": 150,                         // Number (Int), OPTIONAL, default: 0
  "featured": true,                         // Boolean, OPTIONAL, default: false
  "rating": 4.5,                            // Number (Double), OPTIONAL, default: 0
  "ratingCount": 25,                        // Number (Int), OPTIONAL, default: 0
  "viewCount": 500,                         // Number (Int), OPTIONAL, default: 0
  "stock": 50,                              // Number (Int), OPTIONAL, default: 0
  "minStock": 10,                           // Number (Int), OPTIONAL, default: 0
  "inStock": true,                          // Boolean, OPTIONAL, default: true
  "status": "active",                       // String, OPTIONAL: "active", "inactive", "out_of_stock"
  "brand": "Apple",                         // String, OPTIONAL
  "sku": "IP15PRO-256-BLK",                // String, OPTIONAL
  "barcode": "1234567890123",              // String, OPTIONAL
  "weight": 0.5,                           // Number (Double), OPTIONAL (kg)
  "length": 10,                            // Number (Double), OPTIONAL (cm)
  "width": 5,                              // Number (Double), OPTIONAL (cm)
  "height": 2,                             // Number (Double), OPTIONAL (cm)
  "tags": ["smartphone", "apple", "premium"], // Array<String>, OPTIONAL
  "colors": ["Đen", "Trắng", "Vàng"],       // Array<String>, OPTIONAL
  "sizes": ["64GB", "128GB", "256GB"],     // Array<String>, OPTIONAL
  "createdAt": "2025-01-01T00:00:00.000Z", // String (ISO 8601), OPTIONAL
  "updatedAt": "2025-01-01T00:00:00.000Z", // String (ISO 8601), OPTIONAL
  "publishedAt": "2025-01-01T00:00:00.000Z" // String (ISO 8601), OPTIONAL
}
```

### Indexes (Khuyến nghị)

```javascript
// Index cho tìm kiếm theo tên
db.products.createIndex({ "name": 1 })

// Index cho tìm kiếm theo danh mục
db.products.createIndex({ "categoryId": 1 })

// Index cho sắp xếp theo giá
db.products.createIndex({ "price": 1 })

// Index cho sắp xếp theo rating
db.products.createIndex({ "rating": -1 })

// Index cho sắp xếp theo số lượng bán
db.products.createIndex({ "soldCount": -1 })

// Index cho sản phẩm nổi bật
db.products.createIndex({ "featured": 1 })

// Index cho tìm kiếm text (full-text search)
db.products.createIndex({ 
  "name": "text", 
  "description": "text", 
  "tags": "text" 
})

// Compound index cho filter phức tạp
db.products.createIndex({ 
  "categoryId": 1, 
  "price": 1, 
  "inStock": 1 
})
```

---

## 3. Collection: `orders`

### Mô tả
Lưu trữ thông tin đơn hàng, bao gồm thông tin khách hàng, sản phẩm, tổng tiền, trạng thái đơn hàng.

### Cấu trúc Document

```json
{
  "_id": ObjectId("..."),                    // MongoDB tự động tạo
  "orderNumber": "ORD-20251202-001",         // String, REQUIRED (unique)
  "userId": "user_id_123",                   // String, OPTIONAL
  "customerName": "Nguyễn Văn A",            // String, REQUIRED
  "customerPhone": "0123456789",             // String, REQUIRED
  "customerAddress": "123 Đường ABC",        // String, REQUIRED
  "customerEmail": "customer@example.com",   // String, OPTIONAL
  "note": "Giao hàng vào buổi sáng",         // String, OPTIONAL
  "adminNote": "Ghi chú của admin",          // String, OPTIONAL
  "items": [                                  // Array<Object>, REQUIRED
    {
      "id": "cart_item_id_123",
      "productId": "product_id_456",
      "product": {                            // ProductModel (nested)
        "id": "product_id_456",
        "name": "iPhone 15 Pro",
        "price": 29990000,
        "imageUrl": "https://..."
      },
      "quantity": 2,
      "color": "Đen",
      "size": "256GB",
      "category": "Điện thoại"
    }
  ],
  "subtotal": 59980000,                      // Number (Double), REQUIRED
  "shippingFee": 30000,                      // Number (Double), OPTIONAL, default: 0
  "discount": 0,                             // Number (Double), OPTIONAL, default: 0
  "totalAmount": 60010000,                   // Number (Double), REQUIRED
  "paymentMethod": "cod",                    // String, OPTIONAL: "cod", "banking", "card"
  "paymentStatus": "pending",                // String, OPTIONAL: "pending", "paid", "failed", "refunded"
  "shippingMethod": "standard",              // String, OPTIONAL: "standard", "express", "overnight"
  "trackingNumber": "VN123456789",           // String, OPTIONAL
  "status": "pending",                        // String, REQUIRED: "pending", "confirmed", "processing", "shipped", "delivered", "cancelled"
  "createdAt": "2025-12-02T22:42:37.762782", // String (ISO 8601), REQUIRED
  "confirmedAt": null,                       // String (ISO 8601) | null, OPTIONAL
  "shippedAt": null,                         // String (ISO 8601) | null, OPTIONAL
  "deliveredAt": null,                       // String (ISO 8601) | null, OPTIONAL
  "cancelledAt": null,                       // String (ISO 8601) | null, OPTIONAL
  "updatedAt": "2025-12-02T22:42:37.762782" // String (ISO 8601), OPTIONAL
}
```

### Indexes (Khuyến nghị)

```javascript
// Index cho tìm kiếm theo order number (unique)
db.orders.createIndex({ "orderNumber": 1 }, { unique: true })

// Index cho tìm kiếm theo user
db.orders.createIndex({ "userId": 1 })

// Index cho tìm kiếm theo email khách hàng
db.orders.createIndex({ "customerEmail": 1 })

// Index cho sắp xếp theo ngày tạo
db.orders.createIndex({ "createdAt": -1 })

// Index cho filter theo trạng thái
db.orders.createIndex({ "status": 1 })

// Index cho filter theo trạng thái thanh toán
db.orders.createIndex({ "paymentStatus": 1 })

// Compound index cho query phức tạp
db.orders.createIndex({ 
  "userId": 1, 
  "status": 1, 
  "createdAt": -1 
})
```

---

## 🚀 Cách tạo Collections trong MongoDB Atlas

### Cách 1: Tạo thủ công (Khuyến nghị)

1. **Đăng nhập MongoDB Atlas:**
   - Vào https://cloud.mongodb.com
   - Chọn cluster của bạn

2. **Tạo Database:**
   - Click **"Browse Collections"**
   - Click **"Create Database"**
   - Database Name: `ecommerce` (hoặc tên bạn muốn)
   - Collection Name: `users` (hoặc `products`, `orders`)
   - Click **"Create"**

3. **Lặp lại cho các collection còn lại:**
   - `products`
   - `orders`

### Cách 2: Tạo bằng MongoDB Shell

```javascript
// Kết nối đến database
use ecommerce

// Tạo collection users (MongoDB tự động tạo khi insert đầu tiên)
// Nhưng có thể tạo trước với validation schema

// Tạo collection products
db.createCollection("products")

// Tạo collection orders
db.createCollection("orders")
```

### Cách 3: Tạo bằng MongoDB Compass

1. Mở MongoDB Compass
2. Kết nối đến cluster
3. Chọn database `ecommerce`
4. Click **"Create Collection"**
5. Nhập tên collection và tạo

---

## 📝 Tạo Indexes

Sau khi tạo collections, hãy tạo indexes để tối ưu hiệu suất:

### Trong MongoDB Atlas:

1. Vào **"Browse Collections"**
2. Chọn collection (ví dụ: `users`)
3. Click tab **"Indexes"**
4. Click **"Create Index"**
5. Nhập index definition (ví dụ: `{ "email": 1 }`)
6. Chọn **"Unique"** nếu cần (cho email)
7. Click **"Create"**

### Hoặc dùng MongoDB Shell:

```javascript
use ecommerce

// Indexes cho users
db.users.createIndex({ "email": 1 }, { unique: true })

// Indexes cho products
db.products.createIndex({ "name": 1 })
db.products.createIndex({ "categoryId": 1 })
db.products.createIndex({ "price": 1 })
db.products.createIndex({ "rating": -1 })
db.products.createIndex({ "featured": 1 })

// Indexes cho orders
db.orders.createIndex({ "orderNumber": 1 }, { unique: true })
db.orders.createIndex({ "userId": 1 })
db.orders.createIndex({ "status": 1 })
db.orders.createIndex({ "createdAt": -1 })
```

---

## ⚠️ Lưu ý

1. **MongoDB tự động tạo collection:** Nếu collection chưa tồn tại, MongoDB sẽ tự động tạo khi bạn insert document đầu tiên. Tuy nhiên, tạo thủ công giúp bạn có thể set validation schema và indexes ngay từ đầu.

2. **Indexes quan trọng:** Indexes giúp tăng tốc độ query đáng kể, đặc biệt với collections lớn. Hãy tạo indexes cho các field thường xuyên được query.

3. **Unique Indexes:** Đảm bảo tạo unique index cho `email` trong `users` và `orderNumber` trong `orders` để tránh duplicate.

4. **Validation Schema (Tùy chọn):** Bạn có thể tạo validation schema để đảm bảo dữ liệu đúng format, nhưng điều này không bắt buộc.

---

## ✅ Checklist

- [ ] Tạo database `ecommerce`
- [ ] Tạo collection `users`
- [ ] Tạo collection `products`
- [ ] Tạo collection `orders`
- [ ] Tạo unique index cho `users.email`
- [ ] Tạo indexes cho `products` (name, categoryId, price, rating, featured)
- [ ] Tạo unique index cho `orders.orderNumber`
- [ ] Tạo indexes cho `orders` (userId, status, createdAt)

---

Sau khi tạo xong các collections và indexes, bạn có thể chạy lại app và thử đăng ký tài khoản!

