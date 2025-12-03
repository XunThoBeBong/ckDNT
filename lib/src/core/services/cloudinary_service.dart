import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;
import 'package:crypto/crypto.dart' show sha1;

/// CloudinaryService - Service để upload ảnh lên Cloudinary
///
/// Sử dụng Cloudinary để lưu trữ ảnh avatar của user
/// Cần cấu hình trong .env:
/// - CLOUDINARY_CLOUD_NAME
/// - CLOUDINARY_API_KEY
/// - CLOUDINARY_API_SECRET
class CloudinaryService {
  static CloudinaryService? _instance;
  String? _cloudName;
  String? _apiKey;
  String? _apiSecret;

  CloudinaryService._internal();
  factory CloudinaryService() {
    _instance ??= CloudinaryService._internal();
    return _instance!;
  }

  /// Khởi tạo Cloudinary với credentials từ .env
  Future<void> initialize() async {
    try {
      _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
      _apiKey = dotenv.env['CLOUDINARY_API_KEY'];
      _apiSecret = dotenv.env['CLOUDINARY_API_SECRET'];

      if (_cloudName == null || _apiKey == null || _apiSecret == null) {
        developer.log(
          '⚠️ Cloudinary credentials chưa được cấu hình trong .env',
          name: 'CloudinaryService',
        );
        print('⚠️ CẢNH BÁO: Cloudinary credentials chưa được cấu hình');
        print('📝 Thêm vào file .env:');
        print('   CLOUDINARY_CLOUD_NAME=your_cloud_name');
        print('   CLOUDINARY_API_KEY=your_api_key');
        print('   CLOUDINARY_API_SECRET=your_api_secret');
        return;
      }

      developer.log(
        '✅ CloudinaryService đã được khởi tạo thành công',
        name: 'CloudinaryService',
      );
    } catch (e) {
      developer.log(
        '❌ Lỗi khởi tạo CloudinaryService: $e',
        name: 'CloudinaryService',
      );
      print('❌ Lỗi khởi tạo CloudinaryService: $e');
    }
  }

  /// Upload ảnh lên Cloudinary từ File
  ///
  /// [imageFile]: File ảnh cần upload
  /// [folder]: Thư mục lưu trữ trên Cloudinary (mặc định: 'avatars')
  /// [publicId]: ID công khai cho ảnh (nếu null sẽ tự động generate)
  ///
  /// Trả về URL của ảnh đã upload, hoặc null nếu thất bại
  Future<String?> uploadImage(
    File imageFile, {
    String folder = 'avatars',
    String? publicId,
  }) async {
    try {
      developer.log(
        '📁 Đang đọc file: ${imageFile.path}',
        name: 'CloudinaryService',
      );

      // Kiểm tra file có tồn tại không
      if (!await imageFile.exists()) {
        developer.log(
          '❌ File không tồn tại: ${imageFile.path}',
          name: 'CloudinaryService',
        );
        throw Exception('File không tồn tại: ${imageFile.path}');
      }

      // Đọc bytes từ file
      final imageBytes = await imageFile.readAsBytes();
      developer.log(
        '✅ Đã đọc ${imageBytes.length} bytes từ file',
        name: 'CloudinaryService',
      );

      if (imageBytes.isEmpty) {
        developer.log('❌ File rỗng (0 bytes)', name: 'CloudinaryService');
        throw Exception('File ảnh rỗng (0 bytes)');
      }

      // Lấy tên file
      final filename = imageFile.path.split('/').last;
      if (filename.isEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final defaultFilename = 'image_$timestamp.jpg';
        developer.log(
          '⚠️ Tên file rỗng, dùng tên mặc định: $defaultFilename',
          name: 'CloudinaryService',
        );
        return uploadImageFromBytes(
          imageBytes,
          filename: defaultFilename,
          folder: folder,
          publicId: publicId,
        );
      }

      return uploadImageFromBytes(
        imageBytes,
        filename: filename,
        folder: folder,
        publicId: publicId,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Lỗi đọc file: $e',
        name: 'CloudinaryService',
        error: e,
        stackTrace: stackTrace,
      );
      print('❌ Lỗi đọc file để upload: $e');
      rethrow; // Re-throw để caller xử lý
    }
  }

