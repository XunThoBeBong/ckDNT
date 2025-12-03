import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/storage_service.dart';
import 'theme_event.dart';
import 'theme_state.dart';

/// ThemeBloc - Quản lý logic chuyển đổi theme (light/dark)
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeInitial()) {
    on<LoadThemeRequested>(_onLoadThemeRequested);
    on<ToggleThemeRequested>(_onToggleThemeRequested);
    on<SetThemeRequested>(_onSetThemeRequested);
  }

  Future<void> _onLoadThemeRequested(
    LoadThemeRequested event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      // Load theme preference từ storage
      final isDarkMode = StorageService.getBool('isDarkMode') ?? false;
      emit(ThemeLoaded(isDarkMode: isDarkMode));
    } catch (e) {
      // Nếu lỗi, mặc định là light mode
      emit(const ThemeLoaded(isDarkMode: false));
    }
  }

  Future<void> _onToggleThemeRequested(
    ToggleThemeRequested event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final currentState = state;
      bool newIsDarkMode;

      if (currentState is ThemeLoaded) {
        newIsDarkMode = !currentState.isDarkMode;
      } else {
        // Nếu chưa load, mặc định là light mode, toggle sang dark
        newIsDarkMode = true;
      }

      // Lưu vào storage
      await StorageService.setBool('isDarkMode', newIsDarkMode);

      emit(ThemeLoaded(isDarkMode: newIsDarkMode));
    } catch (e) {
      // Nếu lỗi, giữ nguyên state hiện tại
      if (state is ThemeLoaded) {
        emit(state);
      } else {
        emit(const ThemeLoaded(isDarkMode: false));
      }
    }
  }

  Future<void> _onSetThemeRequested(
    SetThemeRequested event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      // Lưu vào storage
      await StorageService.setBool('isDarkMode', event.isDarkMode);
      emit(ThemeLoaded(isDarkMode: event.isDarkMode));
    } catch (e) {
      // Nếu lỗi, giữ nguyên state hiện tại
      if (state is ThemeLoaded) {
        emit(state);
      } else {
        emit(const ThemeLoaded(isDarkMode: false));
      }
    }
  }
}
