import 'package:flutter/material.dart';
import '../models/product_model.dart';

class WishlistProvider extends ChangeNotifier {
  final List<ProductModel> _items = [];

  List<ProductModel> get items => _items;

  bool isWishlisted(String productId) {
    return _items.any((item) => item.id == productId);
  }

  void toggleWishlist(ProductModel product) {
    final isExist = isWishlisted(product.id);
    if (isExist) {
      _items.removeWhere((item) => item.id == product.id);
    } else {
      _items.add(product);
    }
    notifyListeners();
  }
}