  /// Upload ảnh lên Cloudinary từ bytes (hỗ trợ web)
  ///
  /// [imageBytes]: Bytes của ảnh cần upload
  /// [filename]: Tên file (cho web, có thể là 'image.jpg')
  /// [folder]: Thư mục lưu trữ trên Cloudinary (mặc định: 'avatars')
  /// [publicId]: ID công khai cho ảnh (nếu null sẽ tự động generate)
  ///
  /// Trả về URL của ảnh đã upload, hoặc null nếu thất bại
  Future<String?> uploadImageFromBytes(
    List<int> imageBytes, {
    String filename = 'image.jpg',
    String folder = 'avatars',
    String? publicId,
  }) async {
    if (_cloudName == null || _apiKey == null || _apiSecret == null) {
      await initialize();
      if (_cloudName == null || _apiKey == null || _apiSecret == null) {
        developer.log(
          '❌ Cloudinary chưa được khởi tạo',
          name: 'CloudinaryService',
        );
        return null;
      }
    }

    try {
      // Kiểm tra kích thước file (Cloudinary free plan giới hạn 10MB)
      const maxFileSize = 10 * 1024 * 1024; // 10MB
      if (imageBytes.length > maxFileSize) {
        developer.log(
          '⚠️ File quá lớn: ${imageBytes.length} bytes (max: $maxFileSize bytes)',
          name: 'CloudinaryService',
        );
        print(
          '⚠️ [CLOUDINARY] File quá lớn: ${(imageBytes.length / 1024 / 1024).toStringAsFixed(2)}MB (max: 10MB)',
        );
        throw Exception(
          'File ảnh quá lớn (${(imageBytes.length / 1024 / 1024).toStringAsFixed(2)}MB). Vui lòng chọn ảnh nhỏ hơn 10MB hoặc resize ảnh trước khi upload.',
        );
      }

      developer.log(
        '📤 Đang upload ảnh lên Cloudinary... (${(imageBytes.length / 1024 / 1024).toStringAsFixed(2)}MB)',
        name: 'CloudinaryService',
      );

      // Tạo publicId nếu chưa có
      final finalPublicId =
          publicId ?? 'avatar_${DateTime.now().millisecondsSinceEpoch}';
      final fullPublicId = folder.isNotEmpty
          ? '$folder/$finalPublicId'
          : finalPublicId;

      // Tạo timestamp và signature cho authentication
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final transformation = 'w_400,h_400,c_fill,g_face,q_auto,f_auto';
      final signature = _generateSignature(
        timestamp: timestamp,
        publicId: fullPublicId,
        folder: folder,
        transformation: transformation,
      );

      // Tạo multipart request
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields.addAll({
          'timestamp': timestamp.toString(),
          'api_key': _apiKey!,
          'signature': signature,
          'public_id': fullPublicId,
          'folder': folder,
          'transformation': transformation,
        })
        ..files.add(
          http.MultipartFile.fromBytes('file', imageBytes, filename: filename),
        );

      // Gửi request
      developer.log(
        '📤 Đang gửi request lên Cloudinary...',
        name: 'CloudinaryService',
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      developer.log(
        '📥 Nhận response: ${response.statusCode}',
        name: 'CloudinaryService',
      );

      if (response.statusCode == 200) {
        try {
          final responseData =
              json.decode(response.body) as Map<String, dynamic>;
          final secureUrl = responseData['secure_url'] as String?;

          if (secureUrl != null) {
            developer.log(
              '✅ Upload ảnh thành công: $secureUrl',
              name: 'CloudinaryService',
            );
            return secureUrl;
          } else {
            developer.log(
              '❌ Upload ảnh thất bại: Không có secure_url trong response',
              name: 'CloudinaryService',
            );
            developer.log(
              'Response data: $responseData',
              name: 'CloudinaryService',
            );
            return null;
          }
        } catch (e) {
          developer.log(
            '❌ Lỗi parse response: $e',
            name: 'CloudinaryService',
            error: e,
          );
          print('❌ Lỗi parse response: $e');
          print('Response body: ${response.body}');
          return null;
        }
      } else {
        developer.log(
          '❌ Upload ảnh thất bại: ${response.statusCode}',
          name: 'CloudinaryService',
        );
        developer.log(
          'Response body: ${response.body}',
          name: 'CloudinaryService',
        );
        print('❌ Upload ảnh thất bại: ${response.statusCode}');
        print('Response: ${response.body}');

        // Phân tích lỗi cụ thể
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage =
              errorData['error']?['message'] ?? 'Unknown error';
          developer.log(
            'Error message: $errorMessage',
            name: 'CloudinaryService',
          );
          print('Error message: $errorMessage');
        } catch (e) {
          // Ignore parse error
        }

        return null;
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Lỗi upload ảnh: $e',
        name: 'CloudinaryService',
        error: e,
        stackTrace: stackTrace,
      );
      print('❌ Lỗi upload ảnh lên Cloudinary: $e');
      return null;
    }
  }

