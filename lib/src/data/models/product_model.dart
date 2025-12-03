import 'package:mongo_dart/mongo_dart.dart';

class ProductModel {
  // ============================================
  // CÁC TRƯỜNG CƠ BẢN (Required)
  // ============================================
  final String id;
  final String name;
  final double price;

  // ============================================
  // HÌNH ẢNH
  // ============================================
  final String? imageUrl; // Ảnh đại diện chính
  final List<String>? images; // Danh sách ảnh chi tiết (Gallery)

  // ============================================
  // MÔ TẢ & THÔNG TIN
  // ============================================
  final String? description; // Mô tả ngắn
  final String? longDescription; // Mô tả chi tiết (HTML hoặc markdown)
  final String? shortDescription; // Mô tả ngắn gọn (1-2 câu)

  // ============================================
  // GIÁ & KHUYẾN MÃI
  // ============================================
  final double? discountPercent; // Phần trăm giảm giá
  final double? originalPrice; // Giá gốc (trước khi giảm)
  final DateTime? discountStartDate; // Ngày bắt đầu giảm giá
  final DateTime? discountEndDate; // Ngày kết thúc giảm giá

  // ============================================
  // PHÂN LOẠI
  // ============================================
  final String? categoryId; // ID danh mục
  final String? categoryName; // Tên danh mục (để hiển thị nhanh)
  final List<String>? tags; // Tags/Từ khóa để tìm kiếm

  // ============================================
  // THUỘC TÍNH SẢN PHẨM
  // ============================================
  final List<String>? colors; // Danh sách màu sắc có sẵn
  final List<String>? sizes; // Danh sách kích cỡ có sẵn
  final String? brand; // Thương hiệu/Nhà sản xuất
  final String? sku; // SKU/Barcode
  final String? barcode; // Mã vạch

  // ============================================
  // KÍCH THƯỚC & TRỌNG LƯỢNG
  // ============================================
  final double? weight; // Trọng lượng (kg)
  final double? length; // Chiều dài (cm)
  final double? width; // Chiều rộng (cm)
  final double? height; // Chiều cao (cm)

  // ============================================
  // TỒN KHO & TRẠNG THÁI
  // ============================================
  final int? stock; // Số lượng tồn kho
  final int? minStock; // Số lượng tồn kho tối thiểu
  final String?
  status; // Trạng thái: 'active', 'inactive', 'out_of_stock', 'discontinued'
  final bool? inStock; // Còn hàng hay không (tính từ stock > 0)

  // ============================================
  // THỐNG KÊ & ĐÁNH GIÁ
  // ============================================
  final int? soldCount; // Số lượng đã bán
  final int? viewCount; // Số lượt xem
  final bool? featured; // Sản phẩm nổi bật
  final double rating; // Điểm đánh giá (vd: 4.5)
  final int ratingCount; // Số lượng đánh giá (vd: 120)

