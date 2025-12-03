// Stub file cho non-web platforms
// File này sẽ không được sử dụng trên web
// Chỉ để tránh lỗi import khi compile cho mobile/desktop

import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:image_picker/image_picker.dart';

/// Stub implementation - không được sử dụng
class WebCameraDelegate extends ImagePickerCameraDelegate {
  @override
  Future<XFile?> takePhoto({
    ImagePickerCameraDelegateOptions options =
        const ImagePickerCameraDelegateOptions(),
  }) async {
    throw UnimplementedError('WebCameraDelegate chỉ hoạt động trên web');
  }

  @override
  Future<XFile?> takeVideo({
    ImagePickerCameraDelegateOptions options =
        const ImagePickerCameraDelegateOptions(),
  }) async {
    throw UnimplementedError('WebCameraDelegate chỉ hoạt động trên web');
  }
}
