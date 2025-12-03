import 'package:flutter/material.dart';
import '../../../core/injection/service_locator.dart';
import '../../../core/services/mongo_service.dart';

/// Màn hình test kết nối MongoDB
class MongoTestScreen extends StatefulWidget {
  const MongoTestScreen({super.key});

  @override
  State<MongoTestScreen> createState() => _MongoTestScreenState();
}

class _MongoTestScreenState extends State<MongoTestScreen> {
  String _status = 'Chưa test';
  bool _isLoading = false;
  bool _isConnected = false;
  String _errorDetails = '';
  int _productCount = 0;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Đang kiểm tra kết nối...';
      _errorDetails = '';
    });

    try {
      final mongoService = getIt<MongoService>();

      // Test 1: Kết nối
      setState(() {
        _status = 'Đang kết nối MongoDB...';
      });

      await mongoService.connect();

      // Test 2: Kiểm tra trạng thái
      final isConnected = mongoService.isConnected;
      setState(() {
        _isConnected = isConnected;
        if (isConnected) {
          _status = '✅ Đã kết nối thành công!';
        } else {
          _status = '❌ Kết nối thất bại';
          _errorDetails = 'Không thể xác định trạng thái kết nối';
        }
      });

      // Test 3: Health check
      if (isConnected) {
        setState(() {
          _status = 'Đang kiểm tra health...';
        });

        final healthCheck = await mongoService.healthCheck();
        if (healthCheck) {
          setState(() {
            _status = '✅ Kết nối và health check: OK';
          });

          // Test 4: Thử lấy sản phẩm
          setState(() {
            _status = 'Đang test query...';
          });

          final products = await mongoService.getProducts(limit: 5);
          setState(() {
            _productCount = products.length;
            _status = '✅ Tất cả test đều thành công!';
            _status += '\n📦 Tìm thấy $_productCount sản phẩm';
          });
        } else {
          setState(() {
            _status = '⚠️ Đã kết nối nhưng health check thất bại';
            _errorDetails = 'Có thể database chưa có collection "products"';
          });
        }
      }
    } catch (e, stackTrace) {
      setState(() {
        _isConnected = false;
        _status = '❌ Lỗi kết nối MongoDB';
        _errorDetails = 'Chi tiết lỗi:\n$e\n\nStack trace:\n$stackTrace';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test MongoDB Connection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _testConnection,
            tooltip: 'Thử lại',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _isConnected ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _isConnected ? Icons.check_circle : Icons.error_outline,
                      size: 64,
                      color: _isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _isConnected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Error Details
            if (_errorDetails.isNotEmpty) ...[
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Chi tiết lỗi',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorDetails,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Product Count
            if (_productCount > 0) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2, color: Colors.blue),
                      const SizedBox(width: 12),
                      Text(
                        'Số sản phẩm trong database: $_productCount',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Troubleshooting Guide
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Hướng dẫn khắc phục',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTroubleshootingItem(
                      context,
                      '1. Kiểm tra Connection String',
                      'Đảm bảo connection string đúng format:\n'
                          'mongodb+srv://username:password@cluster.mongodb.net/database?options',
                    ),
                    const SizedBox(height: 12),
                    _buildTroubleshootingItem(
                      context,
                      '2. Whitelist IP trong MongoDB Atlas',
                      'Vào MongoDB Atlas → Network Access → Add IP Address\n'
                          'Chọn "Allow Access from Anywhere" (0.0.0.0/0)',
                    ),
                    const SizedBox(height: 12),
                    _buildTroubleshootingItem(
                      context,
                      '3. Kiểm tra Username/Password',
                      'Vào MongoDB Atlas → Database Access\n'
                          'Đảm bảo username và password đúng',
                    ),
                    const SizedBox(height: 12),
                    _buildTroubleshootingItem(
                      context,
                      '4. Kiểm tra Database User Permissions',
                      'Đảm bảo user có quyền đọc/ghi database',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Test Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testConnection,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại kết nối'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingItem(
    BuildContext context,
    String title,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(description, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