  // ============================================
  // THỜI GIAN
  // ============================================
  final DateTime? createdAt; // Ngày tạo
  final DateTime? updatedAt; // Ngày cập nhật
  final DateTime? publishedAt; // Ngày xuất bản/đăng bán

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    // Hình ảnh
    this.imageUrl,
    this.images,
    // Mô tả
    this.description,
    this.longDescription,
    this.shortDescription,
    // Giá & Khuyến mãi
    this.discountPercent,
    this.originalPrice,
    this.discountStartDate,
    this.discountEndDate,
    // Phân loại
    this.categoryId,
    this.categoryName,
    this.tags,
    // Thuộc tính
    this.colors,
    this.sizes,
    this.brand,
    this.sku,
    this.barcode,
    // Kích thước & Trọng lượng
    this.weight,
    this.length,
    this.width,
    this.height,
    // Tồn kho & Trạng thái
    this.stock,
    this.minStock,
    this.status,
    this.inStock,
    // Thống kê & Đánh giá
    this.soldCount,
    this.viewCount,
    this.featured,
    this.rating = 0.0,
    this.ratingCount = 0,
    // Thời gian
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
  });

  // --- 1. GIẢI QUYẾT LỖI UI ---
  // Getter này giúp UI gọi product.image mà không bị lỗi,
  // dù field thực tế là imageUrl
  String get image => imageUrl ?? '';

  // --- 2. LOGIC CLOUDINARY ---
  // Hàm lấy ảnh tối ưu (Resize tự động)
  String getOptimizedImage({int width = 300}) {
    String url = image;
    if (url.isEmpty)
      return 'https://via.placeholder.com/$width'; // Ảnh giữ chỗ nếu null

    // Nếu là ảnh Cloudinary và chưa có tham số resize
    if (url.contains('cloudinary.com') && !url.contains('/w_')) {
      return url.replaceFirst('/upload/', '/upload/w_$width,q_auto,f_auto/');
    }
    return url;
  }

  // ============================================
  // GETTERS & COMPUTED PROPERTIES
  // ============================================

  /// Tính giá sau khi giảm
  double get discountedPrice {
    // Nếu có originalPrice, dùng nó làm giá gốc
    final basePrice = originalPrice ?? price;

    // Kiểm tra discount có còn hiệu lực không
    if (discountPercent != null && discountPercent! > 0) {
      final now = DateTime.now();
      // Kiểm tra thời gian giảm giá
      if (discountStartDate != null && now.isBefore(discountStartDate!)) {
        return basePrice; // Chưa đến thời gian giảm giá
      }
      if (discountEndDate != null && now.isAfter(discountEndDate!)) {
        return basePrice; // Đã hết thời gian giảm giá
      }
      return basePrice * (1 - discountPercent! / 100);
    }
    return basePrice;
  }

  /// Format hiển thị giảm giá (vd: "-10%")
  String get discountTag => discountPercent != null && discountPercent! > 0
      ? '-${discountPercent!.toInt()}%'
      : '';

  /// Kiểm tra sản phẩm có đang giảm giá không
  bool get isOnSale {
    if (discountPercent == null || discountPercent! <= 0) return false;
    final now = DateTime.now();
    if (discountStartDate != null && now.isBefore(discountStartDate!)) {
      return false;
    }
    if (discountEndDate != null && now.isAfter(discountEndDate!)) {
      return false;
    }
    return true;
  }

  /// Kiểm tra còn hàng không
  bool get isInStock {
    if (inStock != null) return inStock!;
    if (stock != null) return stock! > 0;
    if (status == 'out_of_stock' || status == 'discontinued') return false;
    return true; // Mặc định còn hàng nếu không có thông tin
  }

  /// Kiểm tra sắp hết hàng (stock <= minStock)
  bool get isLowStock {
    if (stock == null || minStock == null) return false;
    return stock! <= minStock! && stock! > 0;
  }

  /// Lấy mô tả ngắn (ưu tiên shortDescription, sau đó description)
  String get displayDescription =>
      shortDescription ?? description ?? 'Chưa có mô tả';

  /// Tính kích thước (volume) nếu có đầy đủ thông tin
  double? get volume {
    if (length != null && width != null && height != null) {
      return length! * width! * height!;
    }
    return null;
  }

  /// Lấy danh sách màu sắc (fallback nếu null)
  List<String> get availableColors => colors ?? [];

  /// Lấy danh sách kích cỡ (fallback nếu null)
  List<String> get availableSizes => sizes ?? [];

  /// Kiểm tra sản phẩm có thuộc tính (màu/size) không
  bool get hasVariants =>
      (colors != null && colors!.isNotEmpty) ||
      (sizes != null && sizes!.isNotEmpty);

  /// Tạo ProductModel từ JSON (MongoDB document)
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Xử lý ID: Giống cách UserModel xử lý (đã test và hoạt động tốt)
    String? id;
    if (json['_id'] != null) {
      if (json['_id'] is ObjectId) {
        id = (json['_id'] as ObjectId).toHexString();
      } else {
        // Nếu là string, có thể có format "ObjectId('...')" hoặc hexString thuần
        final idStr = json['_id'].toString();
        // Nếu có format "ObjectId('...')" thì extract hexString
        // Format: "ObjectId('692f28f17bbcf1b72c000000')" -> "692f28f17bbcf1b72c000000"
        if (idStr.startsWith('ObjectId(') && idStr.endsWith(')')) {
          // Tìm vị trí bắt đầu và kết thúc của hex string
          final startIndex = idStr.indexOf("'") + 1;
          final endIndex = idStr.lastIndexOf("'");
          if (startIndex > 0 && endIndex > startIndex) {
            id = idStr.substring(startIndex, endIndex);
          } else {
            // Fallback: bỏ "ObjectId(" và ")"
            id = idStr.substring(9, idStr.length - 1);
          }
        } else {
          id = idStr; // Đã là hexString thuần túy
        }
      }
    } else if (json['id'] != null) {
      id = json['id'].toString();
    }

    return ProductModel(
      // ID
      id: id ?? '',

      // Cơ bản
      name: json['name']?.toString() ?? 'No Name',
      price: (json['price'] is num) ? json['price'].toDouble() : 0.0,

      // Hình ảnh
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
      images: json['images'] != null
          ? List<String>.from(json['images'].map((x) => x.toString()))
          : null,

      // Mô tả
      description: json['description']?.toString(),
      longDescription: json['longDescription']?.toString(),
      shortDescription: json['shortDescription']?.toString(),

      // Giá & Khuyến mãi
      discountPercent: (json['discountPercent'] is num)
          ? json['discountPercent'].toDouble()
          : null,
      originalPrice: (json['originalPrice'] is num)
          ? json['originalPrice'].toDouble()
          : null,
      discountStartDate: json['discountStartDate'] != null
          ? DateTime.tryParse(json['discountStartDate'].toString())
          : null,
      discountEndDate: json['discountEndDate'] != null
          ? DateTime.tryParse(json['discountEndDate'].toString())
          : null,

      // Phân loại
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      tags: json['tags'] != null
          ? List<String>.from(json['tags'].map((x) => x.toString()))
          : null,

      // Thuộc tính
      colors: json['colors'] != null
          ? List<String>.from(json['colors'].map((x) => x.toString()))
          : null,
      sizes: json['sizes'] != null
          ? List<String>.from(json['sizes'].map((x) => x.toString()))
          : null,
      brand: json['brand']?.toString(),
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString(),

      // Kích thước & Trọng lượng
      weight: (json['weight'] is num) ? json['weight'].toDouble() : null,
      length: (json['length'] is num) ? json['length'].toDouble() : null,
      width: (json['width'] is num) ? json['width'].toDouble() : null,
      height: (json['height'] is num) ? json['height'].toDouble() : null,

      // Tồn kho & Trạng thái
      stock: json['stock'] is num ? json['stock'].toInt() : null,
      minStock: json['minStock'] is num ? json['minStock'].toInt() : null,
      status: json['status']?.toString(),
      inStock: json['inStock'] as bool?,

      // Thống kê & Đánh giá
      soldCount: json['soldCount'] is num ? json['soldCount'].toInt() : null,
      viewCount: json['viewCount'] is num ? json['viewCount'].toInt() : null,
      featured: json['featured'] as bool?,
      rating: (json['rating'] is num) ? json['rating'].toDouble() : 0.0,
      ratingCount: (json['ratingCount'] is num)
          ? json['ratingCount'].toInt()
          : 0,

      // Thời gian
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
    );
  }

  /// Chuyển ProductModel sang JSON (cho MongoDB)
  Map<String, dynamic> toJson() {
    return {
      // Cơ bản
      'name': name,
      'price': price,

      // Hình ảnh
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (images != null) 'images': images,

      // Mô tả
      if (description != null) 'description': description,
      if (longDescription != null) 'longDescription': longDescription,
      if (shortDescription != null) 'shortDescription': shortDescription,

      // Giá & Khuyến mãi
      if (originalPrice != null) 'originalPrice': originalPrice,
      if (discountPercent != null) 'discountPercent': discountPercent,
      if (discountStartDate != null)
        'discountStartDate': discountStartDate?.toIso8601String(),
      if (discountEndDate != null)
        'discountEndDate': discountEndDate?.toIso8601String(),

      // Phân loại
      if (categoryId != null) 'categoryId': categoryId,
      if (categoryName != null) 'categoryName': categoryName,
      if (tags != null) 'tags': tags,

      // Thuộc tính
      if (colors != null) 'colors': colors,
      if (sizes != null) 'sizes': sizes,
      if (brand != null) 'brand': brand,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,

      // Kích thước & Trọng lượng
      if (weight != null) 'weight': weight,
      if (length != null) 'length': length,
      if (width != null) 'width': width,
      if (height != null) 'height': height,

      // Tồn kho & Trạng thái
      if (stock != null) 'stock': stock,
      if (minStock != null) 'minStock': minStock,
      if (status != null) 'status': status,
      if (inStock != null) 'inStock': inStock,

      // Thống kê & Đánh giá
      if (soldCount != null) 'soldCount': soldCount,
      if (viewCount != null) 'viewCount': viewCount,
      if (featured != null) 'featured': featured,
      'rating': rating,
      'ratingCount': ratingCount,

      // Thời gian
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
      if (publishedAt != null) 'publishedAt': publishedAt?.toIso8601String(),
    };
  }

  /// Copy với các giá trị mới (useful cho update)
  ProductModel copyWith({
    String? id,
    String? name,
    double? price,
    String? imageUrl,
    List<String>? images,
    String? description,
    String? longDescription,
    String? shortDescription,
    double? discountPercent,
    double? originalPrice,
    DateTime? discountStartDate,
    DateTime? discountEndDate,
    String? categoryId,
    String? categoryName,
    List<String>? tags,
    List<String>? colors,
    List<String>? sizes,
    String? brand,
    String? sku,
    String? barcode,
    double? weight,
    double? length,
    double? width,
    double? height,
    int? stock,
    int? minStock,
    String? status,
    bool? inStock,
    int? soldCount,
    int? viewCount,
    bool? featured,
    double? rating,
    int? ratingCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      description: description ?? this.description,
      longDescription: longDescription ?? this.longDescription,
      shortDescription: shortDescription ?? this.shortDescription,
      discountPercent: discountPercent ?? this.discountPercent,
      originalPrice: originalPrice ?? this.originalPrice,
      discountStartDate: discountStartDate ?? this.discountStartDate,
      discountEndDate: discountEndDate ?? this.discountEndDate,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      tags: tags ?? this.tags,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
      brand: brand ?? this.brand,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      weight: weight ?? this.weight,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      status: status ?? this.status,
      inStock: inStock ?? this.inStock,
      soldCount: soldCount ?? this.soldCount,
      viewCount: viewCount ?? this.viewCount,
      featured: featured ?? this.featured,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}
