import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order_model.dart';
import 'order_detail_page.dart';

/// Halaman Riwayat Pesanan — Soal 4B
class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<OrderModel> _orders = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _page < _totalPages) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _page = 1;
        _orders = [];
      });
    }
    try {
      final res = await _api.get(ApiConstants.orders,
          withAuth: true,
          queryParams: {'page': _page.toString(), 'limit': '10'});
      final data = res['data'] as List<dynamic>? ?? [];
      final pagination =
          res['pagination'] as Map<String, dynamic>? ?? {};
      _totalPages = pagination['totalPages'] ?? 1;
      setState(() {
        if (reset) {
          _orders = data.map((e) => OrderModel.fromMap(e)).toList();
        } else {
          _orders
              .addAll(data.map((e) => OrderModel.fromMap(e)).toList());
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat pesanan: $e')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoadingMore = true;
      _page++;
    });
    await _loadOrders(reset: false);
    if (mounted) setState(() => _isLoadingMore = false);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Pesanan Saya',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadOrders(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      _orders.length + (_isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    if (i == _orders.length) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    return _buildOrderCard(_orders[i]);
                  },
                ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final statusColor = _statusColor(order.status);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => OrderDetailPage(orderId: order.id)),
      ).then((_) => _loadOrders()),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order.orderNumber}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: 'monospace'),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        order.status[0].toUpperCase() +
                            order.status.substring(1),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (order.createdAt != null)
              Text(
                CurrencyFormatter.formatDate(order.createdAt!),
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.items.length} item',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13),
                ),
                Text(
                  CurrencyFormatter.format(order.totalAmount),
                  style: const TextStyle(
                    color: Color(0xFF1A73E8),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Belum Ada Pesanan',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Mulai berbelanja untuk melihat riwayat pesanan',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
