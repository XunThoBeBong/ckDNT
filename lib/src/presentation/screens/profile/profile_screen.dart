import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/theme/theme_bloc.dart';
import '../../../logic/theme/theme_event.dart';
import '../../../logic/theme/theme_state.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/injection/service_locator.dart';
import '../../config/themes/app_colors.dart';
import '../admin/admin_product_list_screen.dart';
import 'edit_profile_screen.dart';

/// ProfileScreen - Màn hình tài khoản
///
/// Hiển thị thông tin user đang đăng nhập:
/// - Avatar (có thể upload từ Cloudinary)
/// - Tên, Email, SĐT
/// - Nút Đăng xuất
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = getIt<CloudinaryService>();
  bool _isUploading = false;

  /// Chọn ảnh từ gallery hoặc camera
  Future<void> _pickAndUploadImage() async {
    try {
      // Hiển thị dialog chọn nguồn ảnh
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chọn ảnh đại diện'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              // Hiển thị option camera (trên web sẽ yêu cầu quyền từ browser)
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

      // Chọn ảnh (trên web, browser sẽ tự xử lý camera nếu hỗ trợ)
      // Trên Android, image_picker sẽ mở camera app của hệ thống
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      print('📸 Đã chọn ảnh: ${image.path}');
      print('📸 Tên file: ${image.name}');
      print('📸 Kích thước: ${await image.length()} bytes');

      setState(() {
        _isUploading = true;
      });

      // Upload lên Cloudinary
      String? avatarUrl;
      try {
        if (kIsWeb) {
          // Trên web, XFile.path là blob URL, cần đọc bytes
          print('🌐 Đang đọc bytes từ web...');
          final bytes = await image.readAsBytes();
          final filename = image.name.isNotEmpty
              ? image.name
              : 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
          print('🌐 Đã đọc ${bytes.length} bytes, đang upload...');
          avatarUrl = await _cloudinaryService.uploadImageFromBytes(
            bytes,
            filename: filename,
            folder: 'avatars',
          );
        } else {
          // Trên mobile/desktop, dùng File trực tiếp
          print('📱 Đang kiểm tra file: ${image.path}');
          final imageFile = File(image.path);

          // Kiểm tra file có tồn tại không
          if (!await imageFile.exists()) {
            throw Exception('File ảnh không tồn tại: ${image.path}');
          }

          // Kiểm tra kích thước file
          final fileSize = await imageFile.length();
          print('📱 Kích thước file: $fileSize bytes');

          if (fileSize == 0) {
            throw Exception('File ảnh rỗng (0 bytes)');
          }

          // Kiểm tra có thể đọc file không
          try {
            final testBytes = await imageFile.readAsBytes();
            print('📱 Đã đọc ${testBytes.length} bytes từ file');
          } catch (e) {
            throw Exception('Không thể đọc file: $e');
          }

          print('📱 Đang upload lên Cloudinary...');
          avatarUrl = await _cloudinaryService.uploadImage(
            imageFile,
            folder: 'avatars',
          );
        }

        if (avatarUrl == null) {
          print('❌ Upload trả về null');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Không thể upload ảnh. Vui lòng kiểm tra kết nối mạng và thử lại.',
                ),
                backgroundColor: AppColors.error,
                duration: Duration(seconds: 5),
              ),
            );
          }
          setState(() {
            _isUploading = false;
          });
          return;
        }

        print('✅ Upload thành công: $avatarUrl');

        // Cập nhật avatar trong database
        if (mounted) {
          print('💾 Đang cập nhật avatar trong database...');
          context.read<AuthBloc>().add(
            UpdateAvatarRequested(avatarUrl: avatarUrl),
          );
        }
      } catch (uploadError, stackTrace) {
        print('❌ Lỗi trong quá trình upload: $uploadError');
        print('Stack trace: $stackTrace');
        rethrow; // Re-throw để catch block bên ngoài xử lý
      }
    } catch (e, stackTrace) {
      print('❌❌❌ LỖI CHỌN/UPLOAD ẢNH ❌❌❌');
      print('Error: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        String errorMessage = 'Lỗi: ${e.toString()}';

        // Xử lý lỗi cụ thể
        if (e.toString().contains('cameraDelegate')) {
          errorMessage =
              'Chức năng chụp ảnh không khả dụng trên platform này. '
              'Vui lòng chọn ảnh từ thư viện.';
        } else if (e.toString().contains('Permission') ||
            e.toString().contains('permission')) {
          errorMessage =
              'Bạn cần cấp quyền truy cập camera/thư viện ảnh. '
              'Vui lòng vào Cài đặt > Ứng dụng > ecommerce > Quyền để cấp quyền.';
        } else if (e.toString().contains('File') &&
            e.toString().contains('không tồn tại')) {
          errorMessage = 'Không tìm thấy file ảnh. Vui lòng chọn lại ảnh.';
        } else if (e.toString().contains('rỗng') ||
            e.toString().contains('0 bytes')) {
          errorMessage = 'File ảnh không hợp lệ. Vui lòng chọn ảnh khác.';
        } else if (e.toString().contains('không thể đọc')) {
          errorMessage =
              'Không thể đọc file ảnh. Vui lòng kiểm tra quyền truy cập.';
        } else if (e.toString().contains('network') ||
            e.toString().contains('Network') ||
            e.toString().contains('connection')) {
          errorMessage =
              'Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          // Khi logout thành công, điều hướng về màn hình đăng nhập
          if (state is AuthUnauthenticated) {
            context.go('/login');
          }
        },
        builder: (context, state) {
          // Nếu đang loading
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Nếu chưa đăng nhập hoặc lỗi
          if (state is AuthUnauthenticated || state is AuthFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_off_outlined,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state is AuthFailure ? state.message : 'Bạn chưa đăng nhập',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Đăng nhập'),
                  ),
                ],
              ),
            );
          }

          // Nếu đã đăng nhập, hiển thị thông tin user
          if (state is AuthAuthenticated) {
            final user = state.user;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar Section
                  Center(
                    child: Column(
                      children: [
                        // Avatar với khả năng upload
                        Stack(
                          children: [
                            // Avatar Image
                            GestureDetector(
                              onTap: _isUploading ? null : _pickAndUploadImage,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 4,
                                  ),
                                ),
                                child: ClipOval(
                                  child:
                                      user.avatarUrl != null &&
                                          user.avatarUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: user.avatarUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: AppColors.white,
                                              ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: AppColors.white,
                                        ),
                                ),
                              ),
                            ),
                            // Upload button overlay
                            if (!_isUploading)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                    border: Border.all(
                                      color: AppColors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            // Loading indicator
                            if (_isUploading)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Hint text
                        if (!_isUploading)
                          TextButton(
                            onPressed: _pickAndUploadImage,
                            child: const Text(
                              'Thay đổi ảnh đại diện',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Tên người dùng
                        Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        // Email
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Thông tin chi tiết
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tiêu đề
                          Text(
                            'Thông tin cá nhân',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Họ và tên
                          _buildInfoRow(
                            context,
                            icon: Icons.person_outlined,
                            label: 'Họ và tên',
                            value: user.fullName,
                          ),
                          const SizedBox(height: 16),

                          // Email
                          _buildInfoRow(
                            context,
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: user.email,
                          ),
                          const SizedBox(height: 16),

                          // Số điện thoại
                          _buildInfoRow(
                            context,
                            icon: Icons.phone_outlined,
                            label: 'Số điện thoại',
                            value: user.phone ?? 'Chưa cập nhật',
                            valueColor: user.phone != null
                                ? null
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(height: 16),

                          // Địa chỉ
                          _buildInfoRow(
                            context,
                            icon: Icons.location_on_outlined,
                            label: 'Địa chỉ',
                            value: user.address,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút Chỉnh sửa thông tin
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(user: user),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Chỉnh sửa thông tin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Nút Đơn hàng của tôi
                  _buildMenuButton(
                    icon: Icons.shopping_bag_outlined,
                    text: 'Đơn hàng của tôi',
                    color: AppColors.primary,
                    onTap: () {
                      context.push('/orders');
                    },
                  ),
                  const SizedBox(height: 12),
                  // Toggle Dark Mode
                  BlocBuilder<ThemeBloc, ThemeState>(
                    builder: (context, themeState) {
                      final isDarkMode = themeState is ThemeLoaded
                          ? themeState.isDarkMode
                          : false;
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.border, width: 1),
                        ),
                        child: SwitchListTile(
                          value: isDarkMode,
                          onChanged: (value) {
                            context.read<ThemeBloc>().add(
                              const ToggleThemeRequested(),
                            );
                          },
                          title: const Text('Chế độ tối'),
                          subtitle: Text(
                            isDarkMode
                                ? 'Đang bật chế độ tối'
                                : 'Đang bật chế độ sáng',
                          ),
                          secondary: Icon(
                            isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // --- KHU VỰC ADMIN (CHỈ HIỆN NẾU LÀ ADMIN) ---
                  if (user.isAdmin) ...[
                    _buildMenuButton(
                      icon: Icons.dashboard,
                      text: 'Quản lý sản phẩm (Admin)',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminProductListScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  // ---------------------------------------------

                  // Nút Đăng xuất
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                // Hiển thị dialog xác nhận
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Xác nhận đăng xuất'),
                                    content: const Text(
                                      'Bạn có chắc chắn muốn đăng xuất?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(dialogContext).pop(),
                                        child: const Text('Hủy'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(dialogContext).pop();
                                          // Gọi logout
                                          context.read<AuthBloc>().add(
                                            const LogoutRequested(),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                        ),
                                        child: const Text('Đăng xuất'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: isLoading
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
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout),
                                  SizedBox(width: 8),
                                  Text(
                                    'Đăng xuất',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ],
              ),
            );
          }

          // Fallback: Nếu state không xác định
          return const Center(child: Text('Trạng thái không xác định'));
        },
      ),
    );
  }

  /// Widget hiển thị một dòng thông tin
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Widget hiển thị một nút menu
  Widget _buildMenuButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color color = AppColors.textPrimary,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
