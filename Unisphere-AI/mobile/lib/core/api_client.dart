import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'app_config.dart';

class ApiClient {
  ApiClient({http.Client? client, FirebaseAuth? auth})
    : client = client ?? http.Client(),
      auth = auth ?? FirebaseAuth.instance;
  final http.Client client;
  final FirebaseAuth auth;

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final response = await client
        .post(
          Uri.parse('${AppConfig.backendUrl}$path'),
          headers: await headers(),
          body: jsonEncode(body ?? {}),
        )
        .timeout(const Duration(seconds: 15));
    return decode(response);
  }

  Future<void> delete(String path) async {
    final response = await client
        .delete(
          Uri.parse('${AppConfig.backendUrl}$path'),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 15));
    decode(response);
  }

  Future<Map<String, String>> headers() async {
    final token = await auth.currentUser?.getIdToken();
    if (token == null) throw StateError('Sign in required');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Request failed (${response.statusCode})';
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        message = data['error'] as String? ?? message;
      } catch (_) {
        /* Keep status message for non-JSON errors. */
      }
      throw StateError(message);
    }
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