  /// Tạo signature cho Cloudinary API
  ///
  /// Tất cả các parameters (trừ api_key và file) phải được include trong signature
  /// [skipFolderIfPublicIdHasPath]: Nếu true, không thêm folder vào signature khi publicId đã chứa path (có dấu /)
  ///                                 Dùng cho delete operation. Upload luôn cần folder parameter.
  String _generateSignature({
    required int timestamp,
    required String publicId,
    String? folder,
    String? transformation,
    bool skipFolderIfPublicIdHasPath = false,
  }) {
    // Tạo string để sign - bao gồm tất cả parameters
    final params = <String>[];

    // Thêm folder nếu có
    // Với delete: Nếu publicId đã chứa folder (có dấu /), không thêm folder vào signature
    // Với upload: Luôn thêm folder vào signature (nếu có)
    if (folder != null && folder.isNotEmpty) {
      if (skipFolderIfPublicIdHasPath && publicId.contains('/')) {
        // Skip folder cho delete operation khi publicId đã có path
      } else {
        params.add('folder=$folder');
      }
    }

    // Thêm public_id
    params.add('public_id=$publicId');

    // Thêm timestamp
    params.add('timestamp=$timestamp');

    // Thêm transformation nếu có
    if (transformation != null && transformation.isNotEmpty) {
      params.add('transformation=$transformation');
    }

    // Sort params theo thứ tự alphabet (Cloudinary yêu cầu)
    params.sort();

    // Join và thêm api_secret
    final signString = params.join('&') + _apiSecret!;

    print("🔐 [CLOUDINARY] Signature params: $params");
    print("🔐 [CLOUDINARY] Sign string (without secret): ${params.join('&')}");

    // Hash SHA-1
    final bytes = utf8.encode(signString);
    final digest = sha1.convert(bytes);
    final signature = digest.toString();

    print("🔐 [CLOUDINARY] Generated signature: $signature");

    return signature;
  }

