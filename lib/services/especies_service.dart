import '../models/especie.dart';

class EspeciesService {
  // Datos estáticos que coinciden con los mockups
  static List<Especie> _especiesEstaticas = [
    Especie(
      id: '1',
      nombre: 'Cardinalis cardinalis',
      individuos: 2,
      informacionBasica: InformacionBasica(
        metodoDeteccion: 'Visual',
        distancia: 'No registrada',
        actividad: 'Parcha',
        sustrato: 'Arbóreo',
        estrato: 'Medio',
      ),
      composicionPoblacional: ComposicionPoblacional(
        abundancia: 2,
        machos: 2,
        hembras: 2,
        indeterminados: 2,
        adultos: 2,
        juveniles: 2,
      ),
      morfologiaDetallada: MorfologiaDetallada(
        pico: Pico(
          altura: 'No medida',
          ancho: 'No medida',
          anchoNarinas: 'No medida',
          anchoComisura: 'No medida',
          curvatura: 'No medida',
          culmenTotal: 18.5,
          culmenExpuesto: 12.2,
        ),
        alas: Alas(
          altura: 'No medida',
          cuerda: 85.3,
          distanciaPrimariaSecundaria: 'No medida',
          envergadura: 215.7,
        ),
        patas: Patas(
          garraHallux: 8.4,
          longitudHallux: 'No medida',
          longitudTarso: 22.1,
        ),
        cola: Cola(
          longitud: 78.9,
          graduacion: 'No medida',
        ),
        masaCorporal: 42.5,
      ),
      observaciones: 'No hay observaciones registradas.',
    ),
    Especie(
      id: '2',
      nombre: 'Cardinalis cardinalis',
      individuos: 5,
      informacionBasica: InformacionBasica(
        metodoDeteccion: 'Visual',
        distancia: '10.5',
        actividad: 'Canto',
        sustrato: 'Arbóreo',
        estrato: 'Aéreo',
      ),
      composicionPoblacional: ComposicionPoblacional(
        abundancia: 5,
        machos: 2,
        hembras: 3,
        indeterminados: 0,
        adultos: 4,
        juveniles: 1,
      ),
      morfologiaDetallada: MorfologiaDetallada(
        pico: Pico(
          altura: 'No medida',
          ancho: 'No medida',
          anchoNarinas: 'No medida',
          anchoComisura: 'No medida',
          curvatura: 'No medida',
          culmenTotal: 18.5,
          culmenExpuesto: 12.2,
        ),
        alas: Alas(
          altura: 'No medida',
          cuerda: 85.3,
          distanciaPrimariaSecundaria: 'No medida',
          envergadura: 215.7,
        ),
        patas: Patas(
          garraHallux: 8.4,
          longitudHallux: 'No medida',
          longitudTarso: 22.1,
        ),
        cola: Cola(
          longitud: 78.9,
          graduacion: 'No medida',
        ),
        masaCorporal: 42.5,
      ),
      observaciones: 'Individuo posado en rama alta',
    ),
  ];

  /// Obtiene todas las especies de una investigación
  static Future<List<Especie>> obtenerEspeciesPorInvestigacion(String investigacionId) async {
    await Future.delayed(Duration(milliseconds: 500));
    return _especiesEstaticas;
  }

  /// Obtiene una especie por ID
  static Future<Especie?> obtenerEspeciePorId(String id) async {
    await Future.delayed(Duration(milliseconds: 300));
    try {
      return _especiesEstaticas.firstWhere((especie) => especie.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene estadísticas generales de especies
  static Future<Map<String, dynamic>> obtenerEstadisticas(String investigacionId) async {
    await Future.delayed(Duration(milliseconds: 300));
    
    int totalEspecies = _especiesEstaticas.length;
    int totalIndividuos = _especiesEstaticas.fold(0, (sum, especie) => sum + especie.individuos);
    
    int totalMachos = _especiesEstaticas.fold(0, (sum, especie) => 
        sum + especie.composicionPoblacional.machos);
    int totalHembras = _especiesEstaticas.fold(0, (sum, especie) => 
        sum + especie.composicionPoblacional.hembras);
    int totalIndeterminados = _especiesEstaticas.fold(0, (sum, especie) => 
        sum + especie.composicionPoblacional.indeterminados);
    
    return {
      'totalEspecies': totalEspecies,
      'totalIndividuos': totalIndividuos,
      'totalMachos': totalMachos,
      'totalHembras': totalHembras,
      'totalIndeterminados': totalIndeterminados,
    };
  }
}