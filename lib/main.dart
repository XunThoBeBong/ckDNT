import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/core/injection/service_locator.dart';
// import 'src/core/services/mongo_connection_test.dart'; // Uncomment để test MongoDB
import 'src/presentation/config/themes/app_theme.dart';
import 'src/presentation/config/routes/app_router.dart';
import 'src/logic/cart/cart_bloc.dart';
import 'src/logic/auth/auth_bloc.dart';
import 'src/logic/theme/theme_bloc.dart';
import 'src/logic/theme/theme_event.dart';
import 'src/logic/theme/theme_state.dart';

// Conditional import cho web camera delegate
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'src/core/services/web_camera_delegate_stub.dart'
    if (dart.library.html) 'src/core/services/web_camera_delegate.dart';

void main() async {
  // Đảm bảo Flutter binding được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables từ file .env
  try {
    await dotenv.load(fileName: ".env");
    print("✅ Đã load file .env thành công");

    // Kiểm tra xem connection string có được load không
    final connString = dotenv.env['MONGO_CONNECTION_STRING'];
    if (connString != null && connString.isNotEmpty) {
      print("✅ Đã tìm thấy MONGO_CONNECTION_STRING trong .env");
      // Mask password trong log để bảo mật
      final maskedString = connString.replaceAll(
        RegExp(r':([^:@]+)@'),
        ':****@',
      );
      print("📝 Connection string: $maskedString");
    } else {
      print("⚠️ CẢNH BÁO: MONGO_CONNECTION_STRING không có trong .env");
      print("📝 Sẽ sử dụng giá trị mặc định (hardcode)");
    }
  } catch (e) {
    print("⚠️ Không thể load file .env: $e");
    print(
      "📝 Đảm bảo file .env tồn tại trong thư mục root của project (ecommerce/.env)",
    );
    print("📝 Nội dung file .env nên là:");
    print(
      "   MONGO_CONNECTION_STRING=mongodb+srv://username:password@cluster.mongodb.net/database?retryWrites=true&w=majority",
    );
  }

  // Khởi tạo tất cả services (Storage, API Client, MongoDB, etc.)
  await setupServiceLocator();

  // Cấu hình camera delegate cho web
  if (kIsWeb) {
    try {
      final ImagePickerPlatform instance = ImagePickerPlatform.instance;
      if (instance is CameraDelegatingImagePickerPlatform) {
        instance.cameraDelegate = WebCameraDelegate();
        print('✅ Đã cấu hình camera delegate cho web');
      }
    } catch (e) {
      print('⚠️ Không thể cấu hình camera delegate: $e');
      print('📝 Camera có thể không hoạt động trên web');
    }
  }

  // TEST: Chạy test kết nối MongoDB (có thể comment lại sau khi test xong)
  // Uncomment dòng dưới để test kết nối và xem log chi tiết
  // await testMongoConnection();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => CartBloc()),
        BlocProvider(create: (context) => AuthBloc()),
        BlocProvider(
          create: (context) => ThemeBloc()..add(const LoadThemeRequested()),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final isDarkMode = themeState is ThemeLoaded && themeState.isDarkMode;

          return MaterialApp.router(
            title: 'Flutter Ecommerce',
            debugShowCheckedModeBanner: false,

            // Áp dụng Theme dựa trên state
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

            // Áp dụng Router đã cấu hình
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
