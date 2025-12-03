import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/injection/service_locator.dart';
import '../../../core/services/mongo_service.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/product_model.dart';
import '../../config/themes/app_colors.dart';

/// AddEditProductScreen - Màn hình thêm/sửa sản phẩm cho Admin
///
/// Nếu [product] != null: Chế độ sửa
/// Nếu [product] == null: Chế độ thêm mới
class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final MongoService _mongoService = getIt<MongoService>();
  final CloudinaryService _cloudinaryService = getIt<CloudinaryService>();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController();

  // State
  String? _imageUrl;
  File? _selectedImageFile;
  bool _isUploading = false;
  bool _isSaving = false;
  String? _selectedCategory; // Category được chọn

  // Sử dụng danh sách categories từ AppConstants để đảm bảo đồng bộ

  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      // Chế độ sửa: điền dữ liệu hiện có
      final product = widget.product!;
      _nameController.text = product.name;
      _priceController.text = product.price.toStringAsFixed(0);
      _descriptionController.text = product.description ?? '';
      _stockController.text = product.stock?.toString() ?? '0';
      _imageUrl = product.imageUrl;
      _selectedCategory = product.categoryName; // Load category hiện tại
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  /// Chọn ảnh từ gallery hoặc camera
  Future<void> _pickImage() async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chọn ảnh sản phẩm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _selectedImageFile = File(image.path);
        _imageUrl = null; // Clear old URL, will upload new one
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Upload ảnh lên Cloudinary
  Future<String?> _uploadImage() async {
    if (_selectedImageFile == null) {
      // Nếu không có ảnh mới, dùng ảnh cũ (nếu có)
      return _imageUrl;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String? uploadedUrl;
      if (kIsWeb) {
        // Trên web, đọc bytes
        final bytes = await _selectedImageFile!.readAsBytes();
        final filename = _selectedImageFile!.path.split('/').last;
        uploadedUrl = await _cloudinaryService.uploadImageFromBytes(
          bytes,
          filename: filename.isNotEmpty
              ? filename
              : 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
          folder: 'products',
        );
      } else {
        // Trên mobile/desktop, dùng File
        uploadedUrl = await _cloudinaryService.uploadImage(
          _selectedImageFile!,
          folder: 'products',
        );
      }

      if (uploadedUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể upload ảnh. Vui lòng thử lại.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return null;
      }

      return uploadedUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi upload ảnh: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  /// Lưu sản phẩm (thêm mới hoặc cập nhật)
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Kiểm tra có ảnh không
    if (_imageUrl == null && _selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ảnh sản phẩm'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Upload ảnh nếu có ảnh mới
      String? finalImageUrl = _imageUrl;
      if (_selectedImageFile != null) {
        finalImageUrl = await _uploadImage();
        if (finalImageUrl == null) {
          setState(() {
            _isSaving = false;
          });
          return;
        }
      }

      // Tạo ProductModel
      final product = ProductModel(
        id: _isEditMode ? widget.product!.id : '', // Sẽ được tạo bởi MongoDB
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imageUrl: finalImageUrl,
        stock: int.tryParse(_stockController.text.trim()) ?? 0,
        status: 'active',
        inStock: (int.tryParse(_stockController.text.trim()) ?? 0) > 0,
        categoryName: _selectedCategory, // Lưu category được chọn
        createdAt: _isEditMode ? widget.product!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Lưu vào MongoDB
      bool success;
      if (_isEditMode) {
        print("🔄 [UI] Bắt đầu update product: ${widget.product!.id}");
        success = await _mongoService.updateProduct(
          widget.product!.id,
          product,
        );
        print("🔄 [UI] Kết quả update: $success");
      } else {
        final productId = await _mongoService.addProduct(product);
        success = productId != null;
      }

      print("🔄 [UI] Final success value: $success");
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode
                    ? 'Đã cập nhật sản phẩm thành công'
                    : 'Đã thêm sản phẩm thành công',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true); // Return true để refresh list
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể lưu sản phẩm. Vui lòng thử lại.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Sửa sản phẩm' : 'Thêm sản phẩm mới'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ảnh sản phẩm
              _buildImageSection(),
              const SizedBox(height: 24),

              // Tên sản phẩm
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên sản phẩm *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên sản phẩm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Giá
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Giá (₫) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập giá sản phẩm';
                  }
                  final price = double.tryParse(value.trim());
                  if (price == null || price <= 0) {
                    return 'Giá phải là số dương';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Số lượng tồn kho
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Số lượng tồn kho',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final stock = int.tryParse(value.trim());
                    if (stock != null && stock < 0) {
                      return 'Số lượng không được âm';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Danh mục (Category)
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Danh mục sản phẩm',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                hint: const Text('Chọn danh mục'),
                items: AppConstants.productCategories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  // Category không bắt buộc, nhưng nên có để filter dễ hơn
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mô tả
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả sản phẩm',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                minLines: 3,
              ),
              const SizedBox(height: 32),

              // Nút Lưu
              ElevatedButton(
                onPressed: (_isSaving || _isUploading) ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: (_isSaving || _isUploading)
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.white,
                          ),
                        ),
                      )
                    : Text(
                        _isEditMode ? 'Cập nhật sản phẩm' : 'Thêm sản phẩm',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget hiển thị phần chọn ảnh
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ảnh sản phẩm *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isUploading ? null : _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.textSecondary,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surface,
            ),
            child: _isUploading
                ? const Center(child: CircularProgressIndicator())
                : _buildImagePreview(),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _isUploading ? null : _pickImage,
          icon: const Icon(Icons.image),
          label: const Text('Chọn ảnh'),
        ),
      ],
    );
  }

  /// Widget hiển thị preview ảnh
  Widget _buildImagePreview() {
    // Nếu có ảnh mới được chọn
    if (_selectedImageFile != null) {
      if (kIsWeb) {
        // Trên web, hiển thị placeholder vì không thể hiển thị File trực tiếp
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 48, color: AppColors.textSecondary),
              SizedBox(height: 8),
              Text(
                'Ảnh đã được chọn',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      } else {
        // Trên mobile/desktop, hiển thị ảnh từ file
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(_selectedImageFile!, fit: BoxFit.cover),
        );
      }
    }

    // Nếu có URL ảnh (ảnh cũ hoặc đã upload)
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: _imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Center(
            child: Icon(
              Icons.image_not_supported,
              size: 48,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    // Không có ảnh
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 48,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 8),
          Text(
            'Chọn ảnh sản phẩm',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
