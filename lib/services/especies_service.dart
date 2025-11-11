import '../models/especie.dart';


class EspeciesService {
  EspeciesService._();

  static Future<List<Especie>> obtenerEspeciesPorInvestigacion(String investigacionId) async {
    throw UnsupportedError(
      'EspeciesService ya no está disponible. Usa los datos provenientes de la investigación detallada.',
    );
  }

  static Future<Especie?> obtenerEspeciePorId(String especieId, String investigacionId) async {
    throw UnsupportedError(
      'EspeciesService ya no está disponible. Usa los datos provenientes de la investigación detallada.',
    );
  }

  static Future<Map<String, dynamic>> obtenerEstadisticas(String investigacionId) async {
    throw UnsupportedError(
      'EspeciesService ya no está disponible. Usa los datos provenientes de la investigación detallada.',
    );
  }
}
