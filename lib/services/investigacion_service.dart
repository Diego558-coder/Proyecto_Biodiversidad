import '../models/investigacion.dart';
import '../models/investigador.dart';
import '../config/api_config.dart';
import 'api_service.dart';
class InvestigacionService {
  
  /// Método de prueba para conectar con la API real
  static Future<void> testApiConnection() async {
    try {
      print('🔄 Probando conexión con la API...');
      final response = await ApiService.get(ApiConfig.researchUrl);
      print('✅ Conexión exitosa!');
      print('📊 Estructura de datos recibidos: $response');
    } catch (e) {
      print('❌ Error al conectar con la API: $e');
      rethrow;
    }
  }
  
  // Datos estáticos que coinciden con los mockups
  static List<Investigacion> _investigacionesEstaticas = [
    Investigacion(
      id: '1',
      titulo: 'Estudio de biodiversidad urbana',
      ubicacion: 'Parque central, Bogotá',
      descripcion: 'Investigación sobre aves en parque de la ciudad',
      fecha: 'Enero 2023-Dic 2023',
      habitat: 'Urbano',
      vegetacion: 'Bosque de Robles',
      estado: 'Ejecución',
      ubicacionEstudio: UbicacionEstudio(
        pais: 'Colombia',
        departamento: 'Cundinamarca',
        ciudad: 'Bogotá',
        barrioVereda: 'Centro/Vereda 1',
        lugarEspecifico: 'Parque central',
        coordenadas: CoordenadasGPS(
          latitud: 4.711,
          longitud: -74.0721,
          descripcion: '4.711°N -74.0721°W',
        ),
      ),
      equipoTrabajo: EquipoTrabajo(
        lider: 'Pepito Pérez',
        miembros: ['Juan Sebastian'],
      ),
      objetivos: [
        'Objetivo 1: Identificar especies de aves en el parque central',
        'Objetivo 2: Analizar la diversidad de especies por época del año',
      ],
      resultados: [
        'Resultado preliminar 1: Se han identificado 15 especies diferentes',
      ],
      datosGenerales: DatosGenerales(
        periodoEstudio: '01/01/2023 12:00 PM (UTC)-01/12/2023 12:00PM (UTC)',
        habitat: 'Urbano',
        vegetacion: 'Bosque de robles',
        altitud: '1200',
      ),
    ),
    Investigacion(
      id: '2',
      titulo: 'Estudio de biodiversidad urbana',
      ubicacion: 'Parque central, Bogotá',
      descripcion: 'En proceso de definición',
      fecha: 'No establecidas',
      habitat: 'Ubicación pendiente',
      vegetacion: 'Información pendiente',
      estado: 'Ejecución',
      ubicacionEstudio: UbicacionEstudio(
        pais: 'Colombia',
        departamento: 'Cundinamarca',
        ciudad: 'Bogotá',
        barrioVereda: 'Centro/Vereda 1',
        lugarEspecifico: 'Parque central',
        coordenadas: CoordenadasGPS(
          latitud: 4.711,
          longitud: -74.0721,
          descripcion: '4.711°N -74.0721°W',
        ),
      ),
      equipoTrabajo: EquipoTrabajo(
        lider: 'Pepito Pérez',
        miembros: ['Juan Sebastian'],
      ),
      objetivos: [
        'Objetivo 1: Por definir',
        'Objetivo 2: Por definir',
      ],
      resultados: [
        'Pendiente por iniciar el estudio',
      ],
      datosGenerales: DatosGenerales(
        periodoEstudio: 'No establecido',
        habitat: 'Ubicación pendiente',
        vegetacion: 'Información pendiente',
        altitud: 'Por determinar',
      ),
    ),
  ];

  /// Obtiene todas las investigaciones
  static Future<List<Investigacion>> obtenerInvestigaciones() async {
    // Simular delay de API
    await Future.delayed(Duration(milliseconds: 500));
    return _investigacionesEstaticas;
  }

  /// Obtiene una investigación por ID
  static Future<Investigacion?> obtenerInvestigacionPorId(String id) async {
    await Future.delayed(Duration(milliseconds: 300));
    try {
      return _investigacionesEstaticas.firstWhere((inv) => inv.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Busca investigaciones por término
  static Future<List<Investigacion>> buscarInvestigaciones(String termino) async {
    await Future.delayed(Duration(milliseconds: 400));
    if (termino.isEmpty) return _investigacionesEstaticas;
    
    return _investigacionesEstaticas.where((inv) =>
      inv.titulo.toLowerCase().contains(termino.toLowerCase()) ||
      inv.descripcion.toLowerCase().contains(termino.toLowerCase()) ||
      inv.ubicacion.toLowerCase().contains(termino.toLowerCase())
    ).toList();
  }

  /// Filtra investigaciones por estado
  static Future<List<Investigacion>> filtrarPorEstado(String estado) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _investigacionesEstaticas.where((inv) =>
      inv.estado.toLowerCase() == estado.toLowerCase()
    ).toList();
  }

  // Métodos para futuro uso con API
  static Future<Investigacion> crearInvestigacion(Investigacion investigacion) async {
    // TODO: Implementar llamada a API
    throw UnimplementedError('Método pendiente de implementar con API');
  }

  static Future<Investigacion> actualizarInvestigacion(Investigacion investigacion) async {
    // TODO: Implementar llamada a API
    throw UnimplementedError('Método pendiente de implementar con API');
  }

  static Future<void> eliminarInvestigacion(String id) async {
    // TODO: Implementar llamada a API
    throw UnimplementedError('Método pendiente de implementar con API');
  }
}