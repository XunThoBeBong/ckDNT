import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/injection/service_locator.dart';
import '../../../core/services/mongo_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/product_model.dart';
import '../../config/themes/app_colors.dart';
import '../../widgets/product_card.dart';

/// SearchScreen - Màn hình tìm kiếm sản phẩm
///
/// Bao gồm:
/// - Search bar với debounce
/// - Auto-suggest (gợi ý từ khóa)
/// - Search history
/// - Kết quả tìm kiếm
class SearchScreen extends StatefulWidget {
  final String initialQuery;

  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounceTimer;
  List<ProductModel> _searchResults = [];
  List<String> _suggestions = [];
  List<String> _searchHistory = [];
  bool _isSearching = false;
  bool _showHistory = true;
  bool _showSuggestions = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchFocusNode.addListener(_onFocusChange);
    _searchController.addListener(_onSearchTextChanged);

    // Nếu có initialQuery, set vào controller và thực hiện search
    if (widget.initialQuery.isNotEmpty) {
      _searchController.text = widget.initialQuery;
      _hasText = true;
      // Delay một chút để đảm bảo UI đã render
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialQuery);
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_searchFocusNode.hasFocus) {
      setState(() {
        _showHistory = _searchController.text.isEmpty;
        _showSuggestions = _searchController.text.isNotEmpty;
      });
    }
  }

  void _onSearchTextChanged() {
    final query = _searchController.text.trim();

    setState(() {
      _hasText = _searchController.text.isNotEmpty;
      _showHistory = query.isEmpty;
      _showSuggestions = query.isNotEmpty;
    });

    // Debounce: Hủy timer cũ nếu có
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _suggestions = [];
      });
      return;
    }

    // Tạo timer mới (500ms)
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
      _loadSuggestions(query);
    });
  }

  /// Tải lịch sử tìm kiếm từ StorageService
  Future<void> _loadSearchHistory() async {
    final historyString = StorageService.getString('search_history');
    if (historyString != null && historyString.isNotEmpty) {
      try {
        // Lưu dưới dạng comma-separated: "keyword1,keyword2,keyword3"
        final history = historyString
            .split(',')
            .where((e) => e.trim().isNotEmpty)
            .map((e) => e.trim())
            .toList();
        setState(() {
          _searchHistory = history;
        });
      } catch (e) {
        // Nếu parse lỗi, bỏ qua
        print('Lỗi load search history: $e');
      }
    }
  }

  /// Lưu lịch sử tìm kiếm vào StorageService
  Future<void> _saveSearchHistory(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    // Xóa query cũ nếu có (để đưa lên đầu)
    _searchHistory.remove(trimmedQuery);
    // Thêm vào đầu danh sách
    _searchHistory.insert(0, trimmedQuery);

    // Giới hạn 15 từ khóa gần nhất
    if (_searchHistory.length > 15) {
      _searchHistory = _searchHistory.take(15).toList();
    }

    // Lưu vào StorageService (dạng comma-separated)
    await StorageService.setString('search_history', _searchHistory.join(','));

    setState(() {});
  }

  /// Tải gợi ý từ khóa (auto-suggest)
  Future<void> _loadSuggestions(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    try {
      final mongoService = getIt<MongoService>();
      // Lấy 5 sản phẩm đầu tiên để làm gợi ý
      final products = await mongoService.searchProducts(query, limit: 5);

      setState(() {
        _suggestions = products.map((p) => p.name).toList();
      });
    } catch (e) {
      // Lỗi thì bỏ qua, không hiển thị gợi ý
      setState(() {
        _suggestions = [];
      });
    }
  }

  /// Thực hiện tìm kiếm
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final mongoService = getIt<MongoService>();
      final results = await mongoService.searchProducts(query);

      // Lưu vào lịch sử
      await _saveSearchHistory(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _showHistory = false;
          _showSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tìm kiếm: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Xử lý khi user chọn từ lịch sử
  void _onHistoryItemTap(String query) {
    setState(() {
      _hasText = true;
    });
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    // Focus vào search bar để ẩn history
    _searchFocusNode.requestFocus();
    // Thực hiện search ngay (không cần debounce vì đã chọn từ history)
    _performSearch(query);
  }

  /// Xử lý khi user chọn gợi ý
  void _onSuggestionTap(String suggestion) {
    setState(() {
      _hasText = true;
    });
    _searchController.text = suggestion;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    // Focus vào search bar để ẩn suggestions
    _searchFocusNode.requestFocus();
    // Thực hiện search ngay (không cần debounce vì đã chọn từ suggestion)
    _performSearch(suggestion);
  }

  /// Xóa lịch sử tìm kiếm
  Future<void> _clearSearchHistory() async {
    await StorageService.remove('search_history');
    setState(() {
      _searchHistory = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildSearchBar(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
    );
  }

  /// Xây dựng search bar trong AppBar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.15), // Tăng độ mờ để text rõ hơn
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        autofocus: true,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500, // Tăng độ đậm để rõ hơn
        ),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm sản phẩm...',
          hintStyle: TextStyle(
            color: AppColors.white.withOpacity(0.8), // Tăng opacity để rõ hơn
            fontSize: 16,
          ),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.white),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_hasText)
                IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.white),
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.requestFocus();
                    setState(() {
                      _hasText = false;
                      _searchResults = [];
                      _suggestions = [];
                      _showHistory = true;
                      _showSuggestions = false;
                    });
                  },
                ),
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Xây dựng body của màn hình
  Widget _buildBody() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    // Hiển thị lịch sử tìm kiếm
    if (_showHistory && _searchHistory.isNotEmpty) {
      return _buildSearchHistory();
    }

    // Hiển thị gợi ý
    if (_showSuggestions && _suggestions.isNotEmpty) {
      return _buildSuggestions();
    }

    // Hiển thị kết quả tìm kiếm
    if (_searchResults.isNotEmpty) {
      return _buildSearchResults();
    }

    // Empty state
    return _buildEmptyState();
  }

  /// Xây dựng lịch sử tìm kiếm
  Widget _buildSearchHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lịch sử tìm kiếm',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _clearSearchHistory,
                child: const Text('Xóa tất cả'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () async {
                    setState(() {
                      _searchHistory.removeAt(index);
                    });
                    await StorageService.setString(
                      'search_history',
                      _searchHistory.isEmpty ? '' : _searchHistory.join(','),
                    );
                  },
                ),
                onTap: () => _onHistoryItemTap(query),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Xây dựng gợi ý từ khóa
  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Gợi ý',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              return ListTile(
                leading: const Icon(Icons.search),
                title: Text(suggestion),
                onTap: () => _onSuggestionTap(suggestion),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Xây dựng kết quả tìm kiếm
  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Kết quả tìm kiếm (${_searchResults.length})',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75, // Tăng từ 0.7 lên 0.75 để giảm chiều cao
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              return ProductCard(
                product: product,
                onTap: () {
                  context.push('/product-detail', extra: product);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Xây dựng empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'Nhập từ khóa để tìm kiếm'
                : 'Không tìm thấy kết quả',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
