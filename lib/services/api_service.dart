import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api_config.dart';
import '../navigation/app_navigator.dart';
import 'session_storage.dart';

/// Static HTTP helper for API calls with Firebase authentication
class ApiService {
  static bool _handlingAuthExpiry = false;

  static Future<void> _handleUnauthorized() async {
    if (_handlingAuthExpiry) return;
    _handlingAuthExpiry = true;
    try {
      await FirebaseAuth.instance.signOut();
      await SessionStorage.clear();
      AppNavigator.pushNamedAndRemoveUntil('/login');
    } finally {
      _handlingAuthExpiry = false;
    }
  }

  static void _checkStatus(int statusCode, String path, String body) {
    if (statusCode == 401) {
      _handleUnauthorized();
      throw ApiAuthException('Session expired. Please sign in again.');
    }
    if (statusCode < 200 || statusCode >= 300) {
      String message = body;
      String? code;
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          message = (decoded['error'] ?? decoded['message'] ?? body).toString();
          code = decoded['code']?.toString();
        }
      } catch (_) {
        if (body.trimLeft().startsWith('<')) {
          message =
              'Backend route not found or Space is serving HTML. Check deployment and API base URL.';
        }
      }
      throw ApiException(message, statusCode: statusCode, code: code);
    }
  }

  static Future<String?> _token() async {
    return FirebaseAuth.instance.currentUser?.getIdToken();
  }

  /// Sends a GET request with Bearer token
  static Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path')
        .replace(queryParameters: queryParams);

    try {
      final idToken = await _token();
      if (idToken == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      _checkStatus(response.statusCode, 'GET $path', response.body);
      return {};
    } catch (e) {
      if (e is ApiAuthException) rethrow;
      debugPrint('ApiService: GET EXCEPTION for $uri: $e');
      rethrow;
    }
  }

  /// Sends a POST request with Bearer token
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    try {
      final idToken = await _token();
      if (idToken == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      _checkStatus(response.statusCode, 'POST $path', response.body);
      return {};
    } catch (e) {
      if (e is ApiAuthException) rethrow;
      debugPrint('ApiService: POST EXCEPTION for $url: $e');
      rethrow;
    }
  }

  /// Sends a PATCH request with Bearer token
  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final idToken = await _token();
      if (idToken == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}$path');
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      _checkStatus(response.statusCode, 'PATCH $path', response.body);
      return {};
    } catch (e) {
      if (e is ApiAuthException) rethrow;
      debugPrint('ApiService PATCH EXCEPTION: $e');
      rethrow;
    }
  }
}

class ApiAuthException implements Exception {
  ApiAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiException implements Exception {
  ApiException(this.message, {required this.statusCode, this.code});
  final String message;
  final int statusCode;
  final String? code;

  @override
  String toString() => code == null ? message : '$message ($code)';
}
