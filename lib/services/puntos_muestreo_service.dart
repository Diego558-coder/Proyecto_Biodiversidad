import '../models/punto_muestreo.dart';
import '../data/mock_data.dart';

class PuntosMuestreoService {
  /// Obtiene los puntos de muestreo desde los datos mock
  static Future<List<PuntoMuestreo>> obtenerPuntosPorInvestigacion(String investigacionId) async {
    // Simular delay de red para mantener la funcionalidad async
    await Future.delayed(const Duration(milliseconds: 300));
    return MockData.getPuntosPorInvestigacion(investigacionId);
  }

  /// Obtiene un punto de muestreo por ID desde los datos mock
  static Future<PuntoMuestreo?> obtenerPuntoPorId(String puntoId, String investigacionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return MockData.getPuntoPorId(puntoId, investigacionId);
  }

  /// Obtiene el primer punto (para pantallas que requieren uno por defecto)
  static Future<PuntoMuestreo> obtenerPuntoPrincipal(String investigacionId) async {
    final puntos = await obtenerPuntosPorInvestigacion(investigacionId);
    return puntos.isNotEmpty
        ? puntos.first
        : PuntoMuestreo(
            id: 'sin-id',
            nombre: 'Punto no disponible',
            ubicacion: Ubicacion(altitud: 0, longitud: 0),
            metodologia: MetodologiaMuestreo(tipoMuestreo: '', detalleMuestreo: '', metodoDeteccion: ''),
            parametrosCenso: ParametrosCenso(periodoCenso: 0, radioFijo: 0),
            duracionMuestreo: DuracionMuestreo(fechaInicio: DateTime.now(), fechaFinalizacion: DateTime.now()),
            muestras: const [],
          );
  }
}
