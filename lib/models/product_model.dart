import 'category_model.dart';

/// Model data produk dari API
class ProductModel {
  final String id;
  final String name;
  final String slug;
  final String description;
  final double price;
  final int stock;
  final String? categoryId;
  final String? imageUrl;
  final bool isActive;
  final String? createdAt;
  final CategoryModel? category;
  final double? averageRating;
  final int? reviewCount;

  ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    required this.stock,
    this.categoryId,
    this.imageUrl,
    this.isActive = true,
    this.createdAt,
    this.category,
    this.averageRating,
    this.reviewCount,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      slug: map['slug'] ?? '',
      description: map['description'] ?? '',
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      stock: int.tryParse(map['stock']?.toString() ?? '0') ?? 0,
      categoryId: map['category_id'],
      imageUrl: map['image_url'],
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at'],
      category: map['categories'] != null && map['categories'] is Map<String, dynamic>
          ? CategoryModel.fromMap(map['categories'])
          : null,
      averageRating: map['average_rating'] != null
          ? double.tryParse(map['average_rating'].toString())
          : null,
      reviewCount: map['review_count'] != null 
          ? int.tryParse(map['review_count'].toString()) 
          : null,
    );
  }
}