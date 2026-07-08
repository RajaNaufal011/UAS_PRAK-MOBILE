import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../cart/cart_page.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

/// Halaman Detail Produk — Soal 2
class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ApiService _api = ApiService();
  ProductModel? _product;
  bool _isLoading = true;
  bool _isAddingToCart = false;
  int _qty = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await _api.get(ApiConstants.productDetail(widget.productId));
      final data = res['data'] as Map<String, dynamic>?;
      if (data != null) {
        setState(() => _product = ProductModel.fromMap(data));
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _isLoading = false);
  }

  Future<void> _addToCart() async {
    if (_product == null) return;
    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu'),
            backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isAddingToCart = true);
    final success = await context.read<CartProvider>().addToCart(_product!.id, _qty);
    if (!mounted) return;
    setState(() => _isAddingToCart = false);

    if (success) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              const Text('Berhasil ditambahkan ke keranjang!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Lanjut Belanja')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CartPage()));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        foregroundColor: Colors.white),
                    child: const Text('Lihat Keranjang')),
                ),
              ]),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan: ${context.read<CartProvider>().errorMessage ?? ""}'),
            backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Produk')),
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Gagal memuat produk', style: TextStyle(color: Colors.grey)),
            TextButton(onPressed: _loadProduct, child: const Text('Coba lagi')),
          ],
        )),
      );
    }

    final p = _product!;
    final stock = p.stock;
    final inStock = stock > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // Hero image AppBar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            actions: [
              Consumer<WishlistProvider>(
                builder: (context, wishlist, child) {
                  final isWishlisted = wishlist.isWishlisted(p.id);
                  return IconButton(
                    icon: Icon(
                      isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: isWishlisted ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => wishlist.toggleWishlist(p),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: p.imageUrl != null && p.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: p.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (_, __, ___) => Container(
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.image_not_supported,
                              size: 80, color: Colors.grey)),
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.shopping_bag,
                          size: 80, color: Colors.grey)),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori
                  if (p.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A73E8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(p.category!.name,
                          style: const TextStyle(
                              color: Color(0xFF1A73E8), fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 12),

                  // Nama produk
                  Text(p.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3)),
                  const SizedBox(height: 12),

                  // Harga
                  Text(CurrencyFormatter.format(p.price),
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8))),

                  const SizedBox(height: 12),

                  // Rating dan stok
                  Row(children: [
                    if ((p.averageRating ?? 0) > 0) ...[
                      RatingBarIndicator(
                        rating: p.averageRating ?? 0,
                        itemBuilder: (_, __) =>
                            const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 18,
                      ),
                      const SizedBox(width: 6),
                      Text((p.averageRating ?? 0).toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Text('(${p.reviewCount ?? 0} ulasan)',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const Spacer(),
                    ] else ...[
                      const Spacer(),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: inStock ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: inStock ? Colors.green : Colors.red),
                      ),
                      child: Row(children: [
                        Icon(inStock ? Icons.check_circle : Icons.cancel,
                            size: 14, color: inStock ? Colors.green : Colors.red),
                        const SizedBox(width: 4),
                        Text(inStock ? 'Stok: $stock' : 'Habis',
                            style: TextStyle(
                                color: inStock ? Colors.green : Colors.red,
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ]),

                  const Divider(height: 28),

                  // Deskripsi
                  const Text('Deskripsi Produk',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(p.description,
                      style: const TextStyle(color: Colors.black87, height: 1.6, fontSize: 14)),

                  const SizedBox(height: 20),

                  // Qty selector
                  if (inStock) ...[
                    const Text('Jumlah:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(children: [
                      IconButton(
                        onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFF1A73E8),
                      ),
                      Container(
                        width: 48, alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('$_qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      IconButton(
                        onPressed: _qty < stock
                            ? () => setState(() => _qty++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF1A73E8),
                      ),
                      const Spacer(),
                      Text('Subtotal: ${CurrencyFormatter.format(p.price * _qty)}',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A73E8))),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: ElevatedButton.icon(
          onPressed: inStock && !_isAddingToCart ? _addToCart : null,
          icon: _isAddingToCart
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.shopping_cart),
          label: Text(inStock ? 'Tambahkan ke Keranjang' : 'Stok Habis'),
          style: ElevatedButton.styleFrom(
            backgroundColor: inStock ? const Color(0xFF1A73E8) : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
