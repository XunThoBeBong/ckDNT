import 'package:equatable/equatable.dart';

/// ThemeEvent - Base class cho tất cả events của ThemeBloc
abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

/// ToggleThemeRequested - Event yêu cầu chuyển đổi theme (light/dark)
class ToggleThemeRequested extends ThemeEvent {
  const ToggleThemeRequested();
}

/// LoadThemeRequested - Event yêu cầu load theme từ storage
class LoadThemeRequested extends ThemeEvent {
  const LoadThemeRequested();
}

/// SetThemeRequested - Event yêu cầu set theme cụ thể
class SetThemeRequested extends ThemeEvent {
  final bool isDarkMode;

  const SetThemeRequested({required this.isDarkMode});

  @override
  List<Object?> get props => [isDarkMode];
}

