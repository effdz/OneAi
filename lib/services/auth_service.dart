import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:oneai/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Untuk demo, kita gunakan URL dummy. Dalam aplikasi nyata, ganti dengan URL API Anda
  static const String _baseUrl = 'https://api.example.com/api';
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';

  // Mendapatkan token dari secure storage
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Menyimpan token ke secure storage
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Menyimpan user ke shared preferences
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Mendapatkan user dari shared preferences
  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  // Hapus token dan user (logout)
  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Cek apakah user sudah login
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Login
  static Future<UserModel> login(String email, String password) async {
    // Untuk demo, kita akan membuat user dummy
    // Dalam aplikasi nyata, ini akan memanggil API login

    try {
      // Simulasi delay jaringan
      await Future.delayed(const Duration(seconds: 1));

      // Validasi email dan password sederhana
      if (email.isEmpty || !email.contains('@')) {
        throw Exception('Email tidak valid');
      }

      if (password.isEmpty || password.length < 6) {
        throw Exception('Password harus minimal 6 karakter');
      }

      // Untuk demo, kita terima semua login dengan email dan password yang valid
      final user = UserModel(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        username: email.split('@')[0],
        email: email,
        lastLogin: DateTime.now(),
      );

      // Simpan token dummy
      await saveToken('dummy-token-${DateTime.now().millisecondsSinceEpoch}');
      await saveUser(user);

      return user;
    } catch (e) {
      throw Exception('Login gagal: $e');
    }
  }

  // Register
  static Future<UserModel> register(
      String username, String email, String password) async {
    // Untuk demo, kita akan membuat user dummy
    // Dalam aplikasi nyata, ini akan memanggil API register

    try {
      // Simulasi delay jaringan
      await Future.delayed(const Duration(seconds: 1));

      // Validasi input sederhana
      if (username.isEmpty || username.length < 3) {
        throw Exception('Username harus minimal 3 karakter');
      }

      if (email.isEmpty || !email.contains('@')) {
        throw Exception('Email tidak valid');
      }

      if (password.isEmpty || password.length < 6) {
        throw Exception('Password harus minimal 6 karakter');
      }

      // Untuk demo, kita terima semua registrasi dengan input yang valid
      final user = UserModel(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        email: email,
        lastLogin: DateTime.now(),
      );

      // Simpan token dummy
      await saveToken('dummy-token-${DateTime.now().millisecondsSinceEpoch}');
      await saveUser(user);

      return user;
    } catch (e) {
      throw Exception('Registrasi gagal: $e');
    }
  }

  // Get authenticated headers
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get user profile
  static Future<UserModel> getUserProfile() async {
    // Untuk demo, kita akan mengambil user dari shared preferences
    // Dalam aplikasi nyata, ini akan memanggil API untuk mendapatkan profil user

    try {
      final user = await getUser();
      if (user == null) {
        throw Exception('User tidak ditemukan');
      }
      return user;
    } catch (e) {
      throw Exception('Gagal mendapatkan profil user: $e');
    }
  }
}
