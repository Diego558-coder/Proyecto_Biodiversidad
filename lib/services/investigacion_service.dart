import '../models/investigacion.dart';
import 'api_service.dart';

class InvestigacionService {
  static final ApiService _apiService = ApiService();

  static Future<List<Investigacion>> obtenerInvestigaciones() async {
    final respuesta = await _apiService.getResearch();
  return respuesta
    .whereType<Map<String, dynamic>>()
    .map((item) => Investigacion.fromApi(item))
    .toList();
  }

  static Future<Investigacion?> obtenerInvestigacionPorId(String id) async {
    final data = await _apiService.getResearchDetails(id);
    final research = data['research'] as Map<String, dynamic>?;
    if (research == null) {
      return null;
    }
    return Investigacion.fromApi(research);
  }

  static Future<List<Investigacion>> buscarInvestigaciones(String termino) async {
    final all = await obtenerInvestigaciones();
    if (termino.isEmpty) return all;
    return all.where((inv) =>
      inv.titulo.toLowerCase().contains(termino.toLowerCase()) ||
      inv.descripcion.toLowerCase().contains(termino.toLowerCase()) ||
      inv.ubicacion.toLowerCase().contains(termino.toLowerCase())
    ).toList();
  }

  static Future<List<Investigacion>> filtrarPorEstado(String estado) async {
    final all = await obtenerInvestigaciones();
    return all.where((inv) => inv.estado.toLowerCase() == estado.toLowerCase()).toList();
  }
}
