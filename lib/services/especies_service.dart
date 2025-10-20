import '../models/especie.dart';
import '../data/mock_data.dart';

class EspeciesService {
  /// Obtiene especies desde los datos mock.
  static Future<List<Especie>> obtenerEspeciesPorInvestigacion(String investigacionId) async {
    // Simular delay de red para mantener la funcionalidad async
    await Future.delayed(const Duration(milliseconds: 300));
    return MockData.getEspeciesPorInvestigacion(investigacionId);
  }

  /// Obtiene una especie por ID desde los datos mock
  static Future<Especie?> obtenerEspeciePorId(String especieId, String investigacionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return MockData.getEspeciePorId(especieId, investigacionId);
  }

  /// Estadísticas agregadas a partir de la lista de especies de los datos mock
  static Future<Map<String, dynamic>> obtenerEstadisticas(String investigacionId) async {
    final especies = await obtenerEspeciesPorInvestigacion(investigacionId);
    final totalEspecies = especies.length;
    final totalIndividuos = especies.fold<int>(0, (sum, e) => sum + e.individuos);
    final totalMachos = especies.fold<int>(0, (sum, e) => sum + e.composicionPoblacional.machos);
    final totalHembras = especies.fold<int>(0, (sum, e) => sum + e.composicionPoblacional.hembras);
    final totalIndeterminados = especies.fold<int>(0, (sum, e) => sum + e.composicionPoblacional.indeterminados);

    return {
      'totalEspecies': totalEspecies,
      'totalIndividuos': totalIndividuos,
      'totalMachos': totalMachos,
      'totalHembras': totalHembras,
      'totalIndeterminados': totalIndeterminados,
    };
  }
}
