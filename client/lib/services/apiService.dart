import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'debugLogger.dart';
import 'apiResponse.dart';
import 'apiException.dart';

class ApiService {
  static String? token = "";

  static Future<void> initToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? "";
  }

  static Future<void> clearToken() async {
    token = null;
  }

  /// POST with JSON body (create / update actions)
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$apiBase/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    logTo('post:$jsonEncode(body)');

    return _parseJsonResponse(res);
  }

  /// PUT with JSON body (update action)
  static Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$apiBase/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return _parseJsonResponse(res);
  }
  
  /// GET list of objects from endpoint
  static Future<List<dynamic>> getList(String endpoint) async {
    final res = await http.get(
      Uri.parse('$apiBase/$endpoint'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode==200) {
      final decoded = _tryDecode(res);

      if (decoded is List) {
        return decoded;
      }
      if (decoded is Map<String, dynamic> && decoded['data'] is List) {
        return decoded['data'];
      }

      return [];
    } else {
      throw apiException(res.body);
    }
  }

  /// GET paged response {data: [], count: N}
  static Future<Map<String, dynamic>> getPaged(String endpoint) async {
    final res = await http.get(
      Uri.parse('$apiBase/$endpoint'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final decoded = _tryDecode(res);
      if (decoded is Map<String, dynamic>) {
          return decoded;
      } else if (decoded is List) {
          // Fallback for non-paged endpoints transparency
          return {'data': decoded, 'count': decoded.length};
      }
      throw apiException('Invalid paged response format');
    } else {
      throw apiException(res.body);
    }
  }

  /// GET single object
  static Future<Map<String, dynamic>> getOne(String endpoint) async {
    final res = await http.get(
      Uri.parse('$apiBase/$endpoint'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return _parseJsonResponse(res);
  }

  /// DELETE
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final res = await http.delete(
      Uri.parse('$apiBase/$endpoint'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return _parseJsonResponse(res);
  }

  static dynamic _tryDecode(http.Response res) {
    try {
      return jsonDecode(res.body);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _parseJsonResponse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
       final body = _tryDecode(res);
       if (body is Map<String, dynamic>) return body;
       // Valid response but empty or not map?
       return {'success': true}; 
    }
    
    throw apiException(res.body);
  }

  /// Register a new user and return an ApiResponse
  static Future<ApiResponse> register({
    required String username,
    required String password,
    required String dob,
  }) async {
    final body = {
      'username': username,
      'password': password,
      'dob': dob,
    };

    try {
      final res = await post('register', body);

      // Create and return ApiResponse from backend response
      return ApiResponse.fromJson(res);
    } catch (e) {
      // Return a generic error response
      return ApiResponse(
        ok: false,
        message: 'Error: $e',
      );
    }
  }  
}
