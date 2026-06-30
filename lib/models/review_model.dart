/// Model ulasan / review produk
class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final int rating;
  final String? comment;
  final String? createdAt;
  final Map<String, dynamic>? user;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.user,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] ?? '',
      productId: map['product_id'] ?? '',
      userId: map['user_id'] ?? '',
      rating: map['rating'] ?? 0,
      comment: map['comment'],
      createdAt: map['created_at'],
      user: map['users'],
    );
  }

  String get userName => user?['full_name'] ?? user?['name'] ?? 'Anonim';
}
