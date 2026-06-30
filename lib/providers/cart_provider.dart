import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/cart_item_model.dart';

/// Provider untuk state keranjang belanja
class CartProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<CartItemModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CartItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Jumlah item di keranjang (badge counter)
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Grand total
  double get grandTotal =>
      _items.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Muat daftar keranjang dari API
  /// API GET /cart returns { data: { cart_id, items: [...], total_items, grand_total } }
  Future<void> loadCart() async {
    _setLoading(true);
    try {
      final res = await _api.get(ApiConstants.cart, withAuth: true);
      final data = res['data'];
      List<dynamic> items = [];
      if (data is Map) {
        items = (data['items'] as List<dynamic>?) ?? [];
      } else if (data is List) {
        items = data;
      }
      _items = items.map((e) => CartItemModel.fromMap(e)).toList();
    } catch (e) {
      _items = [];
    }
    _setLoading(false);
  }

  /// Tambah produk ke keranjang — POST /cart
  Future<bool> addToCart(String productId, int quantity) async {
    try {
      await _api.post(ApiConstants.cart, {
        'product_id': productId,
        'quantity': quantity,
      }, withAuth: true);
      await loadCart();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update jumlah item di keranjang — PUT /cart/:itemId
  Future<bool> updateItem(String cartItemId, int quantity) async {
    try {
      await _api.put(ApiConstants.cartItem(cartItemId), {
        'quantity': quantity,
      }, withAuth: true);
      await loadCart();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Hapus satu item dari keranjang — DELETE /cart/:itemId
  Future<bool> deleteItem(String cartItemId) async {
    try {
      await _api.delete(ApiConstants.cartItem(cartItemId), withAuth: true);
      await loadCart();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Kosongkan seluruh keranjang — DELETE /cart (hapus satu per satu)
  Future<bool> clearCart() async {
    try {
      for (final item in List.from(_items)) {
        await _api.delete(ApiConstants.cartItem(item.id), withAuth: true);
      }
      _items = [];
      notifyListeners();
      return true;
    } catch (e) {
      // Fallback: try DELETE /cart
      try {
        await _api.delete(ApiConstants.cart, withAuth: true);
        _items = [];
        notifyListeners();
        return true;
      } catch (_) {}
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Reset state keranjang (saat logout)
  void reset() {
    _items = [];
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
