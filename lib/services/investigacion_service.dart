import '../models/investigacion.dart';
import '../data/mock_data.dart';

class InvestigacionService {
  /// Obtiene todas las investigaciones desde los datos mock.
  static Future<List<Investigacion>> obtenerInvestigaciones() async {
    // Simular delay de red para mantener la funcionalidad async
    await Future.delayed(const Duration(milliseconds: 500));
    return MockData.investigaciones;
  }

  /// Obtiene detalle de una investigación por ID desde los datos mock.
  static Future<Investigacion?> obtenerInvestigacionPorId(String id) async {
    // Simular delay de red para mantener la funcionalidad async
    await Future.delayed(const Duration(milliseconds: 300));
    return MockData.getInvestigacionPorId(id);
  }

  /// Búsqueda simple en los datos mock.
  static Future<List<Investigacion>> buscarInvestigaciones(String termino) async {
    final all = await obtenerInvestigaciones();
    if (termino.isEmpty) return all;
    return all.where((inv) =>
      inv.titulo.toLowerCase().contains(termino.toLowerCase()) ||
      inv.descripcion.toLowerCase().contains(termino.toLowerCase()) ||
      inv.ubicacion.toLowerCase().contains(termino.toLowerCase())
    ).toList();
  }

  /// Filtra por estado en los datos mock.
  static Future<List<Investigacion>> filtrarPorEstado(String estado) async {
    final all = await obtenerInvestigaciones();
    return all.where((inv) => inv.estado.toLowerCase() == estado.toLowerCase()).toList();
  }
}
