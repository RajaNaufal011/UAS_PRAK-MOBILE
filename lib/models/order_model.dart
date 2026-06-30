/// Model pesanan / order
/// API response: { id, user_id, status, total_amount, shipping_address, notes, created_at, order_items: [...] }
class OrderModel {
  final String id;
  final String userId;
  final String status;
  final double totalAmount;
  final String shippingAddress;
  final String? notes;
  final String? createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.totalAmount,
    required this.shippingAddress,
    this.notes,
    this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    // items bisa dari 'order_items' atau 'items'
    final rawItems = (map['order_items'] as List<dynamic>?) ??
        (map['items'] as List<dynamic>?) ?? [];
    return OrderModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      status: map['status'] ?? 'pending',
      totalAmount: double.tryParse(map['total_amount']?.toString() ?? '0') ?? 0.0,
      shippingAddress: map['shipping_address'] ?? '',
      notes: map['notes'],
      createdAt: map['created_at'],
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map((e) => OrderItemModel.fromMap(e))
          .toList(),
    );
  }

  /// 8 karakter pertama UUID sebagai nomor pesanan
  String get orderNumber =>
      id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
}

/// Model item dalam pesanan
class OrderItemModel {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    // product_name bisa ada langsung atau dari nested products
    final name = map['product_name']?.toString() ??
        (map['products'] as Map<String, dynamic>?)?['name']?.toString() ??
        'Produk';
    return OrderItemModel(
      id: map['id'] ?? '',
      productId: map['product_id'] ?? '',
      productName: name,
      quantity: int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
    );
  }

  double get subtotal => price * quantity;
}
