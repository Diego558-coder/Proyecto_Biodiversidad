import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  
  /// Realiza una petición GET a la API
  static Future<dynamic> get(String url, {Map<String, String>? additionalHeaders}) async {
    try {
      print('🌐 API GET Request: $url');
      
      final headers = {
        ...ApiConfig.defaultHeaders,
        if (additionalHeaders != null) ...additionalHeaders,
      };
      
      print('📋 Headers: $headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('📱 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Sin conexión a internet');
    } on HttpException {
      throw ApiException('Error de conexión HTTP');
    } catch (e) {
      print('❌ Error en petición GET: $e');
      throw ApiException('Error inesperado: $e');
    }
  }
  
  /// Maneja la respuesta HTTP
  static dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        try {
          return json.decode(response.body);
        } catch (e) {
          throw ApiException('Error al procesar respuesta JSON: $e');
        }
      case 400:
        throw ApiException('Petición incorrecta (400)');
      case 401:
        throw ApiException('No autorizado - Verifica la API key (401)');
      case 403:
        throw ApiException('Acceso prohibido (403)');
      case 404:
        throw ApiException('Recurso no encontrado (404)');
      case 500:
        throw ApiException('Error interno del servidor (500)');
      default:
        throw ApiException('Error HTTP ${response.statusCode}: ${response.body}');
    }
  }
}

/// Excepción personalizada para errores de API
class ApiException implements Exception {
  final String message;
  
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}