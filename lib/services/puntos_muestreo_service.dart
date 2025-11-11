import '../models/punto_muestreo.dart';


class PuntosMuestreoService {
  PuntosMuestreoService._();

  static Future<List<PuntoMuestreo>> obtenerPuntosPorInvestigacion(String investigacionId) async {
    throw UnsupportedError(
      'PuntosMuestreoService ya no está disponible. Usa los datos provenientes de la investigación detallada.',
    );
  }

  static Future<PuntoMuestreo?> obtenerPuntoPorId(String puntoId, String investigacionId) async {
    throw UnsupportedError(
      'PuntosMuestreoService ya no está disponible. Usa los datos provenientes de la investigación detallada.',
    );
  }
}
