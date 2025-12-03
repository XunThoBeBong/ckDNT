import 'package:equatable/equatable.dart';

/// ThemeState - Base class cho tất cả states của ThemeBloc
abstract class ThemeState extends Equatable {
  const ThemeState();

  @override
  List<Object?> get props => [];
}

/// ThemeInitial - State khởi tạo (chưa biết theme)
class ThemeInitial extends ThemeState {
  const ThemeInitial();
}

/// ThemeLoaded - State đã load theme
class ThemeLoaded extends ThemeState {
  final bool isDarkMode;

  const ThemeLoaded({required this.isDarkMode});

  @override
  List<Object?> get props => [isDarkMode];
}

