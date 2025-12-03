import 'dart:developer';
import 'dart:io' show Platform;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../../data/models/product_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/cart_item_model.dart';
import '../injection/service_locator.dart';
import 'cloudinary_service.dart';

/// MongoService - Service quản lý kết nối và thao tác với MongoDB
///
/// Sử dụng Singleton pattern để đảm bảo chỉ có 1 kết nối duy nhất
/// Tích hợp với get_it để dependency injection
class MongoService {
  // ============================================
  // Singleton Pattern
  // ============================================
  static final MongoService _instance = MongoService._internal();
  factory MongoService() => _instance;
  MongoService._internal();

  // ============================================
  // Connection Management
  // ============================================
  static Db? _db;
  bool _isConnecting = false;

  /// Lấy connection string từ environment variables (.env)
  ///
  /// Nếu không tìm thấy trong .env, sẽ dùng giá trị mặc định
  static String get _connString {
    final envConnString = dotenv.env['MONGO_CONNECTION_STRING'];

    if (envConnString != null && envConnString.isNotEmpty) {
      return envConnString;
    }

    // Fallback nếu không có trong .env (cho development)
    // ⚠️ Cảnh báo: Đang dùng connection string mặc định
    log(
      "⚠️ Không tìm thấy MONGO_CONNECTION_STRING trong .env, sử dụng giá trị mặc định",
    );
    print("⚠️ CẢNH BÁO: Đang dùng connection string mặc định (hardcode)");
    print(
      "📝 Vui lòng tạo file .env với MONGO_CONNECTION_STRING để bảo mật hơn",
    );
    // Giá trị mặc định (chỉ dùng khi không có .env)
    // ⚠️ QUAN TRỌNG: Phải có database name trong connection string!
    return "mongodb+srv://xuntho:120104@products.blsi64a.mongodb.net/ecommerce?retryWrites=true&w=majority";
  }

  // ==================== ========================
  // Connection Methods
  // ============================================

