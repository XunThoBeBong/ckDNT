import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/injection/service_locator.dart';
import '../../../../core/services/mongo_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../data/models/product_model.dart';
import '../../../config/themes/app_colors.dart';

/// SearchBarWidget - Widget thanh tìm kiếm với dropdown
///
/// Flow:
/// 1. Click vào search bar -> hiển thị dropdown với 5 từ khóa gần nhất
/// 2. User gõ -> hiển thị suggestions
/// 3. Click suggestion hoặc Enter -> gọi callback với kết quả search
class SearchBarWidget extends StatefulWidget {
  final Function(List<ProductModel>)? onSearchResults;

  const SearchBarWidget({super.key, this.onSearchResults});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  Timer? _debounceTimer;
  List<String> _searchHistory = [];
  List<String> _suggestions = [];
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _focusNode.addListener(_onFocusChange);
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showDropdownOverlay();
    } else {
      // Delay để cho phép click vào item trong dropdown
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _removeOverlay();
        }
      });
    }
  }

  void _onSearchTextChanged() {
    final query = _searchController.text.trim();

    // Debounce: Hủy timer cũ nếu có
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      _updateOverlay();
      return;
    }

    // Tạo timer mới (500ms)
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadSuggestions(query);
    });
  }

  /// Tải lịch sử tìm kiếm (5 từ khóa gần nhất)
  Future<void> _loadSearchHistory() async {
    final historyString = StorageService.getString('search_history');
    if (historyString != null && historyString.isNotEmpty) {
      try {
        final history = historyString
            .split(',')
            .where((e) => e.trim().isNotEmpty)
            .map((e) => e.trim())
            .take(5) // Chỉ lấy 5 từ khóa gần nhất
            .toList();
        setState(() {
          _searchHistory = history;
        });
      } catch (e) {
        print('Lỗi load search history: $e');
      }
    }
  }

  /// Tải gợi ý từ khóa
  Future<void> _loadSuggestions(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
      });
      _updateOverlay();
      return;
    }

    try {
      final mongoService = getIt<MongoService>();
      final products = await mongoService.searchProducts(query, limit: 5);

      if (mounted) {
        setState(() {
          _suggestions = products.map((p) => p.name).toList();
        });
        _updateOverlay();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
        });
        _updateOverlay();
      }
    }
  }

  /// Thực hiện tìm kiếm và gọi callback
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      // Nếu query rỗng, clear kết quả
      widget.onSearchResults?.call([]);
      return;
    }

    _focusNode.unfocus();
    _removeOverlay();

    try {
      final mongoService = getIt<MongoService>();
      final results = await mongoService.searchProducts(query);

      // Lưu vào lịch sử
      await _saveSearchHistory(query);

      if (mounted) {
        // Gọi callback để HomeScreen hiển thị kết quả
        widget.onSearchResults?.call(results);
      }
    } catch (e) {
      if (mounted) {
        widget.onSearchResults?.call([]);
      }
    }
  }

  /// Lưu lịch sử tìm kiếm
  Future<void> _saveSearchHistory(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    _searchHistory.remove(trimmedQuery);
    _searchHistory.insert(0, trimmedQuery);

    if (_searchHistory.length > 15) {
      _searchHistory = _searchHistory.take(15).toList();
    }

    await StorageService.setString('search_history', _searchHistory.join(','));
  }

  /// Hiển thị dropdown overlay
  void _showDropdownOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(builder: (context) => _buildDropdown());

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Cập nhật dropdown overlay
  void _updateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  /// Xóa dropdown overlay
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Xử lý khi user chọn từ lịch sử
  void _onHistoryItemTap(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  /// Xử lý khi user chọn gợi ý
  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion);
  }

  /// Xử lý khi user nhấn Enter
  void _handleSubmitted(String query) {
    _performSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: CompositedTransformTarget(
          link: _layerLink,
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onSubmitted: _handleSubmitted,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sản phẩm...',
              hintStyle: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: 20,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      color: AppColors.textSecondary,
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _suggestions = [];
                        });
                        _updateOverlay();
                        // Clear kết quả search
                        widget.onSearchResults?.call([]);
                      },
                    ),
                  Icon(Icons.mic, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 8),
                ],
              ),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Xây dựng dropdown overlay
  Widget _buildDropdown() {
    final query = _searchController.text.trim();
    final hasQuery = query.isNotEmpty;
    final hasHistory = _searchHistory.isNotEmpty && !hasQuery;
    final hasSuggestions = _suggestions.isNotEmpty && hasQuery;

    if (!hasHistory && !hasSuggestions) {
      return const SizedBox.shrink();
    }

    // Tính toán width của dropdown để căn đều với search bar
    final screenWidth = MediaQuery.of(context).size.width;
    final dropdownWidth = screenWidth > 600
        ? 600.0 // Trên màn hình lớn, dùng maxWidth 600 giống search bar
        : screenWidth - 32; // Trên mobile, dùng full width trừ padding

    // Tính toán offset để căn giữa trên màn hình lớn
    final horizontalOffset = screenWidth > 600
        ? (screenWidth - 600) / 2 -
              16 // Căn giữa với search bar
        : 0.0; // Trên mobile không cần offset

    return Positioned(
      left: horizontalOffset,
      width: dropdownWidth,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 56), // Offset từ search bar
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: AppColors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                // Hiển thị lịch sử tìm kiếm (5 từ khóa gần nhất)
                if (hasHistory) ...[
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Tìm kiếm gần đây',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ..._searchHistory.map(
                    (keyword) => _buildDropdownItem(
                      keyword,
                      Icons.history,
                      () => _onHistoryItemTap(keyword),
                    ),
                  ),
                ],

                // Hiển thị suggestions
                if (hasSuggestions) ...[
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Gợi ý',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ..._suggestions.map(
                    (suggestion) => _buildDropdownItem(
                      suggestion,
                      Icons.search,
                      () => _onSuggestionTap(suggestion),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Xây dựng item trong dropdown
  Widget _buildDropdownItem(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
