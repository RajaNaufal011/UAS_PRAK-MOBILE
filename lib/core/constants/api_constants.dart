/// Konstanta URL dan endpoint untuk API E-Commerce
class ApiConstants {
  static const String baseUrl = 'https://api-tb-f2wk.onrender.com/api';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String profile = '/auth/profile';

  // Products
  static const String products = '/products';
  static String productDetail(String id) => '/products/$id';

  // Categories
  static const String categories = '/categories';

  // Cart — POST /cart untuk add, PUT /cart/:id untuk update, DELETE /cart/:id untuk hapus
  static const String cart = '/cart';
  static String cartItem(String id) => '/cart/$id';

  // Orders
  static const String orders = '/orders';
  static const String allOrders = '/orders/admin/all';
  static String orderDetail(String id) => '/orders/$id';
  static String orderStatus(String id) => '/orders/$id/status';

  // Dashboard (Admin)
  static const String dashboardStats = '/dashboard/stats';
}
