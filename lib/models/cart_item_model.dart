/// Model item keranjang belanja
/// API response: { id, cart_id, product_id, quantity, created_at, products: {id, name, price, image_url, ...} }
class CartItemModel {
  final String id;
  final String productId;
  final String cartId;
  int quantity;
  final double price;
  final Map<String, dynamic>? product;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.cartId,
    required this.quantity,
    required this.price,
    this.product,
  });

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    // Price bisa dari product.price, products.price, atau price langsung
    final prod = (map['product'] ?? map['products']) as Map<String, dynamic>?;
    final rawPrice = prod?['price'] ?? map['price'] ?? 0;
    return CartItemModel(
      id: map['id'] ?? '',
      productId: map['product_id'] ?? prod?['id'] ?? '',
      cartId: map['cart_id'] ?? '',
      quantity: int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      price: double.tryParse(rawPrice.toString()) ?? 0.0,
      product: prod,
    );
  }

  /// Nama produk
  String get productName => product?['name'] ?? 'Produk';

  /// URL gambar produk
  String? get productImage => product?['image_url'];

  /// Subtotal (harga × qty)
  double get subtotal => price * quantity;
}