  /// Kết nối đến MongoDB
  ///
  /// [retryCount]: Số lần thử lại nếu kết nối thất bại (mặc định: 3)
  /// [retryDelay]: Thời gian chờ giữa các lần thử lại (mặc định: 2 giây)
  ///
  /// ⚠️ LƯU Ý: mongo_dart KHÔNG hỗ trợ Flutter Web!
  /// Chỉ hoạt động trên Mobile (Android/iOS) và Desktop (Windows/Mac/Linux)
  Future<void> connect({
    int retryCount = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    // Kiểm tra platform - mongo_dart không hỗ trợ web
    try {
      final isWeb =
          !Platform.isAndroid &&
          !Platform.isIOS &&
          !Platform.isWindows &&
          !Platform.isMacOS &&
          !Platform.isLinux;
      if (isWeb) {
        log("❌ mongo_dart KHÔNG hỗ trợ Flutter Web!");
        log("💡 Giải pháp:");
        log("   1. Chạy trên Desktop: flutter run -d windows");
        log("   2. Hoặc tạo REST API backend để kết nối MongoDB");
        log("   3. Hoặc sử dụng MongoDB Atlas Data API (HTTP-based)");
        throw UnsupportedError(
          'mongo_dart không hỗ trợ Flutter Web. '
          'Vui lòng chạy trên Desktop/Mobile hoặc sử dụng REST API backend.',
        );
      }
    } catch (e) {
      // Nếu không thể detect platform (có thể là web), throw error
      if (e.toString().contains('Platform._operatingSystem') ||
          e.toString().contains('Unsupported operation')) {
        log("❌ mongo_dart KHÔNG hỗ trợ Flutter Web!");
        log("💡 Giải pháp:");
        log("   1. Chạy trên Desktop: flutter run -d windows");
        log("   2. Hoặc tạo REST API backend để kết nối MongoDB");
        log("   3. Hoặc sử dụng MongoDB Atlas Data API (HTTP-based)");
        throw UnsupportedError(
          'mongo_dart không hỗ trợ Flutter Web. '
          'Vui lòng chạy trên Desktop/Mobile hoặc sử dụng REST API backend.',
        );
      }
      rethrow;
    }
    // Tránh kết nối đồng thời nhiều lần
    if (_isConnecting) {
      log("⚠️ Đang kết nối, vui lòng đợi...");
      return;
    }

    // Nếu đã kết nối, không cần kết nối lại
    if (_db != null && _db!.isConnected) {
      log("✅ Đã kết nối MongoDB");
      return;
    }

    _isConnecting = true;

    for (int attempt = 1; attempt <= retryCount; attempt++) {
      try {
        log("🔄 Đang kết nối MongoDB... (Lần thử: $attempt/$retryCount)");
        print("🔄 Đang kết nối MongoDB... (Lần thử: $attempt/$retryCount)");

        _db = await Db.create(_connString);
        await _db!.open();

        log("✅ KẾT NỐI MONGODB THÀNH CÔNG!");
        print("✅ KẾT NỐI MONGODB THÀNH CÔNG!");
        print("📊 Database: ${_db!.databaseName}");
        print(
          "📊 Connection string: ${_connString.replaceAll(RegExp(r':[^@]+@'), ':****@')}",
        ); // Ẩn password
        print(
          "📊 Connection state: ${_db!.isConnected ? 'Connected' : 'Not connected'}",
        );

        // Kiểm tra database name
        final dbName = _db!.databaseName;
        if (dbName == null || dbName.isEmpty) {
          log(
            "⚠️ CẢNH BÁO: Database name trống! Connection string có thể thiếu database name.",
          );
          print("⚠️ CẢNH BÁO: Database name trống!");
          print(
            "💡 Hãy thêm database name vào connection string, ví dụ: ...mongodb.net/ecommerce",
          );
        }

        _isConnecting = false;
        return;
      } catch (e, stackTrace) {
        log("❌ Lỗi kết nối MongoDB (Lần thử $attempt/$retryCount): $e");
        log("📍 Stack trace: $stackTrace");
        print("❌ Lỗi kết nối MongoDB (Lần thử $attempt/$retryCount): $e");

        // Nếu không phải lần thử cuối, đợi rồi thử lại
        if (attempt < retryCount) {
          log("⏳ Đợi ${retryDelay.inSeconds} giây trước khi thử lại...");
          print("⏳ Đợi ${retryDelay.inSeconds} giây trước khi thử lại...");
          await Future.delayed(retryDelay);
        } else {
          _isConnecting = false;
          // Log chi tiết lỗi cuối cùng
          log("❌❌❌ KHÔNG THỂ KẾT NỐI MONGODB SAU $retryCount LẦN THỬ ❌❌❌");
          log("📋 Chi tiết lỗi: $e");
          log("🔍 Kiểm tra:");
          // Ẩn password trong log để bảo mật
          final maskedConnString = _connString.replaceAll(
            RegExp(r':[^@]+@'),
            ':****@',
          );
          log("   1. Connection string: $maskedConnString");
          log("   2. Username/password có đúng không?");
          log("   3. IP đã được whitelist trong MongoDB Atlas chưa?");
          log("   4. Cluster có đang hoạt động không?");
          print("❌❌❌ KHÔNG THỂ KẾT NỐI MONGODB SAU $retryCount LẦN THỬ ❌❌❌");
          print("📋 Chi tiết lỗi: $e");
          print("🔍 Kiểm tra:");
          print("   1. Connection string trong file .env có đúng không?");
          print("   2. Username/password có đúng không?");
          print("   3. IP đã được whitelist trong MongoDB Atlas chưa?");
          print("   4. Cluster có đang hoạt động không?");
          rethrow; // Ném lỗi nếu đã hết số lần thử
        }
      }
    }
  }

  /// Kiểm tra trạng thái kết nối
  bool get isConnected => _db != null && _db!.isConnected;

  /// Đóng kết nối MongoDB
  Future<void> disconnect() async {
    if (_db != null && _db!.isConnected) {
      try {
        await _db!.close();
        log("✅ Đã đóng kết nối MongoDB");
      } catch (e) {
        log("❌ Lỗi khi đóng kết nối: $e");
      } finally {
        _db = null;
      }
    }
  }

  /// Kiểm tra health của database connection
  Future<bool> healthCheck() async {
    if (!isConnected) return false;

    try {
      // Thực hiện một query đơn giản để kiểm tra
      await _db!.collection('products').find().take(1).toList();
      return true;
    } catch (e) {
      log("❌ Health check thất bại: $e");
      return false;
    }
  }

  // ============================================
  // Product Methods
  // ============================================

  /// Lấy danh sách sản phẩm với đầy đủ tính năng filtering, sorting, pagination
  ///
  /// [limit]: Giới hạn số lượng sản phẩm (null = không giới hạn)
  /// [skip]: Bỏ qua số lượng sản phẩm (cho pagination)
  /// [sortBy]: Sắp xếp theo field nào (ví dụ: 'price', 'createdAt', 'rating')
  /// [sortOrder]: Thứ tự sắp xếp (1 = tăng dần, -1 = giảm dần)
  /// [categoryId]: Lọc theo danh mục
  /// [minPrice]: Giá tối thiểu
  /// [maxPrice]: Giá tối đa
  /// [inStock]: Chỉ lấy sản phẩm còn hàng
  /// [featured]: Chỉ lấy sản phẩm nổi bật
  /// [status]: Lọc theo trạng thái ('active', 'inactive', 'out_of_stock')
  /// [brand]: Lọc theo thương hiệu
  /// [searchQuery]: Tìm kiếm trong tên, mô tả, tags
  /// [minRating]: Đánh giá tối thiểu (0.0 - 5.0)
  /// [tags]: Lọc theo tags (ít nhất 1 tag khớp)
  /// [colors]: Lọc theo màu sắc (sản phẩm có chứa màu này)
  /// [sizes]: Lọc theo kích cỡ (sản phẩm có chứa size này)
  Future<List<ProductModel>> getProducts({
    int? limit,
    int? skip,
    String? sortBy,
    int? sortOrder,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    bool? featured,
    String? status,
    String? brand,
    String? searchQuery,
    double? minRating,
    List<String>? tags,
    List<String>? colors,
    List<String>? sizes,
  }) async {
    if (!isConnected) {
      log("⚠️ Chưa kết nối MongoDB, đang thử kết nối...");
      await connect();
    }

    if (!isConnected) {
      log("❌ Không thể kết nối MongoDB");
      return [];
    }

    try {
      var collection = _db!.collection('products');

      // Xây dựng query filter
      Map<String, dynamic> query = {};

      // Filter theo danh mục
      if (categoryId != null && categoryId.isNotEmpty) {
        query['categoryId'] = categoryId;
      }

      // Filter theo giá
      if (minPrice != null || maxPrice != null) {
        query['price'] = {};
        if (minPrice != null) {
          query['price']['\$gte'] = minPrice;
        }
        if (maxPrice != null) {
          query['price']['\$lte'] = maxPrice;
        }
      }

      // Filter theo trạng thái tồn kho
      if (inStock != null) {
        if (inStock) {
          // Còn hàng: stock > 0 hoặc status != 'out_of_stock'
          query['\$or'] = [
            {
              'stock': {'\$gt': 0},
            },
            {
              'status': {'\$ne': 'out_of_stock'},
            },
            {'inStock': true},
          ];
        } else {
          // Hết hàng
          query['\$or'] = [
            {
              'stock': {'\$lte': 0},
            },
            {'status': 'out_of_stock'},
            {'inStock': false},
          ];
        }
      }

      // Filter theo featured
      if (featured != null) {
        query['featured'] = featured;
      }

      // Filter theo status
      if (status != null && status.isNotEmpty) {
        query['status'] = status;
      }

      // Filter theo brand
      if (brand != null && brand.isNotEmpty) {
        query['brand'] = brand;
      }

      // Filter theo rating
      if (minRating != null && minRating > 0) {
        query['rating'] = {'\$gte': minRating};
      }

      // Filter theo tags (ít nhất 1 tag khớp)
      if (tags != null && tags.isNotEmpty) {
        query['tags'] = {'\$in': tags};
      }

      // Filter theo colors (sản phẩm có chứa màu này)
      if (colors != null && colors.isNotEmpty) {
        query['colors'] = {'\$in': colors};
      }

      // Filter theo sizes (sản phẩm có chứa size này)
      if (sizes != null && sizes.isNotEmpty) {
        query['sizes'] = {'\$in': sizes};
      }

      // Tìm kiếm trong tên, mô tả, tags
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query['\$or'] = [
          {
            'name': {'\$regex': searchQuery, '\$options': 'i'},
          },
          {
            'description': {'\$regex': searchQuery, '\$options': 'i'},
          },
          {
            'shortDescription': {'\$regex': searchQuery, '\$options': 'i'},
          },
          {
            'tags': {
              '\$in': [searchQuery],
            },
          },
          {
            'brand': {'\$regex': searchQuery, '\$options': 'i'},
          },
        ];
      }

      // Thực hiện query
      var stream = collection.find(query);

      // Áp dụng pagination và limit
      if (skip != null) {
        stream = stream.skip(skip);
      }
      if (limit != null) {
        stream = stream.take(limit);
      }

      List<Map<String, dynamic>> data = await stream.toList();

      // Sort ở application level nếu cần
      // (MongoDB sort có thể được thêm vào query nếu cần tối ưu hơn)
      if (sortBy != null) {
        data.sort((a, b) {
          final aVal = a[sortBy];
          final bVal = b[sortBy];
          if (aVal == null) return 1;
          if (bVal == null) return -1;

          // Xử lý các kiểu dữ liệu khác nhau
          if (aVal is num && bVal is num) {
            final comparison = aVal.compareTo(bVal);
            return sortOrder == -1 ? -comparison : comparison;
          }

          final comparison = (aVal as Comparable).compareTo(bVal);
          return sortOrder == -1 ? -comparison : comparison;
        });
      }

      log("✅ Lấy được ${data.length} sản phẩm");
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e, stackTrace) {
      log("❌ Lỗi lấy danh sách sản phẩm: $e");
      log("📍 Stack trace: $stackTrace");
      return [];
    }
  }

