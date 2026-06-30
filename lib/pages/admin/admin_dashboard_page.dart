import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';

/// Halaman Admin Dashboard — Soal 5
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  // Stats
  Map<String, dynamic>? _stats;
  // Products
  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  // Orders
  List<dynamic> _orders = [];
  String _orderStatusFilter = 'all';

  bool _isLoadingStats = true;
  bool _isLoadingProducts = true;
  bool _isLoadingOrders = true;

  final List<String> _statusOptions = [
    'all', 'pending', 'processing', 'shipped', 'delivered', 'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
    _loadProducts();
    _loadOrders();
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final res = await _api.get(ApiConstants.dashboardStats, withAuth: true);
      setState(() => _stats = res['data'] as Map<String, dynamic>?);
    } catch (e) {
      debugPrint('Stats error: $e');
    }
    setState(() => _isLoadingStats = false);
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final res = await _api.get(ApiConstants.products,
          withAuth: true, queryParams: {'limit': '100'});
      final list = res['data'] as List<dynamic>? ?? [];
      setState(() => _products = list.map((e) => ProductModel.fromMap(e)).toList());
    } catch (e) {
      debugPrint('Products error: $e');
    }
    setState(() => _isLoadingProducts = false);
  }

  Future<void> _loadCategories() async {
    try {
      final res = await _api.get(ApiConstants.categories);
      final list = res['data'] as List<dynamic>? ?? [];
      setState(() => _categories = list.map((e) => CategoryModel.fromMap(e)).toList());
    } catch (e) {
      debugPrint('Categories error: $e');
    }
  }

  String? _ordersError;

  Future<void> _loadOrders() async {
    setState(() {
      _isLoadingOrders = true;
      _ordersError = null;
    });
    try {
      final params = <String, String>{'limit': '100'};
      if (_orderStatusFilter != 'all') params['status'] = _orderStatusFilter;
      final res = await _api.get(ApiConstants.allOrders, withAuth: true, queryParams: params);
      setState(() => _orders = res['data'] as List<dynamic>? ?? []);
    } catch (e) {
      debugPrint('Orders error: $e');
      setState(() => _ordersError = e.toString());
    }
    setState(() => _isLoadingOrders = false);
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _api.put(ApiConstants.orderStatus(orderId), {'status': newStatus}, withAuth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status berhasil diperbarui'), backgroundColor: Colors.green));
      await _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteProduct(ProductModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menonaktifkan "${p.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _api.delete(ApiConstants.productDetail(p.id), withAuth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk dinonaktifkan'), backgroundColor: Colors.green));
      await _loadProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red));
    }
  }

  void _showProductForm({ProductModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final priceCtrl = TextEditingController(text: existing != null ? existing.price.toInt().toString() : '');
    final stockCtrl = TextEditingController(text: existing?.stock.toString() ?? '');
    final imageCtrl = TextEditingController(text: existing?.imageUrl ?? '');
    String? selectedCategoryId = existing?.categoryId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing == null ? 'Tambah Produk' : 'Edit Produk',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildFormField('Nama Produk', nameCtrl),
                const SizedBox(height: 12),
                _buildFormField('Deskripsi', descCtrl, maxLines: 3),
                const SizedBox(height: 12),
                _buildFormField('Harga (Rp)', priceCtrl, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _buildFormField('Stok', stockCtrl, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _buildFormField('URL Gambar (opsional)', imageCtrl),
                const SizedBox(height: 12),
                // Kategori dropdown
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: _categories.map((c) =>
                    DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => setModalState(() => selectedCategoryId = v),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty || stockCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nama, harga, dan stok wajib diisi')));
                        return;
                      }
                      Navigator.pop(ctx);
                      final body = {
                        'name': nameCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'price': int.tryParse(priceCtrl.text) ?? 0,
                        'stock': int.tryParse(stockCtrl.text) ?? 0,
                        if (imageCtrl.text.isNotEmpty) 'image_url': imageCtrl.text.trim(),
                        if (selectedCategoryId != null) 'category_id': selectedCategoryId,
                      };
                      try {
                        if (existing == null) {
                          await _api.post(ApiConstants.products, body, withAuth: true);
                        } else {
                          await _api.put(ApiConstants.productDetail(existing.id), body, withAuth: true);
                        }
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(existing == null ? 'Produk berhasil ditambahkan!' : 'Produk berhasil diperbarui!'),
                            backgroundColor: Colors.green,
                          ));
                        await _loadProducts();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(existing == null ? 'Tambah Produk' : 'Simpan Perubahan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController ctrl,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'processing': return Colors.blue;
      case 'shipped': return Colors.indigo;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  List<String> _getNextStatuses(String current) {
    switch (current.toLowerCase()) {
      case 'pending': return ['processing', 'cancelled'];
      case 'processing': return ['shipped', 'cancelled'];
      case 'shipped': return ['delivered'];
      default: return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Dashboard Admin', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Statistik'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Produk'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Pesanan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildProductsTab(),
          _buildOrdersTab(),
        ],
      ),
    );
  }

  // ==================== TAB 1: STATISTIK ====================
  Widget _buildStatsTab() {
    if (_isLoadingStats) return const Center(child: CircularProgressIndicator());
    final stats = _stats ?? {};

    final ordersByStatus = stats['orders_by_status'] as Map<String, dynamic>? ?? {};
    final totalProd = stats['total_products'] ?? 0;
    final totalOrders = stats['total_orders'] ?? 0;
    final totalUsers = stats['total_users'] ?? 0;
    final totalRevenue = stats['total_revenue'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stat cards grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _statCard('Total Produk', '$totalProd', Icons.inventory_2, const Color(0xFF1A73E8)),
              _statCard('Total Pesanan', '$totalOrders', Icons.receipt_long, Colors.purple),
              _statCard('Pendapatan', CurrencyFormatter.format(totalRevenue), Icons.attach_money, Colors.green),
              _statCard('Total User', '$totalUsers', Icons.people, Colors.orange),
            ],
          ),
          const SizedBox(height: 20),
          // Status bar chart
          if (ordersByStatus.isNotEmpty) ...[
            const Text('Status Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: ([...ordersByStatus.values.map((v) => (v as num).toDouble()), 1]).reduce((a, b) => a > b ? a : b) * 1.3,
                barGroups: ordersByStatus.entries.toList().asMap().entries.map((e) {
                  final idx = e.key;
                  final entry = e.value;
                  return BarChartGroupData(x: idx, barRods: [
                    BarChartRodData(
                      toY: (entry.value as num).toDouble(),
                      color: _statusColor(entry.key),
                      width: 22,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ]);
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, _) {
                      final keys = ordersByStatus.keys.toList();
                      final idx = val.toInt();
                      if (idx >= keys.length) return const Text('');
                      final key = keys[idx];
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(key[0].toUpperCase() + key.substring(1, key.length > 4 ? 4 : key.length),
                            style: const TextStyle(fontSize: 9)),
                      );
                    },
                  )),
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (val, _) => Text('${val.toInt()}', style: const TextStyle(fontSize: 10)),
                  )),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              )),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== TAB 2: MANAJEMEN PRODUK ====================
  Widget _buildProductsTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingProducts
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProducts,
              child: _products.isEmpty
                  ? const Center(child: Text('Belum ada produk'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _products.length,
                      itemBuilder: (_, i) => _buildProductCard(_products[i]),
                    ),
            ),
    );
  }

  Widget _buildProductCard(ProductModel p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: p.imageUrl != null && p.imageUrl!.isNotEmpty
              ? Image.network(p.imageUrl!,
                  width: 56, height: 56, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      width: 56, height: 56, color: Colors.grey.shade100,
                      child: const Icon(Icons.image_not_supported, size: 24, color: Colors.grey)))
              : Container(width: 56, height: 56, color: Colors.grey.shade100,
                  child: const Icon(Icons.shopping_bag, size: 24, color: Colors.grey)),
        ),
        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(CurrencyFormatter.format(p.price),
                style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.w600)),
            Row(children: [
              Icon(Icons.inventory, size: 12, color: p.stock > 0 ? Colors.green : Colors.red),
              const SizedBox(width: 2),
              Text('Stok: ${p.stock}', style: TextStyle(fontSize: 11, color: p.stock > 0 ? Colors.green : Colors.red)),
            ]),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF1A73E8), size: 20),
              onPressed: () => _showProductForm(existing: p),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deleteProduct(p),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 3: MANAJEMEN PESANAN ====================
  Widget _buildOrdersTab() {
    return Column(
      children: [
        // Filter chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statusOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = _statusOptions[i];
                final isSelected = _orderStatusFilter == s;
                return GestureDetector(
                  onTap: () {
                    setState(() => _orderStatusFilter = s);
                    _loadOrders();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1A73E8) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(s == 'all' ? 'Semua' : s[0].toUpperCase() + s.substring(1),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12)),
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: _isLoadingOrders
              ? const Center(child: CircularProgressIndicator())
              : _ordersError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 60, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Gagal Memuat Pesanan',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text(_ordersError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 20),
                            const Text(
                              '⚠️ Ini adalah error dari backend API. Database Supabase tidak memiliki relasi Foreign Key antara tabel "orders" dan "profiles". Server API crash (500) saat mencoba melakukan Join.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: _orders.isEmpty
                          ? const Center(child: Text('Tidak ada pesanan'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _orders.length,
                              itemBuilder: (_, i) => _buildAdminOrderCard(_orders[i]),
                            ),
                    ),
        ),
      ],
    );
  }

  Widget _buildAdminOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final orderId = order['id']?.toString() ?? '';
    final shortId = orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();
    final nextStatuses = _getNextStatuses(status);
    final isTerminal = status == 'delivered' || status == 'cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('#$shortId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _statusColor(status)),
              ),
              child: Text(status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(CurrencyFormatter.format(order['total_amount'] ?? 0),
              style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.bold, fontSize: 15)),
          if (order['shipping_address'] != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on, size: 13, color: Colors.grey),
              const SizedBox(width: 3),
              Expanded(child: Text('${order['shipping_address']}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ],
          if (!isTerminal && nextStatuses.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Update Status:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: nextStatuses.map((s) => GestureDetector(
              onTap: () => _updateOrderStatus(orderId, s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(s),
                  borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.arrow_forward, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(s[0].toUpperCase() + s.substring(1),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              ),
            )).toList()),
          ] else if (isTerminal)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                status == 'delivered' ? '✓ Pesanan selesai' : '✗ Pesanan dibatalkan',
                style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}
