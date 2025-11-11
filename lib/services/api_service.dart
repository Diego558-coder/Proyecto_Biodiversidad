import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';

class ApiService {
  Future<List<dynamic>> getResearch() async {
    final url = Uri.parse("${AppConfig.baseUrl}/research");
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${AppConfig.apiKey}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al obtener investigaciones: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] != true || body['data'] is! List) {
      throw Exception('Respuesta inválida al obtener investigaciones');
    }

    return List<dynamic>.from(body['data'] as List);
  }

  Future<Map<String, dynamic>> getResearchDetails(String uuid) async {
    final url = Uri.parse("${AppConfig.baseUrl}/details/research/$uuid");
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${AppConfig.apiKey}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al obtener detalles de la investigación: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] != true || body['data'] is! Map<String, dynamic>) {
      throw Exception('Respuesta inválida al obtener detalles de la investigación');
    }

    return Map<String, dynamic>.from(body['data'] as Map);
  }
}