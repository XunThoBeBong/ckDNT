import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:image_picker/image_picker.dart';

/// WebCameraDelegate - Camera delegate cho Flutter Web
///
/// Sử dụng HTML5 MediaDevices API để truy cập camera trên web
class WebCameraDelegate extends ImagePickerCameraDelegate {
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;

  @override
  Future<XFile?> takePhoto({
    ImagePickerCameraDelegateOptions options =
        const ImagePickerCameraDelegateOptions(),
  }) async {
    try {
      // Kiểm tra xem browser có hỗ trợ MediaDevices không
      if (html.window.navigator.mediaDevices == null) {
        throw Exception('Trình duyệt không hỗ trợ truy cập camera');
      }

      // Lấy stream từ camera
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': true,
        'audio': false,
      });

      _mediaStream = stream;

      // Tạo video element để hiển thị preview
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..srcObject = stream;

      // Hiển thị dialog với video preview và nút chụp
      final captured = await _showCameraDialog();

      if (!captured) {
        _stopCamera();
        return null;
      }

      // Chụp ảnh từ video
      if (_videoElement == null) {
        _stopCamera();
        return null;
      }

      final canvas = html.CanvasElement(
        width: _videoElement!.videoWidth,
        height: _videoElement!.videoHeight,
      );
      final ctx = canvas.context2D;
      ctx.drawImage(_videoElement!, 0, 0);

      // Convert canvas sang blob
      final blob = await canvas.toBlob('image/jpeg', 0.85);

      // Convert blob sang bytes
      final reader = html.FileReader();
      final completer = Completer<Uint8List>();
      reader.onLoadEnd.listen((_) {
        completer.complete(reader.result as Uint8List);
      });
      reader.readAsArrayBuffer(blob);
      final bytes = await completer.future;

      _stopCamera();

      // Tạo XFile từ bytes
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return XFile.fromData(
        bytes,
        mimeType: 'image/jpeg',
        name: 'camera_$timestamp.jpg',
      );
    } catch (e) {
      _stopCamera();
      throw Exception('Không thể truy cập camera: $e');
    }
  }

  @override
  Future<XFile?> takeVideo({
    ImagePickerCameraDelegateOptions options =
        const ImagePickerCameraDelegateOptions(),
  }) async {
    // Chưa implement video, chỉ hỗ trợ photo
    throw UnimplementedError('Video recording chưa được hỗ trợ');
  }

  /// Hiển thị dialog với camera preview
  Future<bool> _showCameraDialog() async {
    final completer = Completer<bool>();

    // Tạo overlay
    final overlay = html.DivElement()
      ..style.position = 'fixed'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'rgba(0, 0, 0, 0.9)'
      ..style.zIndex = '9999'
      ..style.display = 'flex'
      ..style.flexDirection = 'column'
      ..style.alignItems = 'center'
      ..style.justifyContent = 'center';

    // Container cho video
    final videoContainer = html.DivElement()
      ..style.position = 'relative'
      ..style.maxWidth = '90%'
      ..style.maxHeight = '80%';

    if (_videoElement != null) {
      _videoElement!.style.width = '100%';
      _videoElement!.style.height = 'auto';
      _videoElement!.style.maxHeight = '70vh';
      videoContainer.append(_videoElement!);
    }

    // Buttons container
    final buttonsContainer = html.DivElement()
      ..style.marginTop = '20px'
      ..style.display = 'flex'
      ..style.gap = '10px';

    // Capture button
    final captureBtn = html.ButtonElement()
      ..text = 'Chụp ảnh'
      ..style.padding = '12px 24px'
      ..style.fontSize = '16px'
      ..style.backgroundColor = '#E94057'
      ..style.color = 'white'
      ..style.border = 'none'
      ..style.borderRadius = '8px'
      ..style.cursor = 'pointer'
      ..onClick.listen((_) {
        completer.complete(true);
        overlay.remove();
      });

    // Cancel button
    final cancelBtn = html.ButtonElement()
      ..text = 'Hủy'
      ..style.padding = '12px 24px'
      ..style.fontSize = '16px'
      ..style.backgroundColor = '#666'
      ..style.color = 'white'
      ..style.border = 'none'
      ..style.borderRadius = '8px'
      ..style.cursor = 'pointer'
      ..onClick.listen((_) {
        completer.complete(false);
        overlay.remove();
      });

    buttonsContainer.append(captureBtn);
    buttonsContainer.append(cancelBtn);

    overlay.append(videoContainer);
    overlay.append(buttonsContainer);

    html.document.body!.append(overlay);

    return completer.future;
  }

  /// Dừng camera stream
  void _stopCamera() {
    _mediaStream?.getTracks().forEach((track) => track.stop());
    _mediaStream = null;
    _videoElement = null;
  }
}
