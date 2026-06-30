import 'package:intl/intl.dart';

/// Utility untuk format angka menjadi format Rupiah
class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format integer ke "Rp 8.500.000"
  static String format(num amount) {
    return _formatter.format(amount);
  }

  /// Format tanggal ke "28 Jun 2025"
  static String formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  /// Format tanggal + waktu
  static String formatDateTime(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (_) {
      return isoDate;
    }
  }
}