  /// Lấy sản phẩm theo ID
  Future<ProductModel?> getProductById(String productId) async {
    if (!isConnected) {
      await connect();
    }

    if (!isConnected) return null;

    try {
      var collection = _db!.collection('products');
      final data = await collection.findOne({
        '_id': ObjectId.fromHexString(productId),
      });

      if (data == null) return null;

      return ProductModel.fromJson(data);
    } catch (e) {
      log("❌ Lỗi lấy sản phẩm theo ID: $e");
      return null;
    }
  }

  /// Tìm kiếm sản phẩm (wrapper cho getProducts với searchQuery)
  ///
  /// [query]: Từ khóa tìm kiếm
  /// [limit]: Giới hạn số lượng kết quả
  /// [sortBy]: Sắp xếp theo field nào
  /// [sortOrder]: Thứ tự sắp xếp
  Future<List<ProductModel>> searchProducts(
    String query, {
    int? limit,
    String? sortBy,
    int? sortOrder,
  }) async {
    return getProducts(
      searchQuery: query,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  /// Lấy sản phẩm theo danh mục (wrapper cho getProducts với categoryId)
  ///
  /// [categoryId]: ID của danh mục
  /// [limit]: Giới hạn số lượng
  /// [sortBy]: Sắp xếp theo field nào
  /// [sortOrder]: Thứ tự sắp xếp
  Future<List<ProductModel>> getProductsByCategory(
    String categoryId, {
    int? limit,
    String? sortBy,
    int? sortOrder,
  }) async {
    return getProducts(
      categoryId: categoryId,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  /// Lấy sản phẩm nổi bật
  Future<List<ProductModel>> getFeaturedProducts({
    int limit = 10,
    bool? inStock,
  }) async {
    return getProducts(
      limit: limit,
      featured: true,
      sortBy: 'rating',
      sortOrder: -1,
      inStock: inStock,
    );
  }

  /// Lấy sản phẩm phổ biến (theo số lượng bán)
  Future<List<ProductModel>> getPopularProducts({
    int limit = 10,
    bool? inStock,
  }) async {
    return getProducts(
      limit: limit,
      sortBy: 'soldCount',
      sortOrder: -1,
      inStock: inStock,
    );
  }

  /// Lấy sản phẩm mới nhất
  Future<List<ProductModel>> getNewestProducts({
    int limit = 10,
    bool? inStock,
  }) async {
    return getProducts(
      limit: limit,
      sortBy: 'createdAt',
      sortOrder: -1,
      inStock: inStock,
    );
  }

  /// Lấy sản phẩm đang giảm giá
  Future<List<ProductModel>> getOnSaleProducts({
    int limit = 10,
    bool? inStock,
  }) async {
    return getProducts(
      limit: limit,
      sortBy: 'discountPercent',
      sortOrder: -1,
      inStock: inStock,
    );
  }

  /// Thêm sản phẩm mới
  ///
  /// [product]: ProductModel chứa thông tin sản phẩm
  /// Trả về ID của sản phẩm vừa tạo, hoặc null nếu thất bại
  Future<String?> addProduct(ProductModel product) async {
    if (!isConnected) {
      await connect();
    }

    if (!isConnected) {
      log("❌ Không thể thêm sản phẩm: Chưa kết nối MongoDB");
      return null;
    }

    try {
      var collection = _db!.collection('products');

      // Convert ProductModel sang JSON
      final productData = product.toJson();

      // Thêm thời gian tạo nếu chưa có
      if (productData['createdAt'] == null) {
        productData['createdAt'] = DateTime.now().toIso8601String();
      }
      if (productData['updatedAt'] == null) {
        productData['updatedAt'] = DateTime.now().toIso8601String();
      }

      // Insert vào MongoDB
      final result = await collection.insertOne(productData);

      if (result.id != null) {
        final productId = result.id!.toString();
        log("✅ Đã thêm sản phẩm thành công với ID: $productId");
        return productId;
      } else {
        log("❌ Không thể lấy ID của sản phẩm vừa tạo");
        return null;
      }
    } catch (e, stackTrace) {
      log("❌ Lỗi thêm sản phẩm: $e");
      log("📍 Stack trace: $stackTrace");
      return null;
    }
  }

  /// Cập nhật sản phẩm
  ///
  /// [productId]: ID của sản phẩm cần cập nhật
  /// [product]: ProductModel chứa thông tin mới
  /// Trả về true nếu cập nhật thành công, false nếu thất bại
  Future<bool> updateProduct(String productId, ProductModel product) async {
    print("🔄 [SERVICE] updateProduct called: productId=$productId");

    if (!isConnected) {
      await connect();
    }

    if (!isConnected) {
      log("❌ Không thể cập nhật sản phẩm: Chưa kết nối MongoDB");
      print("❌ [SERVICE] Không kết nối MongoDB");
      return false;
    }

    try {
      print("🔄 [SERVICE] Bắt đầu update trong MongoDB...");
      print("🔄 [SERVICE] productId: $productId (length: ${productId.length})");

      var collection = _db!.collection('products');

      // Kiểm tra xem product có tồn tại trong DB không và lấy _id thực tế
      ObjectId actualObjectId;
      try {
        final existingProduct = await collection.findOne({
          '_id': ObjectId.fromHexString(productId),
        });
        if (existingProduct == null) {
          log("⚠️ Không tìm thấy sản phẩm với ID: $productId");
          print(
            "⚠️ [SERVICE] Không tìm thấy sản phẩm trong DB với ID: $productId",
          );
          return false;
        }

        // Lấy _id thực tế từ document để đảm bảo format đúng
        final existingId = existingProduct['_id'];
        if (existingId is ObjectId) {
          actualObjectId = existingId;
        } else if (existingId != null) {
          // Nếu _id là string, convert lại
          actualObjectId = ObjectId.fromHexString(existingId.toString());
        } else {
          actualObjectId = ObjectId.fromHexString(productId);
        }

        print("✅ [SERVICE] Tìm thấy sản phẩm trong DB");
        print(
          "🔍 [SERVICE] _id từ DB: $actualObjectId (type: ${actualObjectId.runtimeType})",
        );
      } catch (e) {
        log("❌ Lỗi khi kiểm tra sản phẩm tồn tại: $e");
        print("❌ [SERVICE] Lỗi khi kiểm tra sản phẩm: $e");
        return false;
      }

      // Convert ProductModel sang JSON (không bao gồm id)
      final productData = product.toJson();
      print("🔄 [SERVICE] productData keys: ${productData.keys.toList()}");

      // Cập nhật thời gian sửa đổi
      productData['updatedAt'] = DateTime.now().toIso8601String();

      // Cập nhật trong MongoDB - dùng actualObjectId từ DB (đã được set ở trên)
      final updateQuery = {'_id': actualObjectId};

      print("🔄 [SERVICE] Đang thực hiện update với query: $updateQuery");
      // Dùng updateOne() thay vì update() để đảm bảo chỉ update 1 document
      final result = await collection.updateOne(updateQuery, {
        '\$set': productData,
      });

      // result từ updateOne() trả về là WriteResult object
      // Truy cập như object property
      final resultDynamic = result as dynamic;
      final nMatched =
          (resultDynamic.nMatched as int?) ??
          (resultDynamic['nMatched'] as int?) ??
          0;
      final nModified =
          (resultDynamic.nModified as int?) ??
          (resultDynamic['nModified'] as int?) ??
          0;

      log(
        "🔍 Update result type: ${result.runtimeType}, nMatched: $nMatched, nModified: $nModified",
      );
      print(
        "🔍 [PRINT] Update result type: ${result.runtimeType}, nMatched: $nMatched, nModified: $nModified",
      );

      // Xem như thành công nếu document được tìm thấy (nMatched > 0)
      // nModified có thể = 0 nếu giá trị không thay đổi, nhưng operation vẫn thành công
      final updated = nMatched > 0;

      print(
        "🔄 [SERVICE] nMatched: $nMatched, nModified: $nModified, updated: $updated",
      );

      if (updated) {
        if (nModified > 0) {
          log(
            "✅ Đã cập nhật sản phẩm thành công: $productId (nModified: $nModified)",
          );
          print("✅ [SERVICE] Update thành công với nModified > 0");
        } else {
          log(
            "✅ Đã tìm thấy sản phẩm: $productId (không có thay đổi về giá trị, nhưng operation thành công)",
          );
          print(
            "✅ [SERVICE] Update thành công (nMatched > 0 nhưng nModified = 0)",
          );
        }
      } else {
        log("⚠️ Không tìm thấy sản phẩm để cập nhật: $productId");
        print("❌ [SERVICE] Không tìm thấy sản phẩm (nMatched = 0)");
      }

      print("🔄 [SERVICE] Returning: $updated");
      return updated;
    } catch (e, stackTrace) {
      log("❌ Lỗi cập nhật sản phẩm: $e");
      log("📍 Stack trace: $stackTrace");
      print("❌ [SERVICE] Exception trong updateProduct: $e");
      print("📍 [SERVICE] Stack trace: $stackTrace");
      return false;
    }
  }

  /// Xóa sản phẩm
  ///
  /// [productId]: ID của sản phẩm cần xóa
  /// Trả về true nếu xóa thành công, false nếu thất bại
  Future<bool> deleteProduct(String productId) async {
    if (!isConnected) {
      await connect();
    }

    if (!isConnected) {
      log("❌ Không thể xóa sản phẩm: Chưa kết nối MongoDB");
      return false;
    }

    try {
      var collection = _db!.collection('products');

      // Bước 1: Lấy thông tin sản phẩm trước khi xóa để lấy imageUrl và images
      print("🗑️ [SERVICE] Đang lấy thông tin sản phẩm trước khi xóa...");
      final productDoc = await collection.findOne({
        '_id': ObjectId.fromHexString(productId),
      });

      if (productDoc == null) {
        log("⚠️ Không tìm thấy sản phẩm để xóa: $productId");
        print("❌ [SERVICE] Không tìm thấy sản phẩm để xóa");
        return false;
      }

      // Parse product để lấy imageUrl và images
      ProductModel? product;
      try {
        product = ProductModel.fromJson(productDoc);
      } catch (e) {
        log("⚠️ Không thể parse product: $e");
        print("⚠️ [SERVICE] Không thể parse product: $e");
      }

      // Bước 2: Xóa ảnh trên Cloudinary (nếu có)
      if (product != null) {
        print("🗑️ [SERVICE] Product info:");
        print("   - imageUrl: ${product.imageUrl}");
        print("   - images: ${product.images}");

        final cloudinaryService = getIt<CloudinaryService>();
        final imagesToDelete = <String>[];

        // Thêm imageUrl vào danh sách cần xóa
        if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
          imagesToDelete.add(product.imageUrl!);
          print(
            "🗑️ [SERVICE] Thêm imageUrl vào danh sách xóa: ${product.imageUrl}",
          );
          print(
            "🗑️ [SERVICE] imageUrl is Cloudinary: ${product.imageUrl!.contains('cloudinary.com')}",
          );
        }

        // Thêm tất cả images trong gallery vào danh sách cần xóa
        if (product.images != null && product.images!.isNotEmpty) {
          imagesToDelete.addAll(product.images!);
          print(
            "🗑️ [SERVICE] Thêm ${product.images!.length} ảnh gallery vào danh sách xóa",
          );
          for (final img in product.images!) {
            print(
              "🗑️ [SERVICE] Gallery image is Cloudinary: ${img.contains('cloudinary.com')} - $img",
            );
          }
        }

        print("🗑️ [SERVICE] Tổng số ảnh cần xóa: ${imagesToDelete.length}");

        // Xóa từng ảnh trên Cloudinary
        if (imagesToDelete.isNotEmpty) {
          print(
            "🗑️ [SERVICE] Đang xóa ${imagesToDelete.length} ảnh trên Cloudinary...",
          );
          int deletedCount = 0;
          for (final imageUrl in imagesToDelete) {
            print("🗑️ [SERVICE] Xử lý URL: $imageUrl");
            try {
              final deleted = await cloudinaryService.deleteImageFromUrl(
                imageUrl,
              );
              if (deleted) {
                deletedCount++;
                print("✅ [SERVICE] Đã xóa ảnh trên Cloudinary: $imageUrl");
              } else {
                print(
                  "⚠️ [SERVICE] Không thể xóa ảnh (có thể không phải Cloudinary URL hoặc extract publicId thất bại): $imageUrl",
                );
              }
            } catch (e, stackTrace) {
              log("⚠️ Lỗi xóa ảnh trên Cloudinary: $imageUrl - $e");
              print("⚠️ [SERVICE] Lỗi xóa ảnh trên Cloudinary: $imageUrl - $e");
              print("📍 [SERVICE] Stack trace: $stackTrace");
              // Tiếp tục xóa các ảnh khác dù có lỗi
            }
          }
          print(
            "🗑️ [SERVICE] Đã xóa $deletedCount/${imagesToDelete.length} ảnh trên Cloudinary",
          );
        } else {
          print("🗑️ [SERVICE] Sản phẩm không có ảnh để xóa trên Cloudinary");
        }
      } else {
        print(
          "⚠️ [SERVICE] Product is null, không thể xóa ảnh trên Cloudinary",
        );
      }

      // Bước 3: Xóa sản phẩm trong MongoDB
      print("🗑️ [SERVICE] Đang thực hiện deleteOne...");
      final result = await collection.deleteOne({
        '_id': ObjectId.fromHexString(productId),
      });

      print(
        "🗑️ [SERVICE] deleteOne completed, result type: ${result.runtimeType}",
      );

      // Kiểm tra xem document còn tồn tại không sau khi delete
      // Nếu không tìm thấy document nữa → delete thành công
      final stillExists = await collection.findOne({
        '_id': ObjectId.fromHexString(productId),
      });

      final deleted = stillExists == null;

      print(
        "🗑️ [SERVICE] Document còn tồn tại sau delete: ${stillExists != null}",
      );
      print("🗑️ [SERVICE] deleted: $deleted");

      if (deleted) {
        log("✅ Đã xóa sản phẩm thành công: $productId");
        print("✅ [SERVICE] Delete thành công");
      } else {
        log("⚠️ Không tìm thấy sản phẩm để xóa: $productId");
        print("❌ [SERVICE] Không tìm thấy sản phẩm để xóa");
      }

      print("🗑️ [SERVICE] Returning: $deleted");
      return deleted;
    } catch (e, stackTrace) {
      log("❌ Lỗi xóa sản phẩm: $e");
      log("📍 Stack trace: $stackTrace");
      print("❌ [SERVICE] Exception trong deleteProduct: $e");
      print("📍 [SERVICE] Stack trace: $stackTrace");
      return false;
    }
  }

  /// Đếm số lượng sản phẩm theo điều kiện
  ///
  /// Sử dụng các filter tương tự như getProducts
  Future<int> countProducts({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    bool? featured,
    String? status,
    String? brand,
    String? searchQuery,
    double? minRating,
  }) async {
    if (!isConnected) {
      await connect();
    }

    if (!isConnected) return 0;

    try {
      var collection = _db!.collection('products');

      // Xây dựng query filter (tương tự getProducts)
      Map<String, dynamic> query = {};

      if (categoryId != null && categoryId.isNotEmpty) {
        query['categoryId'] = categoryId;
      }

      if (minPrice != null || maxPrice != null) {
        query['price'] = {};
        if (minPrice != null) query['price']['\$gte'] = minPrice;
        if (maxPrice != null) query['price']['\$lte'] = maxPrice;
      }

      if (inStock != null) {
        if (inStock) {
          query['\$or'] = [
            {
              'stock': {'\$gt': 0},
            },
            {
              'status': {'\$ne': 'out_of_stock'},
            },
            {'inStock': true},
          ];
        } else {
          query['\$or'] = [
            {
              'stock': {'\$lte': 0},
            },
            {'status': 'out_of_stock'},
            {'inStock': false},
          ];
        }
      }

      if (featured != null) query['featured'] = featured;
      if (status != null && status.isNotEmpty) query['status'] = status;
      if (brand != null && brand.isNotEmpty) query['brand'] = brand;
      if (minRating != null && minRating > 0) {
        query['rating'] = {'\$gte': minRating};
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query['\$or'] = [
          {
            'name': {'\$regex': searchQuery, '\$options': 'i'},
          },
          {
            'description': {'\$regex': searchQuery, '\$options': 'i'},
          },
          {
            'tags': {
              '\$in': [searchQuery],
            },
          },
        ];
      }

      final count = await collection.count(query);
      return count;
    } catch (e) {
      log("❌ Lỗi đếm sản phẩm: $e");
      return 0;
    }
  }

  // ============================================
  // Generic CRUD Methods (Cho các collection khác)
  // ============================================

  /// Lấy dữ liệu từ collection
  ///
  /// [collectionName]: Tên collection
  /// [query]: Điều kiện tìm kiếm (MongoDB query)
  /// [limit]: Giới hạn số lượng
  Future<List<Map<String, dynamic>>> find(
    String collectionName,
    Map<String, dynamic> query, {
    int? limit,
  }) async {
    if (!isConnected) {
      await connect();
    }

    if (!isConnected) return [];

    try {
      var collection = _db!.collection(collectionName);
      var stream = collection.find(query);

      if (limit != null) {
        stream = stream.take(limit);
      }

      return await stream.toList();
    } catch (e) {
      log("❌ Lỗi tìm kiếm trong collection $collectionName: $e");
      return [];
    }
  }

  /// Thêm document mới vào collection
  Future<String?> insert(
    String collectionName,
    Map<String, dynamic> data,
  ) async {
    if (!isConnected) {
      log("⚠️ Chưa kết nối, đang thử kết nối...");
      await connect();
    }

    if (!isConnected) {
      log("❌ Không thể insert: Chưa kết nối MongoDB");
      return null;
    }

    try {
      log("📝 Đang insert vào collection: $collectionName");
      log("📝 Dữ liệu: $data");

      // Tạo một bản copy của data để tránh lỗi type với ObjectId
      // mongo_dart có thể tự động thêm _id là ObjectId, nên cần đảm bảo Map là mutable
      final dataToInsert = Map<String, dynamic>.from(data);

      var collection = _db!.collection(collectionName);
      final result = await collection.insertOne(dataToInsert);

      log("✅ Insert thành công!");
      log("📝 Result type: ${result.runtimeType}");
      log("📝 Result: $result");

      // Xử lý result.id - có thể là ObjectId hoặc String
      String? insertedId;
      if (result.id != null) {
        if (result.id is ObjectId) {
          insertedId = (result.id as ObjectId).toHexString();
        } else {
          insertedId = result.id.toString();
        }
        log("✅ Inserted ID: $insertedId");
      } else {
        log("⚠️ Result.id là null!");
      }

      return insertedId;
    } catch (e, stackTrace) {
      log("❌ Lỗi thêm dữ liệu vào collection $collectionName: $e");
      log("📍 Stack trace: $stackTrace");
      print("❌❌❌ LỖI INSERT ❌❌❌");
      print("Collection: $collectionName");
      print("Data: $data");
      print("Error: $e");
      print("Stack trace: $stackTrace");
      return null;
    }
  }

  /// Cập nhật document
  Future<bool> update(
    String collectionName,
    Map<String, dynamic> query,
    Map<String, dynamic> updateData,
  ) async {
    if (!isConnected) {
      await connect();
    }

    if (!isConnected) return false;

    try {
      var collection = _db!.collection(collectionName);
      // Dùng updateOne() thay vì update() để đảm bảo chỉ update 1 document
      final result = await collection.updateOne(query, {'\$set': updateData});

      // result từ updateOne() trả về là WriteResult object
      final resultDynamic = result as dynamic;
      final nMatched =
          (resultDynamic.nMatched as int?) ??
          (resultDynamic['nMatched'] as int?) ??
          0;
      final nModified =
          (resultDynamic.nModified as int?) ??
          (resultDynamic['nModified'] as int?) ??
          0;

      // Xem như thành công nếu document được tìm thấy (nMatched > 0)
      // nModified có thể = 0 nếu giá trị không thay đổi, nhưng operation vẫn thành công
      final updated = nMatched > 0;

      log(
        "🔍 Update result - collection: $collectionName, nMatched: $nMatched, nModified: $nModified, updated: $updated",
      );

      return updated;
    } catch (e, stackTrace) {
      log("❌ Lỗi cập nhật dữ liệu trong collection $collectionName: $e");
      log("📍 Stack trace: $stackTrace");
      print("❌ [SERVICE] Exception trong update: $e");
      print("📍 [SERVICE] Stack trace: $stackTrace");
      return false;
    }
  }

  /// Xóa document
  Future<bool> delete(String collectionName, Map<String, dynamic> query) async {
    if (!isConnected) {
      await connect();
    }

    if (!isConnected) return false;

    try {
      var collection = _db!.collection(collectionName);
      final result = await collection.deleteOne(query);
      // WriteResult có thể là Map hoặc object với deletedCount
      return (result as dynamic).deletedCount > 0;
    } catch (e) {
      log("❌ Lỗi xóa dữ liệu trong collection $collectionName: $e");
      return false;
    }
  }

  // ============================================
  // Order Methods
  // ============================================

  /// Tạo đơn hàng mới
  ///
  /// [order]: OrderModel chứa thông tin đơn hàng
  /// Trả về ID của đơn hàng vừa tạo, hoặc null nếu thất bại
  Future<String?> createOrder(OrderModel order) async {
    if (!isConnected) {
      await connect();
    }

    if (!isConnected) {
      log("❌ Không thể tạo đơn hàng: Chưa kết nối MongoDB");
      return null;
    }

    try {
      var collection = _db!.collection('orders');

      // Convert OrderModel sang JSON để lưu vào MongoDB
      final orderData = order.toJson();

      // Insert vào MongoDB
      final result = await collection.insertOne(orderData);

      if (result.id != null) {
        final orderId = result.id!.toString();
        log("✅ Đã tạo đơn hàng thành công với ID: $orderId");
        return orderId;
      } else {
        log("❌ Không thể lấy ID của đơn hàng vừa tạo");
        return null;
      }
    } catch (e, stackTrace) {
      log("❌ Lỗi tạo đơn hàng: $e");
      log("📍 Stack trace: $stackTrace");
      return null;
    }
  }

  /// Tạo đơn hàng với kiểm tra tồn kho (Atomic Update - Tránh Race Condition)
  ///
  /// [order]: OrderModel chứa thông tin đơn hàng
  /// Trả về Map với:
  /// - 'orderId': String? - ID đơn hàng nếu thành công, null nếu thất bại
  /// - 'error': String? - Thông báo lỗi nếu có (ví dụ: sản phẩm nào hết hàng)
  ///
  /// Logic:
  /// 1. Duyệt qua từng item trong đơn hàng
  /// 2. Atomic update: Trừ tồn kho chỉ khi stock >= quantity
  /// 3. Nếu có item hết hàng, rollback lại các item đã trừ trước đó
  /// 4. Nếu tất cả thành công, tạo đơn hàng
  Future<Map<String, dynamic>> createOrderWithStockCheck(
    OrderModel order,
  ) async {
    if (!isConnected) {
      await connect();
    }

    if (!isConnected) {
      log("❌ Không thể tạo đơn hàng: Chưa kết nối MongoDB");
      return {'orderId': null, 'error': 'Không thể kết nối đến database'};
    }

    var productCollection = _db!.collection('products');
    var orderCollection = _db!.collection('orders');

    // Danh sách các item đã trừ kho thành công (để rollback nếu cần)
    final List<Map<String, dynamic>> itemsProcessed = [];

    try {
      log("🛒 Bắt đầu tạo đơn hàng với kiểm tra tồn kho...");
      print("🛒 [PRINT] Bắt đầu tạo đơn hàng với kiểm tra tồn kho...");

      // Bước 0: Gộp các items cùng productId, color, size lại để tránh trừ kho trùng lặp
      final Map<String, CartItemModel> mergedItems = {};
      for (var item in order.items) {
        // Tạo key duy nhất dựa trên productId, color, size
        final key = '${item.productId}_${item.color ?? ''}_${item.size ?? ''}';

        if (mergedItems.containsKey(key)) {
          // Nếu đã có item cùng key, cộng quantity lại
          final existingItem = mergedItems[key]!;
          mergedItems[key] = existingItem.copyWith(
            quantity: existingItem.quantity + item.quantity,
          );
          log(
            "🔄 Gộp item trùng lặp: ${item.product.name} (quantity: ${existingItem.quantity} + ${item.quantity} = ${existingItem.quantity + item.quantity})",
          );
        } else {
          // Nếu chưa có, thêm mới
          mergedItems[key] = item;
        }
      }

      log(
        "📦 Tổng số items sau khi gộp: ${mergedItems.length} (trước khi gộp: ${order.items.length})",
      );
      print(
        "📦 [PRINT] Tổng số items sau khi gộp: ${mergedItems.length} (trước khi gộp: ${order.items.length})",
      );

      // Bước 1: Duyệt qua từng sản phẩm đã gộp để trừ kho
      for (var item in mergedItems.values) {
        // Bỏ qua các item có quantity <= 0 để tránh lỗi logic
        if (item.quantity <= 0) {
          log(
            "⚠️ Bỏ qua item với quantity <= 0: ${item.product.name} (quantity: ${item.quantity})",
          );
          continue;
        }

        try {
          // Lấy thông tin sản phẩm trước để kiểm tra kiểu dữ liệu
          final productBeforeUpdate = await productCollection.findOne({
            '_id': ObjectId.fromHexString(item.productId),
          });

          if (productBeforeUpdate == null) {
            log(
              "❌ Không tìm thấy sản phẩm: ${item.product.name} (productId: ${item.productId})",
            );
            print("❌ [PRINT] Không tìm thấy sản phẩm: ${item.product.name}");
            await _rollbackStock(itemsProcessed, productCollection);
            return {
              'orderId': null,
              'error':
                  'Không tìm thấy dữ liệu sản phẩm "${item.product.name}" trong hệ thống.',
            };
          }

          final stockBefore = productBeforeUpdate['stock'];
          final stockType = stockBefore.runtimeType;
          final stockValue = stockBefore is num ? stockBefore.toDouble() : 0.0;
          final quantityValue = item.quantity.toDouble();

          log(
            "🔍 Stock trước update: $stockValue (type: $stockType), quantity: $quantityValue",
          );
          print(
            "🔍 [PRINT] Stock trước update: $stockValue (type: $stockType), quantity: $quantityValue",
          );

          // Atomic update: Chỉ trừ kho nếu stock >= quantity
          // Đảm bảo so sánh cùng kiểu dữ liệu (double)
          final result = await productCollection.update(
            {
              '_id': ObjectId.fromHexString(item.productId),
              'stock': {
                '\$gte': quantityValue,
              }, // ĐIỀU KIỆN QUAN TRỌNG - dùng double
            },
            {
              '\$inc': {
                'stock': -quantityValue,
              }, // Trừ tồn kho Atomic - dùng double
            },
          );

          // Kiểm tra kết quả update
          // result từ update() trả về là Map<String, dynamic>, không phải object có getter
          final nModified = (result['nModified'] as int? ?? 0);
          log(
            "🔍 Update result: nModified=$nModified, matchedCount=${result['nMatched'] ?? 0}",
          );
          print(
            "🔍 [PRINT] Update result: nModified=$nModified, matchedCount=${result['nMatched'] ?? 0}",
          );
          if (nModified == 0) {
            // Không đủ hàng hoặc không tìm thấy sản phẩm (theo điều kiện stock >= quantity)
            log(
              "❌ Hết hàng hoặc không đủ tồn kho cho sản phẩm: ${item.product.name} (quantity yêu cầu: ${item.quantity})",
            );

            // Lấy lại thông tin sản phẩm để kiểm tra tồn kho thực tế và báo lỗi chính xác
            final productData = await productCollection.findOne({
              '_id': ObjectId.fromHexString(item.productId),
            });

            if (productData == null) {
              // Không tìm thấy sản phẩm trong DB
              log(
                "❌ Không tìm thấy document sản phẩm trong DB: ${item.product.name} (productId: ${item.productId})",
              );

              // Rollback: Cộng lại tồn kho cho các item đã trừ trước đó
              await _rollbackStock(itemsProcessed, productCollection);

              return {
                'orderId': null,
                'error':
                    'Không tìm thấy dữ liệu sản phẩm "${item.product.name}" trong hệ thống. Vui lòng liên hệ admin.',
              };
            }

            final currentStockRaw = productData['stock'];
            final currentStockType = currentStockRaw.runtimeType;
            final currentStock = currentStockRaw is num
                ? currentStockRaw.toDouble()
                : 0.0;
            final quantityDouble = item.quantity.toDouble();

            log(
              "❌ Stock hiện tại: $currentStock (type: $currentStockType), quantity yêu cầu: $quantityDouble",
            );
            print(
              "❌ [PRINT] Stock hiện tại: $currentStock (type: $currentStockType), quantity yêu cầu: $quantityDouble",
            );

            // Nếu stock sau khi đọc lại đúng bằng stockValue - quantityDouble,
            // coi như lần update trước đã trừ kho thành công dù nModified == 0.
            final expectedAfter = stockValue - quantityDouble;
            if ((currentStock - expectedAfter).abs() < 0.000001) {
              log(
                "ℹ️ Phát hiện stock đã giảm đúng ($stockValue -> $currentStock) dù nModified=0. Xem như trừ kho thành công cho sản phẩm: ${item.product.name}",
              );
              print(
                "ℹ️ [PRINT] Stock đã giảm đúng ($stockValue -> $currentStock). Xem như trừ kho thành công cho sản phẩm: ${item.product.name}",
              );

              itemsProcessed.add({
                'productId': item.productId,
                'quantity': item.quantity,
                'productName': item.product.name,
              });

              // Chuyển sang xử lý sản phẩm tiếp theo
              continue;
            }

            // Nếu stock thực tế vẫn đủ cho quantity yêu cầu, thử một lần update an toàn
            // với điều kiện stock == currentStock để tránh double-trừ trong race condition.
            if (currentStock >= quantityDouble) {
              log(
                "ℹ️ Stock thực tế ($currentStock) vẫn đủ cho sản phẩm ${item.product.name}. Thử update lại với điều kiện stock == currentStock...",
              );
              print(
                "ℹ️ [PRINT] Stock thực tế ($currentStock) vẫn đủ. Thử update lại với điều kiện stock == currentStock...",
              );

              final retryResult = await productCollection.update(
                {
                  '_id': ObjectId.fromHexString(item.productId),
                  'stock':
                      currentStock, // CAS: chỉ update nếu stock vẫn bằng currentStock (double)
                },
                {
                  '\$set': {
                    'stock': currentStock - quantityDouble,
                  }, // Dùng double
                },
              );

              final retryModified = retryResult['nModified'] as int? ?? 0;
              final retryMatched = retryResult['nMatched'] as int? ?? 0;
              log(
                "🔍 Retry result: nModified=$retryModified, nMatched=$retryMatched",
              );
              print(
                "🔍 [PRINT] Retry result: nModified=$retryModified, nMatched=$retryMatched",
              );
              if (retryModified > 0) {
                log(
                  "✅ Đã trừ tồn kho thành công ở lần retry an toàn cho sản phẩm: ${item.product.name}",
                );
                print(
                  "✅ [PRINT] Đã trừ tồn kho thành công ở lần retry an toàn cho sản phẩm: ${item.product.name}",
                );

                // Lưu lại item đã trừ kho thành công (để rollback nếu cần)
                itemsProcessed.add({
                  'productId': item.productId,
                  'quantity': item.quantity,
                  'productName': item.product.name,
                });

                // Chuyển sang xử lý sản phẩm tiếp theo
                continue;
              }

              log(
                "❌ Lần retry an toàn (stock == currentStock) cũng thất bại cho sản phẩm: ${item.product.name}",
              );
              print(
                "❌ [PRINT] Lần retry an toàn (stock == currentStock) cũng thất bại cho sản phẩm: ${item.product.name}",
              );
            }

            // Nếu tới đây thì hoặc stock thực tế không đủ, hoặc retry an toàn cũng thất bại → rollback + trả lỗi
            // Rollback: Cộng lại tồn kho cho các item đã trừ trước đó
            await _rollbackStock(itemsProcessed, productCollection);

            final errorMessage = currentStock <= 0
                ? 'Sản phẩm "${item.product.name}" đã hết hàng'
                : 'Sản phẩm "${item.product.name}" chỉ còn $currentStock sản phẩm (bạn đang mua ${item.quantity})';

            print("❌ [PRINT] Trả về lỗi: $errorMessage");
            return {'orderId': null, 'error': errorMessage};
          }

          // Lưu lại item đã trừ kho thành công (để rollback nếu cần)
          itemsProcessed.add({
            'productId': item.productId,
            'quantity': item.quantity,
            'productName': item.product.name,
          });

          log("✅ Đã trừ ${item.quantity} sản phẩm: ${item.product.name}");
        } catch (e) {
          log("❌ Lỗi khi trừ tồn kho cho ${item.product.name}: $e");

          // Rollback: Cộng lại tồn kho cho các item đã trừ trước đó
          await _rollbackStock(itemsProcessed, productCollection);

          return {
            'orderId': null,
            'error': 'Lỗi khi xử lý sản phẩm "${item.product.name}": $e',
          };
        }
      }

      // Bước 2: Nếu trừ kho thành công hết thì mới tạo đơn hàng
      log("✅ Tất cả sản phẩm đã được trừ kho, đang tạo đơn hàng...");
      print("✅ [PRINT] Tất cả sản phẩm đã được trừ kho, đang tạo đơn hàng...");
      log("📦 Số lượng items trong đơn hàng: ${order.items.length}");
      print("📦 [PRINT] Số lượng items trong đơn hàng: ${order.items.length}");

      String? orderId;
      try {
        // Tạo orderData từ order gốc (không dùng mergedItems vì mergedItems chỉ để trừ kho)
        final orderData = order.toJson();
        log("📝 Order data keys: ${orderData.keys.toList()}");
        print("📝 [PRINT] Order data keys: ${orderData.keys.toList()}");
        log(
          "📝 Order items count: ${(orderData['items'] as List?)?.length ?? 0}",
        );
        print(
          "📝 [PRINT] Order items count: ${(orderData['items'] as List?)?.length ?? 0}",
        );

        log("📝 Đang insert đơn hàng vào MongoDB collection 'orders'...");
        print(
          "📝 [PRINT] Đang insert đơn hàng vào MongoDB collection 'orders'...",
        );
        final result = await orderCollection.insertOne(orderData);
        log(
          "📝 Insert completed. Result ID: ${result.id}, type: ${result.id?.runtimeType}",
        );
        print(
          "📝 [PRINT] Insert completed. Result ID: ${result.id}, type: ${result.id?.runtimeType}",
        );

        // Xử lý result.id - có thể là ObjectId hoặc String
        if (result.id != null) {
          if (result.id is ObjectId) {
            orderId = (result.id as ObjectId).toHexString();
            log("📝 Converted ObjectId to hex string: $orderId");
          } else {
            orderId = result.id.toString();
            log("📝 Result.id as string: $orderId");
            // Nếu orderId có format "ObjectId('...')" thì extract hex string
            if (orderId.startsWith('ObjectId(') && orderId.endsWith(')')) {
              final startIndex = orderId.indexOf("'") + 1;
              final endIndex = orderId.lastIndexOf("'");
              if (startIndex > 0 && endIndex > startIndex) {
                orderId = orderId.substring(startIndex, endIndex);
                log("📝 Extracted hex from ObjectId string: $orderId");
              }
            }
          }
        } else {
          log("⚠️ WARNING: result.id is NULL after insertOne!");
        }

        if (orderId != null && orderId.isNotEmpty) {
          log("✅ Đã tạo đơn hàng thành công với ID: $orderId");
          print("✅ [PRINT] Đã tạo đơn hàng thành công với ID: $orderId");
          log("✅ Order number: ${order.orderNumber}");
          print("✅ [PRINT] Order number: ${order.orderNumber}");
          return {'orderId': orderId, 'error': null};
        } else {
          log(
            "❌ Không thể lấy ID của đơn hàng vừa tạo (result.id: ${result.id}, type: ${result.id?.runtimeType})",
          );
          log(
            "❌ Order data có thể không hợp lệ hoặc insertOne không thành công",
          );

          // Rollback: Cộng lại tồn kho vì không tạo được đơn hàng
          log("🔄 Đang rollback tồn kho vì không tạo được đơn hàng...");
          await _rollbackStock(itemsProcessed, productCollection);
          log("🔄 Rollback hoàn tất");

          return {
            'orderId': null,
            'error': 'Không thể tạo đơn hàng. Vui lòng thử lại.',
          };
        }
      } catch (insertError, insertStackTrace) {
        log("❌ Lỗi khi tạo đơn hàng (sau khi đã trừ kho): $insertError");
        print(
          "❌ [PRINT] Lỗi khi tạo đơn hàng (sau khi đã trừ kho): $insertError",
        );
        log("📍 Stack trace: $insertStackTrace");
        print("📍 [PRINT] Stack trace: $insertStackTrace");

        // Rollback: Cộng lại tồn kho vì không tạo được đơn hàng
        await _rollbackStock(itemsProcessed, productCollection);

        return {'orderId': null, 'error': 'Lỗi khi tạo đơn hàng: $insertError'};
      }
    } catch (e, stackTrace) {
      log("❌ Lỗi tạo đơn hàng: $e");
      print("❌ [PRINT] Lỗi tạo đơn hàng: $e");
      log("📍 Stack trace: $stackTrace");
      print("📍 [PRINT] Stack trace: $stackTrace");

      // Rollback: Cộng lại tồn kho khi có lỗi
      await _rollbackStock(itemsProcessed, productCollection);

      return {'orderId': null, 'error': 'Lỗi khi tạo đơn hàng: $e'};
    }
  }

  /// Rollback tồn kho cho các sản phẩm đã trừ trước đó
  ///
  /// [itemsProcessed]: Danh sách các item đã trừ kho thành công
  /// [productCollection]: Collection products
  Future<void> _rollbackStock(
    List<Map<String, dynamic>> itemsProcessed,
    var productCollection,
  ) async {
    if (itemsProcessed.isEmpty) return;

    log("🔄 Đang rollback tồn kho cho ${itemsProcessed.length} sản phẩm...");

    for (var item in itemsProcessed) {
      try {
        await productCollection.update(
          {'_id': ObjectId.fromHexString(item['productId'] as String)},
          {
            '\$inc': {'stock': item['quantity'] as int},
          },
        );
        log(
          "✅ Đã rollback ${item['quantity']} sản phẩm: ${item['productName']}",
        );
      } catch (e) {
        log("❌ Lỗi rollback cho ${item['productName']}: $e");
        // Tiếp tục rollback các item khác dù có lỗi
      }
    }
  }

  /// Lấy đơn hàng theo ID
  ///
  /// [orderId]: ID của đơn hàng
  /// Trả về OrderModel nếu tìm thấy, null nếu không tìm thấy
  Future<OrderModel?> getOrderById(String orderId) async {
    if (!isConnected) {
      await connect();
    }

    if (!isConnected) return null;

    try {
      var collection = _db!.collection('orders');
      final data = await collection.findOne({
        '_id': ObjectId.fromHexString(orderId),
      });

      if (data == null) return null;

      return OrderModel.fromJson(data);
    } catch (e) {
      log("❌ Lỗi lấy đơn hàng theo ID: $e");
      return null;
    }
  }

  /// Lấy danh sách đơn hàng của user
  ///
  /// [userId]: ID của user (có thể là empty string nếu chưa đăng nhập)
  /// [limit]: Giới hạn số lượng đơn hàng
  /// [sortBy]: Sắp xếp theo field nào (mặc định: 'createdAt')
  /// [sortOrder]: Thứ tự sắp xếp (1: tăng dần, -1: giảm dần, mặc định: -1)
  Future<List<OrderModel>> getOrdersByUserId(
    String userId, {
    int? limit,
    String sortBy = 'createdAt',
    int sortOrder = -1,
  }) async {
    if (!isConnected) {
      await connect();
    }

    if (!isConnected) return [];

    try {
      var collection = _db!.collection('orders');
      final query = <String, dynamic>{};

      // Nếu userId không rỗng, filter theo userId
      if (userId.isNotEmpty) {
        query['userId'] = userId;
      }

      var stream = collection.find(query);

      // Áp dụng limit nếu có
      if (limit != null) {
        stream = stream.take(limit);
      }

      final data = await stream.toList();

      // Sort ở application level
      data.sort((a, b) {
        final aVal = a[sortBy];
        final bVal = b[sortBy];
        if (aVal == null) return 1;
        if (bVal == null) return -1;

        if (aVal is DateTime && bVal is DateTime) {
          final comparison = aVal.compareTo(bVal);
          return sortOrder == -1 ? -comparison : comparison;
        }

        if (aVal is String && bVal is String) {
          final comparison = aVal.compareTo(bVal);
          return sortOrder == -1 ? -comparison : comparison;
        }

        return 0;
      });

      log("✅ Lấy được ${data.length} đơn hàng");
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e, stackTrace) {
      log("❌ Lỗi lấy danh sách đơn hàng: $e");
      log("📍 Stack trace: $stackTrace");
      return [];
    }
  }

  /// Cập nhật trạng thái đơn hàng
  ///
  /// [orderId]: ID của đơn hàng
  /// [status]: Trạng thái mới ('pending', 'confirmed', 'shipping', 'delivered', 'cancelled')
  /// Trả về true nếu cập nhật thành công, false nếu thất bại
  Future<bool> updateOrderStatus(String orderId, String status) async {
    if (!isConnected) {
      await connect();
    }

    if (!isConnected) return false;

    try {
      var collection = _db!.collection('orders');
      final result = await collection.update(
        {'_id': ObjectId.fromHexString(orderId)},
        {
          '\$set': {
            'status': status,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        },
      );

      // result từ update() trả về là Map<String, dynamic>
      final success = (result['nModified'] as int? ?? 0) > 0;
      if (success) {
        log("✅ Đã cập nhật trạng thái đơn hàng $orderId thành $status");
      } else {
        log("⚠️ Không tìm thấy đơn hàng $orderId để cập nhật");
      }
      return success;
    } catch (e) {
      log("❌ Lỗi cập nhật trạng thái đơn hàng: $e");
      return false;
    }
  }
}
