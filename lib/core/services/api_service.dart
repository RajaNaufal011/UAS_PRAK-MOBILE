import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'storage_service.dart';

/// HTTP client wrapper untuk memanggil REST API
/// Otomatis menyertakan Bearer token jika tersedia
class ApiService {
  final StorageService _storage = StorageService();

  /// Membuat headers dengan atau tanpa token
  Future<Map<String, String>> _getHeaders({bool withAuth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth) {
      final token = await _storage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// HTTP GET tanpa/dengan auth
  Future<Map<String, dynamic>> get(String endpoint,
      {bool withAuth = false, Map<String, String>? queryParams}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint')
        .replace(queryParameters: queryParams);
    final headers = await _getHeaders(withAuth: withAuth);

    final response = await http.get(uri, headers: headers);
    return _handleResponse(response);
  }

  /// HTTP POST
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body,
      {bool withAuth = false}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(withAuth: withAuth);

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  /// HTTP PUT
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body,
      {bool withAuth = false}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(withAuth: withAuth);

    final response = await http.put(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  /// HTTP DELETE
  Future<Map<String, dynamic>> delete(String endpoint,
      {bool withAuth = false}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(withAuth: withAuth);

    final response = await http.delete(uri, headers: headers);
    return _handleResponse(response);
  }

  /// Parse response dan handle error
  Map<String, dynamic> _handleResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    } else {
      final message =
          decoded['message'] ?? decoded['error'] ?? 'Terjadi kesalahan';
      throw ApiException(message, response.statusCode);
    }
  }
}

/// Custom exception untuk error dari API
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
