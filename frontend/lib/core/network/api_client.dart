import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiClient {
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    // Handle Android Emulator localhost routing vs regular iOS/Desktop
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {}
    return 'http://localhost:8000';
  }

  final http.Client _httpClient;
  String _baseUrl;

  ApiClient({String? baseUrl, http.Client? httpClient})
      : _baseUrl = baseUrl ?? defaultBaseUrl,
        _httpClient = httpClient ?? http.Client();

  String get baseUrl => _baseUrl;

  set baseUrl(String url) {
    if (url.isNotEmpty) {
      _baseUrl = url;
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    developer.log('GET Request: $uri', name: 'ApiClient');

    try {
      final response = await _httpClient.get(uri, headers: _headers);
      return _processResponse(response);
    } catch (e) {
      developer.log('GET Error: $e', name: 'ApiClient', error: e);
      throw ApiException('Falha na comunicação com o servidor: $e');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    developer.log('POST Request: $uri | Body: $body', name: 'ApiClient');

    try {
      final response = await _httpClient.post(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      developer.log('POST Error: $e', name: 'ApiClient', error: e);
      throw ApiException('Falha na comunicação com o servidor: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    final int statusCode = response.statusCode;
    developer.log('Response Status: $statusCode', name: 'ApiClient');

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      String errorMessage = 'Ocorreu um erro inesperado';
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded.containsKey('detail')) {
          errorMessage = decoded['detail'];
        }
      } catch (_) {}
      
      developer.log(
        'API Error Status: $statusCode | Msg: $errorMessage', 
        name: 'ApiClient'
      );
      throw ApiException(errorMessage, statusCode);
    }
  }

  void close() {
    _httpClient.close();
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}
