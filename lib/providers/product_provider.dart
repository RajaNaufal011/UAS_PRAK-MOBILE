import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

/// Provider untuk daftar produk, kategori, search, filter, sort
class ProductProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Filter state
  String _searchQuery = '';
  String? _selectedCategoryId;
  String _sortBy = 'newest';

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  static const int _limit = 10;

  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedCategoryId => _selectedCategoryId;
  String get sortBy => _sortBy;
  bool get hasMore => _currentPage < _totalPages;

  /// Muat produk dari awal (reset pagination)
  Future<void> loadProducts({bool reset = true}) async {
    if (reset) {
      _currentPage = 1;
      _products = [];
      _setLoading(true);
    } else {
      _isLoadingMore = true;
      notifyListeners();
    }

    try {
      final queryParams = <String, String>{
        'page': _currentPage.toString(),
        'limit': _limit.toString(),
      };
      if (_searchQuery.isNotEmpty) queryParams['search'] = _searchQuery;
      if (_selectedCategoryId != null) {
        queryParams['category_id'] = _selectedCategoryId!;
      }
      if (_sortBy.isNotEmpty) queryParams['sort'] = _sortBy;

      final res = await _api.get(ApiConstants.products, queryParams: queryParams);
      final data = res['data'] as List<dynamic>? ?? [];
      final pagination = res['pagination'] as Map<String, dynamic>? ?? {};
      _totalPages = pagination['totalPages'] ?? 1;

      final newProducts = data.map((e) => ProductModel.fromMap(e)).toList();
      if (reset) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoadingMore = false;
    _setLoading(false);
  }

  /// Muat lebih banyak produk (infinite scroll)
  Future<void> loadMore() async {
    if (!hasMore || _isLoadingMore) return;
    _currentPage++;
    await loadProducts(reset: false);
  }

  /// Muat semua kategori
  Future<void> loadCategories() async {
    try {
      final res = await _api.get(ApiConstants.categories);
      final data = res['data'] as List<dynamic>? ?? [];
      _categories = data.map((e) => CategoryModel.fromMap(e)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  /// Set search query dan reload produk
  void setSearch(String query) {
    _searchQuery = query;
    loadProducts();
  }

  /// Set filter kategori dan reload
  void setCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    loadProducts();
  }

  /// Set sorting dan reload
  void setSort(String sort) {
    _sortBy = sort;
    loadProducts();
  }

  /// Reset semua filter
  void resetFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _sortBy = 'newest';
    loadProducts();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