  /// Xóa ảnh trên Cloudinary
  ///
  /// [publicId]: ID công khai của ảnh cần xóa
  /// [folder]: Thư mục chứa ảnh
  ///
  /// Trả về true nếu xóa thành công, false nếu thất bại
  Future<bool> deleteImage(String publicId, {String folder = 'avatars'}) async {
    print(
      "🗑️ [CLOUDINARY] deleteImage - publicId: $publicId, folder: $folder",
    );

    if (_cloudName == null || _apiKey == null || _apiSecret == null) {
      print("🗑️ [CLOUDINARY] Chưa khởi tạo, đang initialize...");
      await initialize();
      if (_cloudName == null || _apiKey == null || _apiSecret == null) {
        print("❌ [CLOUDINARY] Không thể khởi tạo Cloudinary credentials");
        return false;
      }
    }

    try {
      // Nếu publicId đã chứa folder (có dấu /), không cần thêm folder nữa
      final fullPublicId = publicId.contains('/')
          ? publicId
          : (folder.isNotEmpty ? '$folder/$publicId' : publicId);
      print("🗑️ [CLOUDINARY] fullPublicId: $fullPublicId");

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // Với delete: Nếu fullPublicId đã chứa folder (có dấu /), không truyền folder vào signature
      // Vì Cloudinary chỉ cần public_id với full path, không cần folder riêng
      final signature = _generateSignature(
        timestamp: timestamp,
        publicId: fullPublicId,
        folder: folder,
        skipFolderIfPublicIdHasPath:
            true, // Skip folder nếu publicId đã có path (cho delete)
      );

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/destroy',
      );

      print("🗑️ [CLOUDINARY] Request URL: $uri");
      print(
        "🗑️ [CLOUDINARY] Request body: public_id=$fullPublicId, timestamp=$timestamp, api_key=${_apiKey!.substring(0, 5)}...",
      );

      final response = await http.post(
        uri,
        body: {
          'public_id': fullPublicId,
          'timestamp': timestamp.toString(),
          'api_key': _apiKey!,
          'signature': signature,
        },
      );

      print("🗑️ [CLOUDINARY] Response status: ${response.statusCode}");
      print("🗑️ [CLOUDINARY] Response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("🗑️ [CLOUDINARY] Response data: $responseData");

        if (responseData['result'] == 'ok') {
          developer.log(
            '✅ Xóa ảnh thành công: $fullPublicId',
            name: 'CloudinaryService',
          );
          print("✅ [CLOUDINARY] Xóa ảnh thành công: $fullPublicId");
          return true;
        } else {
          print(
            "⚠️ [CLOUDINARY] Response result không phải 'ok': ${responseData['result']}",
          );
        }
      } else {
        print(
          "❌ [CLOUDINARY] HTTP status code không phải 200: ${response.statusCode}",
        );
      }

      developer.log(
        '❌ Xóa ảnh thất bại: ${response.statusCode} - ${response.body}',
        name: 'CloudinaryService',
      );
      print("❌ [CLOUDINARY] Xóa ảnh thất bại");
      return false;
    } catch (e, stackTrace) {
      developer.log('❌ Lỗi xóa ảnh: $e', name: 'CloudinaryService', error: e);
      print("❌ [CLOUDINARY] Exception: $e");
      print("📍 [CLOUDINARY] Stack trace: $stackTrace");
      return false;
    }
  }

  /// Extract publicId từ Cloudinary URL
  ///
  /// [imageUrl]: URL của ảnh trên Cloudinary
  /// Trả về publicId (ví dụ: "products/product_id") hoặc null nếu không phải Cloudinary URL
  ///
  /// Hỗ trợ các format:
  /// - https://res.cloudinary.com/{cloud_name}/image/upload/{public_id}.{format}
  /// - https://res.cloudinary.com/{cloud_name}/image/upload/v{version}/{public_id}.{format}
  /// - https://res.cloudinary.com/{cloud_name}/image/upload/{transformations}/{public_id}.{format}
  /// - https://res.cloudinary.com/{cloud_name}/image/upload/v{version}/{transformations}/{public_id}.{format}
  String? extractPublicIdFromUrl(String imageUrl) {
    print("🔍 [CLOUDINARY] extractPublicIdFromUrl - Input: $imageUrl");

    if (!imageUrl.contains('cloudinary.com')) {
      print("⚠️ [CLOUDINARY] URL không chứa 'cloudinary.com'");
      return null;
    }

    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      print("🔍 [CLOUDINARY] Path segments: $pathSegments");

      // Tìm vị trí 'upload' trong path
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) {
        print("⚠️ [CLOUDINARY] Không tìm thấy 'upload' trong path");
        return null;
      }

      // Lấy phần sau 'upload'
      final segmentsAfterUpload = pathSegments.sublist(uploadIndex + 1);
      print("🔍 [CLOUDINARY] Segments after upload: $segmentsAfterUpload");

      if (segmentsAfterUpload.isEmpty) {
        print("⚠️ [CLOUDINARY] Không có segments sau 'upload'");
        return null;
      }

      // Segment cuối cùng LUÔN là public_id + extension
      // Logic đơn giản: Lấy segment cuối cùng (có extension), đó chính là public_id
      // Bỏ qua version (v...) và transformations (chứa dấu phẩy) ở giữa
      String lastValidSegment = segmentsAfterUpload.last;
      int lastValidIndex = segmentsAfterUpload.length - 1;

      // Nếu segment cuối cùng không có extension, tìm ngược lại segment có extension
      if (!lastValidSegment.contains('.')) {
        for (int i = segmentsAfterUpload.length - 2; i >= 0; i--) {
          final segment = segmentsAfterUpload[i];
          // Tìm segment có extension (đó là public_id)
          if (segment.contains('.')) {
            lastValidSegment = segment;
            lastValidIndex = i;
            break;
          }
        }
      }

      print(
        "🔍 [CLOUDINARY] Last valid segment: $lastValidSegment (index: $lastValidIndex)",
      );

      // Bỏ extension (nếu có)
      final dotIndex = lastValidSegment.lastIndexOf('.');
      final publicId = dotIndex > 0
          ? lastValidSegment.substring(0, dotIndex)
          : lastValidSegment;

      print("🔍 [CLOUDINARY] PublicId (sau khi bỏ extension): $publicId");

      // Tìm folder (các segments trước public_id, bỏ qua version và transformations)
      final folderParts = <String>[];
      if (lastValidIndex > 0) {
        for (int i = 0; i < lastValidIndex; i++) {
          final segment = segmentsAfterUpload[i];
          // Chỉ lấy segments không phải version và transformations
          if (!segment.startsWith('v') &&
              !segment.contains('_') &&
              !segment.contains(',') &&
              segment.isNotEmpty) {
            folderParts.add(segment);
          }
        }
      }

      // Gộp folder và publicId
      final finalPublicId = folderParts.isNotEmpty
          ? '${folderParts.join('/')}/$publicId'
          : publicId;

      print("🔍 [CLOUDINARY] Final publicId: $finalPublicId");

      return finalPublicId;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Lỗi extract publicId: $e',
        name: 'CloudinaryService',
        error: e,
      );
      print("❌ [CLOUDINARY] Exception trong extractPublicIdFromUrl: $e");
      print("📍 [CLOUDINARY] Stack trace: $stackTrace");
      return null;
    }
  }

  /// Xóa ảnh từ Cloudinary URL
  ///
  /// [imageUrl]: URL của ảnh trên Cloudinary
  /// Trả về true nếu xóa thành công, false nếu thất bại hoặc không phải Cloudinary URL
  Future<bool> deleteImageFromUrl(String imageUrl) async {
    print("🗑️ [CLOUDINARY] deleteImageFromUrl - Input URL: $imageUrl");

    final publicId = extractPublicIdFromUrl(imageUrl);
    print("🗑️ [CLOUDINARY] Extracted publicId: $publicId");

    if (publicId == null) {
      developer.log(
        '⚠️ Không phải Cloudinary URL hoặc không thể extract publicId: $imageUrl',
        name: 'CloudinaryService',
      );
      print("⚠️ [CLOUDINARY] Không thể extract publicId từ URL");
      return false;
    }

    // Extract folder từ publicId (nếu có)
    final parts = publicId.split('/');
    String? folder;
    String finalPublicId;
    if (parts.length > 1) {
      folder = parts.sublist(0, parts.length - 1).join('/');
      finalPublicId = parts.last;
    } else {
      finalPublicId = publicId;
      folder = null;
    }

    print(
      "🗑️ [CLOUDINARY] Folder: ${folder ?? 'null'}, finalPublicId: $finalPublicId",
    );

    final result = await deleteImage(
      finalPublicId,
      folder: folder ?? 'products',
    );
    print("🗑️ [CLOUDINARY] deleteImage result: $result");

    return result;
  }

  /// Lấy URL ảnh đã được optimize (resize, compress)
  ///
  /// [imageUrl]: URL gốc của ảnh trên Cloudinary
  /// [width]: Chiều rộng mong muốn
  /// [height]: Chiều cao mong muốn
  ///
  /// Trả về URL ảnh đã được optimize
  String getOptimizedImageUrl(String imageUrl, {int? width, int? height}) {
    if (!imageUrl.contains('cloudinary.com')) {
      return imageUrl;
    }

    try {
      // Tách URL thành các phần
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Tìm vị trí 'upload' trong path
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) {
        return imageUrl;
      }

      // Tạo transformation string
      final transformations = <String>[];
      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      transformations.addAll(['c_fill', 'q_auto', 'f_auto']);

      final transformationString = transformations.join(',');

      // Tạo URL mới với transformation
      final newPathSegments = [
        ...pathSegments.sublist(0, uploadIndex + 1),
        transformationString,
        ...pathSegments.sublist(uploadIndex + 1),
      ];

      return uri.replace(pathSegments: newPathSegments).toString();
    } catch (e) {
      developer.log(
        '❌ Lỗi tạo optimized URL: $e',
        name: 'CloudinaryService',
        error: e,
      );
      return imageUrl;
    }
  }
}
