/// Validators - Các hàm validation cho form inputs

/// Validate email
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Vui lòng nhập email';
  }

  // Regex pattern cho email
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  if (!emailRegex.hasMatch(value)) {
    return 'Email không hợp lệ';
  }

  return null;
}

/// Validate password
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Vui lòng nhập mật khẩu';
  }

  if (value.length < 6) {
    return 'Mật khẩu phải có ít nhất 6 ký tự';
  }

  return null;
}

/// Validate confirm password
String? validateConfirmPassword(String? password, String? confirmPassword) {
  if (confirmPassword == null || confirmPassword.isEmpty) {
    return 'Vui lòng xác nhận mật khẩu';
  }

  if (password != confirmPassword) {
    return 'Mật khẩu xác nhận không khớp';
  }

  return null;
}

/// Validate full name
String? validateFullName(String? value) {
  if (value == null || value.isEmpty) {
    return 'Vui lòng nhập họ và tên';
  }

  if (value.trim().length < 2) {
    return 'Họ và tên phải có ít nhất 2 ký tự';
  }

  return null;
}

/// Validate address
String? validateAddress(String? value) {
  if (value == null || value.isEmpty) {
    return 'Vui lòng nhập địa chỉ';
  }

  if (value.trim().length < 5) {
    return 'Địa chỉ phải có ít nhất 5 ký tự';
  }

  return null;
}

/// Validate phone number (Vietnam format)
String? validatePhone(String? value) {
  if (value == null || value.isEmpty) {
    return 'Vui lòng nhập số điện thoại';
  }

  // Regex pattern cho số điện thoại Việt Nam
  // Hỗ trợ: 09xx, 08xx, 07xx, 03xx, 05xx, 02xx
  final phoneRegex = RegExp(r'^(0[2|3|5|7|8|9])+([0-9]{8,9})$');

  if (!phoneRegex.hasMatch(value)) {
    return 'Số điện thoại không hợp lệ (VD: 0912345678)';
  }

  return null;
}
