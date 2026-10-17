import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'api_exceptions.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  final Duration timeout;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  /// Executes a GET request and returns decoded dynamic JSON.
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              ...?headers,
            },
          )
          .timeout(timeout);

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const TimeoutApiException();
    } on http.ClientException catch (e) {
      throw NetworkException('Error de conexión con el servicio: ${e.message}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado de comunicación: $e');
    }
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final fullUrl = '$base$cleanEndpoint';

    final uri = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringParams = queryParameters.map((k, v) => MapEntry(k, v.toString()));
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...stringParams,
      });
    }
    return uri;
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw ApiException('Formato de respuesta JSON inválido: $e', statusCode);
      }
    }

    dynamic errorBody;
    try {
      errorBody = jsonDecode(response.body);
    } catch (_) {
      errorBody = null;
    }

    final message = (errorBody is Map && errorBody['message'] != null)
        ? errorBody['message'].toString()
        : 'Error HTTP $statusCode: ${response.reasonPhrase ?? ''}';

    if (statusCode == 401) {
      throw UnauthorizedException(message);
    } else if (statusCode == 404) {
      throw NotFoundException(message);
    } else if (statusCode == 422) {
      Map<String, List<String>> validationErrors = {};
      if (errorBody is Map && errorBody['errors'] is Map) {
        (errorBody['errors'] as Map).forEach((key, val) {
          if (val is List) {
            validationErrors[key.toString()] = val.map((e) => e.toString()).toList();
          }
        });
      }
      throw ValidationException(message, validationErrors);
    } else if (statusCode == 429) {
      throw RateLimitException(message);
    } else if (statusCode >= 500) {
      throw ServerException(message);
    } else {
      throw ApiException(message, statusCode);
    }
  }

  void close() {
    _client.close();
  }
}
