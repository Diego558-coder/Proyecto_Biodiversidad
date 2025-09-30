import '../models/punto_muestreo.dart';

class PuntosMuestreoService {
  // Datos estáticos que coinciden con los mockups
  static PuntoMuestreo _puntoMuestreoEstatico = PuntoMuestreo(
    id: '1',
    nombre: 'Punto 1',
    ubicacion: Ubicacion(
      altitud: 1.6610363970634727,
      longitud: 75.6274835637284,
    ),
    metodologia: MetodologiaMuestreo(
      tipoMuestreo: 'Punto de observación',
      detalleMuestreo: 'Extensivo',
      metodoDeteccion: 'Visual',
    ),
    parametrosCenso: ParametrosCenso(
      periodoCenso: 30,
      radioFijo: 50,
    ),
    duracionMuestreo: DuracionMuestreo(
      fechaInicio: DateTime.parse('2025-08-01 02:48:11'),
      fechaFinalizacion: DateTime.parse('2025-08-01 02:48:11'),
    ),
    muestras: [
      Muestra(
        id: '1',
        nombre: 'Muestra 1',
        temperatura: 21.0,
        humedad: 21,
        condiciones: CondicionesAmbientales(
          precipitacion: 'Normal',
          nubosidad: '12%',
          luminosidad: 'Normal',
          condiciones: 'Regular',
        ),
      ),
    ],
  );

  /// Obtiene los puntos de muestreo de una investigación
  static Future<List<PuntoMuestreo>> obtenerPuntosPorInvestigacion(String investigacionId) async {
    await Future.delayed(Duration(milliseconds: 500));
    return [_puntoMuestreoEstatico];
  }

  /// Obtiene un punto de muestreo por ID
  static Future<PuntoMuestreo?> obtenerPuntoPorId(String id) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _puntoMuestreoEstatico;
  }

  /// Obtiene el primer punto de muestreo (para mostrar por defecto)
  static Future<PuntoMuestreo> obtenerPuntoPrincipal(String investigacionId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _puntoMuestreoEstatico;
  }
}