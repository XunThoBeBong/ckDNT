import 'package:flutter/material.dart';
import '../../config/themes/app_colors.dart';

/// CustomTextField - Widget nhập liệu dùng chung
///
/// Widget tái sử dụng cho tất cả các form trong app
/// Hỗ trợ đầy đủ tính năng: validation, icons, password visibility, etc.
class CustomTextField extends StatefulWidget {
  /// Controller cho TextField
  final TextEditingController? controller;

  /// Label text (hiển thị phía trên khi focus hoặc có giá trị)
  final String? labelText;

  /// Hint text (placeholder)
  final String? hintText;

  /// Prefix icon (icon bên trái)
  final IconData? prefixIcon;

  /// Suffix icon (icon bên phải) - nếu không set, sẽ tự động thêm cho password
  final Widget? suffixIcon;

  /// Validator function
  final String? Function(String?)? validator;

  /// Keyboard type
  final TextInputType? keyboardType;

  /// Text input action (Next, Done, etc.)
  final TextInputAction? textInputAction;

  /// Callback khi submit (Enter/Done)
  final void Function(String)? onFieldSubmitted;

  /// Số dòng (cho multiline)
  final int? maxLines;

  /// Số dòng tối thiểu
  final int? minLines;

  /// Có phải password field không
  final bool obscureText;

  /// Có bật password visibility toggle không (chỉ dùng khi obscureText = true)
  final bool enablePasswordToggle;

  /// Có bắt buộc không (hiển thị dấu *)
  final bool isRequired;

  /// Có bật auto focus không
  final bool autofocus;

  /// Read only
  final bool readOnly;

  /// Enabled
  final bool enabled;

  /// Max length
  final int? maxLength;

  /// Initial value
  final String? initialValue;

  /// On changed callback
  final void Function(String)? onChanged;

  /// On tap callback
  final void Function()? onTap;

  /// Focus node
  final FocusNode? focusNode;

  /// Custom decoration (nếu muốn override hoàn toàn)
  final InputDecoration? decoration;

  /// Custom style
  final TextStyle? style;

  const CustomTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.enablePasswordToggle = true,
    this.isRequired = false,
    this.autofocus = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLength,
    this.initialValue,
    this.onChanged,
    this.onTap,
    this.focusNode,
    this.decoration,
    this.style,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    // Chỉ dispose controller nếu chúng ta tự tạo (không phải từ widget)
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Xử lý label text với dấu * nếu required
    String? displayLabelText = widget.labelText;
    if (widget.isRequired && displayLabelText != null) {
      displayLabelText = '$displayLabelText *';
    }

    // Xử lý suffix icon cho password
    Widget? suffixIcon = widget.suffixIcon;
    if (widget.obscureText &&
        widget.enablePasswordToggle &&
        widget.suffixIcon == null) {
      suffixIcon = IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    // Tạo decoration mặc định
    final defaultDecoration = InputDecoration(
      labelText: displayLabelText,
      hintText: widget.hintText,
      prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      filled: true,
      fillColor: widget.enabled
          ? AppColors.surface
          : AppColors.surface.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return TextFormField(
      controller: widget.controller ?? _controller,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      obscureText: _obscureText,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      maxLength: widget.maxLength,
      initialValue: widget.initialValue,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      focusNode: widget.focusNode,
      validator: widget.validator,
      style: widget.style,
      decoration: widget.decoration ?? defaultDecoration,
    );
  }
}
