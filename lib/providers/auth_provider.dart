import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

/// Provider untuk state autentikasi user
class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  UserModel? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _user?.isAdmin ?? false;

  /// Cek status login saat app pertama dibuka (auto-login)
  Future<void> checkLoginStatus() async {
    _isLoggedIn = await _storage.isLoggedIn();
    if (_isLoggedIn) {
      await getProfile();
    }
    notifyListeners();
  }

  /// Register user baru
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _api.post(ApiConstants.register, {
        'full_name': fullName,
        'email': email,
        'password': password,
      });
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Login dan simpan token
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final res = await _api.post(ApiConstants.login, {
        'email': email,
        'password': password,
      });

      // Ambil token dari response
      final token = res['data']?['access_token'] ??
          res['access_token'] ??
          res['token'];

      if (token == null) throw Exception('Token tidak ditemukan');

      await _storage.saveToken(token);
      _isLoggedIn = true;

      // Simpan data user jika tersedia di response login
      final userData = res['data']?['user'] ?? res['user'];
      if (userData != null) {
        _user = UserModel.fromMap(userData);
        await _storage.saveIsAdmin(_user!.isAdmin);
      }

      await getProfile();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Ambil data profil user dari API
  Future<void> getProfile() async {
    try {
      final res = await _api.get(ApiConstants.profile, withAuth: true);
      final data = res['data'] ?? res;
      _user = UserModel.fromMap(data);
      await _storage.saveIsAdmin(_user!.isAdmin);
      notifyListeners();
    } catch (e) {
      // Jika 401 (token expired), logout otomatis
      if (e is ApiException && e.statusCode == 401) {
        await logout();
      }
    }
  }

  /// Update profil user (nama & nomor telepon)
  Future<bool> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final res = await _api.put(ApiConstants.profile, {
        'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      }, withAuth: true);

      final data = res['data'] ?? res;
      _user = UserModel.fromMap(data);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Logout — hapus token dan reset state
  Future<void> logout() async {
    await _storage.clearToken();
    _isLoggedIn = false;
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
