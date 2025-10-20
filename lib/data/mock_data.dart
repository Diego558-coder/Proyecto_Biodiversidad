import '../models/investigacion.dart';
import '../models/especie.dart';
import '../models/punto_muestreo.dart';

class MockData {
  // Datos mock de investigaciones
  static final List<Investigacion> investigaciones = [
    Investigacion(
      id: 'inv-001',
      titulo: 'Diversidad de Aves en el Parque Natural Chicaque',
      ubicacion: 'Cundinamarca, Colombia',
      descripcion: 'Estudio de diversidad y abundancia de especies de aves en el ecosistema de bosque andino del Parque Natural Chicaque',
      fecha: '2024-01-15',
      habitat: 'Bosque andino',
      vegetacion: 'Bosque secundario con especies nativas',
      estado: 'Finalizada',
      ubicacionEstudio: UbicacionEstudio(
        pais: 'Colombia',
        departamento: 'Cundinamarca',
        ciudad: 'San Antonio del Tequendama',
        barrioVereda: 'Vereda Chicaque',
        lugarEspecifico: 'Parque Natural Chicaque',
        coordenadas: CoordenadasGPS(
          latitud: 4.6097,
          longitud: -74.3081,
          descripcion: 'Centro del parque natural',
        ),
      ),
      equipoTrabajo: EquipoTrabajo(
        lider: 'Dr. María González',
        miembros: [
          'Biólogo Carlos Rodríguez',
          'Estudiante Ana Martínez',
          'Guía local Pedro Jiménez'
        ],
      ),
      objetivos: [
        'Identificar especies de aves presentes en el área',
        'Evaluar el estado de conservación del hábitat',
        'Determinar patrones de distribución altitudinal',
        'Documentar comportamientos reproductivos'
      ],
      resultados: [
        'Se identificaron 87 especies de aves',
        '15 especies endémicas registradas',
        'Alto grado de conservación del bosque',
        'Presencia de especies indicadoras de calidad ambiental'
      ],
      datosGenerales: DatosGenerales(
        periodoEstudio: 'Enero - Marzo 2024',
        habitat: 'Bosque andino',
        vegetacion: 'Bosque secundario con especies nativas',
        altitud: '2100-2600 m.s.n.m',
      ),
    ),
    Investigacion(
      id: 'inv-002',
      titulo: 'Monitoreo de Aves Acuáticas - Humedal La Conejera',
      ubicacion: 'Bogotá, Colombia',
      descripcion: 'Seguimiento de poblaciones de aves acuáticas migratorias y residentes en el Humedal La Conejera',
      fecha: '2024-02-01',
      habitat: 'Humedal urbano',
      vegetacion: 'Vegetación acuática y semiacuática',
      estado: 'En ejecución',
      ubicacionEstudio: UbicacionEstudio(
        pais: 'Colombia',
        departamento: 'Cundinamarca',
        ciudad: 'Bogotá',
        barrioVereda: 'Localidad de Suba',
        lugarEspecifico: 'Humedal La Conejera',
        coordenadas: CoordenadasGPS(
          latitud: 4.7589,
          longitud: -74.0489,
          descripcion: 'Sector central del humedal',
        ),
      ),
      equipoTrabajo: EquipoTrabajo(
        lider: 'Dr. Roberto Silva',
        miembros: [
          'Bióloga Sandra López',
          'Estudiante Miguel Herrera',
          'Voluntario Luis Morales'
        ],
      ),
      objetivos: [
        'Monitorear especies migratorias',
        'Evaluar calidad del agua',
        'Identificar amenazas al ecosistema',
        'Proponer medidas de conservación'
      ],
      resultados: [
        'Registro de 34 especies acuáticas',
        '8 especies migratorias confirmadas',
        'Detección de contaminación por plásticos',
        'Propuestas de restauración implementadas'
      ],
      datosGenerales: DatosGenerales(
        periodoEstudio: 'Febrero - Diciembre 2024',
        habitat: 'Humedal urbano',
        vegetacion: 'Vegetación acuática y semiacuática',
        altitud: '2540 m.s.n.m',
      ),
    ),
    Investigacion(
      id: 'inv-003',
      titulo: 'Estudio de Colibríes en el Jardín Botánico José Celestino Mutis',
      ubicacion: 'Bogotá, Colombia',
      descripcion: 'Investigación sobre diversidad, comportamiento y preferencias alimentarias de colibríes en ambiente urbano controlado',
      fecha: '2023-11-20',
      habitat: 'Jardín botánico urbano',
      vegetacion: 'Plantas ornamentales nativas e introducidas',
      estado: 'Finalizada',
      ubicacionEstudio: UbicacionEstudio(
        pais: 'Colombia',
        departamento: 'Cundinamarca',
        ciudad: 'Bogotá',
        barrioVereda: 'Localidad de Engativá',
        lugarEspecifico: 'Jardín Botánico José Celestino Mutis',
        coordenadas: CoordenadasGPS(
          latitud: 4.6707,
          longitud: -74.1039,
          descripcion: 'Área de jardines temáticos',
        ),
      ),
      equipoTrabajo: EquipoTrabajo(
        lider: 'Dra. Patricia Ramírez',
        miembros: [
          'Ornitólogo Juan Carlos Peña',
          'Estudiante Laura Vega',
          'Fotógrafo especializado David Torres'
        ],
      ),
      objetivos: [
        'Catalogar especies de colibríes residentes',
        'Estudiar preferencias florales',
        'Analizar patrones de comportamiento territorial',
        'Evaluar éxito reproductivo'
      ],
      resultados: [
        '12 especies de colibríes identificadas',
        '23 plantas con alta visitación documentadas',
        'Comportamientos reproductivos registrados',
        'Mapa de territorios establecido'
      ],
      datosGenerales: DatosGenerales(
        periodoEstudio: 'Noviembre 2023 - Enero 2024',
        habitat: 'Jardín botánico urbano',
        vegetacion: 'Plantas ornamentales nativas e introducidas',
        altitud: '2558 m.s.n.m',
      ),
    ),
  ];

  // Datos mock de especies por investigación
  static final Map<String, List<Especie>> especiesPorInvestigacion = {
    'inv-001': [
      Especie(
        id: 'esp-001-01',
        nombre: 'Turdus fuscater (Mirla Patinaranja)',
        individuos: 23,
        informacionBasica: InformacionBasica(
          metodoDeteccion: 'Visual y auditivo',
          distancia: '5-15 metros',
          actividad: 'Forrajeo en suelo',
          sustrato: 'Suelo y vegetación baja',
          estrato: 'Sotobosque',
        ),
        composicionPoblacional: ComposicionPoblacional(
          abundancia: 23,
          machos: 12,
          hembras: 11,
          indeterminados: 0,
          adultos: 18,
          juveniles: 5,
        ),
        morfologiaDetallada: MorfologiaDetallada(
          pico: Pico(
            altura: '8.5 mm',
            ancho: '7.2 mm',
            culmenTotal: 15.8,
            culmenExpuesto: 12.3,
          ),
          alas: Alas(
            cuerda: 118.5,
            envergadura: 245.0,
          ),
          patas: Patas(
            longitudTarso: 28.4,
            garraHallux: 6.8,
          ),
          cola: Cola(
            longitud: 95.2,
            graduacion: 'Cuadrada',
          ),
          masaCorporal: 62.5,
        ),
        observaciones: 'Especie muy común en el área. Observada principalmente en horas de la mañana. Presenta comportamiento territorial marcado.',
      ),
      Especie(
        id: 'esp-001-02',
        nombre: 'Colibri coruscans (Colibrí Orejivioleta Ventriazul)',
        individuos: 8,
        informacionBasica: InformacionBasica(
          metodoDeteccion: 'Visual',
          distancia: '3-8 metros',
          actividad: 'Nectarívoro',
          sustrato: 'Flores y perchas',
          estrato: 'Dosel medio',
        ),
        composicionPoblacional: ComposicionPoblacional(
          abundancia: 8,
          machos: 5,
          hembras: 3,
          indeterminados: 0,
          adultos: 6,
          juveniles: 2,
        ),
        morfologiaDetallada: MorfologiaDetallada(
          pico: Pico(
            altura: '2.8 mm',
            ancho: '2.1 mm',
            culmenTotal: 18.2,
            culmenExpuesto: 15.6,
          ),
          alas: Alas(
            cuerda: 68.3,
            envergadura: 130.0,
          ),
          patas: Patas(
            longitudTarso: 5.8,
            garraHallux: 2.1,
          ),
          cola: Cola(
            longitud: 42.8,
            graduacion: 'Bifurcada',
          ),
          masaCorporal: 8.2,
        ),
        observaciones: 'Colibrí de alta montaña. Muy territorial alrededor de fuentes de néctar. Vuelo característico con zumbido audible.',
      ),
      Especie(
        id: 'esp-001-03',
        nombre: 'Anisognathus igniventris (Tangara Montana Dorsiazul)',
        individuos: 15,
        informacionBasica: InformacionBasica(
          metodoDeteccion: 'Visual y auditivo',
          distancia: '8-20 metros',
          actividad: 'Forrajeo en grupos',
          sustrato: 'Copas de árboles',
          estrato: 'Dosel',
        ),
        composicionPoblacional: ComposicionPoblacional(
          abundancia: 15,
          machos: 8,
          hembras: 7,
          indeterminados: 0,
          adultos: 12,
          juveniles: 3,
        ),
        morfologiaDetallada: MorfologiaDetallada(
          pico: Pico(
            altura: '5.4 mm',
            ancho: '4.8 mm',
            culmenTotal: 12.6,
            culmenExpuesto: 9.8,
          ),
          alas: Alas(
            cuerda: 78.9,
            envergadura: 165.0,
          ),
          patas: Patas(
            longitudTarso: 18.2,
            garraHallux: 4.5,
          ),
          cola: Cola(
            longitud: 58.4,
            graduacion: 'Redondeada',
          ),
          masaCorporal: 24.8,
        ),
        observaciones: 'Especie gregaria. Frecuentemente en bandadas mixtas. Coloración muy llamativa especialmente en machos.',
      ),
    ],
    'inv-002': [
      Especie(
        id: 'esp-002-01',
        nombre: 'Gallinula galeata (Polla de Agua)',
        individuos: 12,
        informacionBasica: InformacionBasica(
          metodoDeteccion: 'Visual',
          distancia: '10-30 metros',
          actividad: 'Natación y forrajeo',
          sustrato: 'Agua y vegetación acuática',
          estrato: 'Superficie del agua',
        ),
        composicionPoblacional: ComposicionPoblacional(
          abundancia: 12,
          machos: 6,
          hembras: 6,
          indeterminados: 0,
          adultos: 8,
          juveniles: 4,
        ),
        morfologiaDetallada: MorfologiaDetallada(
          pico: Pico(
            altura: '6.8 mm',
            ancho: '5.2 mm',
            culmenTotal: 28.4,
            culmenExpuesto: 22.1,
          ),
          alas: Alas(
            cuerda: 165.8,
            envergadura: 310.0,
          ),
          patas: Patas(
            longitudTarso: 52.6,
            garraHallux: 8.9,
          ),
          cola: Cola(
            longitud: 68.2,
            graduacion: 'Cuadrada',
          ),
          masaCorporal: 285.5,
        ),
        observaciones: 'Ave acuática residente. Construcción de nidos observada en época reproductiva. Muy adaptada al ambiente urbano.',
      ),
      Especie(
        id: 'esp-002-02',
        nombre: 'Anas discors (Cerceta Alidiscus)',
        individuos: 6,
        informacionBasica: InformacionBasica(
          metodoDeteccion: 'Visual',
          distancia: '15-40 metros',
          actividad: 'Natación y buceo superficial',
          sustrato: 'Agua abierta',
          estrato: 'Superficie del agua',
        ),
        composicionPoblacional: ComposicionPoblacional(
          abundancia: 6,
          machos: 4,
          hembras: 2,
          indeterminados: 0,
          adultos: 6,
          juveniles: 0,
        ),
        morfologiaDetallada: MorfologiaDetallada(
          pico: Pico(
            altura: '8.2 mm',
            ancho: '16.8 mm',
            culmenTotal: 38.6,
            culmenExpuesto: 32.4,
          ),
          alas: Alas(
            cuerda: 185.4,
            envergadura: 380.0,
          ),
          patas: Patas(
            longitudTarso: 32.8,
            garraHallux: 5.6,
          ),
          cola: Cola(
            longitud: 78.5,
            graduacion: 'Redondeada',
          ),
          masaCorporal: 365.2,
        ),
        observaciones: 'Especie migratoria. Presente durante temporada seca. Comportamiento gregario con otras especies de patos.',
      ),
    ],
    'inv-003': [
      Especie(
        id: 'esp-003-01',
        nombre: 'Amazilia tzacatl (Colibrí Colirrufo)',
        individuos: 18,
        informacionBasica: InformacionBasica(
          metodoDeteccion: 'Visual',
          distancia: '2-6 metros',
          actividad: 'Nectarívoro',
          sustrato: 'Flores ornamentales',
          estrato: 'Vegetación media',
        ),
        composicionPoblacional: ComposicionPoblacional(
          abundancia: 18,
          machos: 10,
          hembras: 8,
          indeterminados: 0,
          adultos: 14,
          juveniles: 4,
        ),
        morfologiaDetallada: MorfologiaDetallada(
          pico: Pico(
            altura: '2.4 mm',
            ancho: '1.8 mm',
            culmenTotal: 19.8,
            culmenExpuesto: 17.2,
          ),
          alas: Alas(
            cuerda: 54.6,
            envergadura: 115.0,
          ),
          patas: Patas(
            longitudTarso: 4.2,
            garraHallux: 1.8,
          ),
          cola: Cola(
            longitud: 32.4,
            graduacion: 'Bifurcada',
          ),
          masaCorporal: 4.8,
        ),
        observaciones: 'Colibrí muy común en jardines urbanos. Prefiere flores de Salvia y Fucsia. Establecimiento de territorios marcado.',
      ),
      Especie(
        id: 'esp-003-02',
        nombre: 'Colibri thalassinus (Colibrí Orejivioleta Verde)',
        individuos: 9,
        informacionBasica: InformacionBasica(
          metodoDeteccion: 'Visual',
          distancia: '3-8 metros',
          actividad: 'Nectarívoro y insectívoro',
          sustrato: 'Flores y perchas',
          estrato: 'Dosel medio y alto',
        ),
        composicionPoblacional: ComposicionPoblacional(
          abundancia: 9,
          machos: 5,
          hembras: 4,
          indeterminados: 0,
          adultos: 7,
          juveniles: 2,
        ),
        morfologiaDetallada: MorfologiaDetallada(
          pico: Pico(
            altura: '3.1 mm',
            ancho: '2.2 mm',
            culmenTotal: 22.4,
            culmenExpuesto: 19.1,
          ),
          alas: Alas(
            cuerda: 72.8,
            envergadura: 140.0,
          ),
          patas: Patas(
            longitudTarso: 6.4,
            garraHallux: 2.6,
          ),
          cola: Cola(
            longitud: 48.6,
            graduacion: 'Escotada',
          ),
          masaCorporal: 9.4,
        ),
        observaciones: 'Colibrí de tamaño medio. Comportamiento agresivo hacia otras especies. Construcción de nidos observada en eucaliptos.',
      ),
    ],
  };

  // Datos mock de puntos de muestreo por investigación
  static final Map<String, List<PuntoMuestreo>> puntosPorInvestigacion = {
    'inv-001': [
      PuntoMuestreo(
        id: 'punto-001-01',
        nombre: 'Sendero Principal - Entrada',
        ubicacion: Ubicacion(
          altitud: 2150.0,
          longitud: -74.3075,
        ),
        metodologia: MetodologiaMuestreo(
          tipoMuestreo: 'Punto de conteo',
          detalleMuestreo: 'Radio fijo de 25 metros',
          metodoDeteccion: 'Visual y auditivo',
        ),
        parametrosCenso: ParametrosCenso(
          periodoCenso: 10,
          radioFijo: 25,
        ),
        duracionMuestreo: DuracionMuestreo(
          fechaInicio: DateTime(2024, 1, 15),
          fechaFinalizacion: DateTime(2024, 1, 20),
        ),
        muestras: [
          Muestra(
            id: 'muestra-001-01',
            nombre: 'Censo matutino día 1',
            temperatura: 16.5,
            humedad: 85,
            condiciones: CondicionesAmbientales(
              precipitacion: 'Sin lluvia',
              nubosidad: 'Parcialmente nublado',
              luminosidad: 'Buena',
              condiciones: 'Óptimas para observación',
            ),
          ),
          Muestra(
            id: 'muestra-001-02',
            nombre: 'Censo vespertino día 1',
            temperatura: 18.2,
            humedad: 78,
            condiciones: CondicionesAmbientales(
              precipitacion: 'Llovizna ligera',
              nubosidad: 'Nublado',
              luminosidad: 'Media',
              condiciones: 'Aceptables',
            ),
          ),
        ],
      ),
      PuntoMuestreo(
        id: 'punto-001-02',
        nombre: 'Mirador Alto',
        ubicacion: Ubicacion(
          altitud: 2580.0,
          longitud: -74.3098,
        ),
        metodologia: MetodologiaMuestreo(
          tipoMuestreo: 'Transecto lineal',
          detalleMuestreo: 'Transecto de 200 metros',
          metodoDeteccion: 'Visual principalmente',
        ),
        parametrosCenso: ParametrosCenso(
          periodoCenso: 15,
          radioFijo: 50,
        ),
        duracionMuestreo: DuracionMuestreo(
          fechaInicio: DateTime(2024, 1, 16),
          fechaFinalizacion: DateTime(2024, 1, 18),
        ),
        muestras: [
          Muestra(
            id: 'muestra-001-03',
            nombre: 'Transecto mirador',
            temperatura: 14.8,
            humedad: 90,
            condiciones: CondicionesAmbientales(
              precipitacion: 'Sin lluvia',
              nubosidad: 'Despejado',
              luminosidad: 'Excelente',
              condiciones: 'Excelentes para fotografía',
            ),
          ),
        ],
      ),
    ],
    'inv-002': [
      PuntoMuestreo(
        id: 'punto-002-01',
        nombre: 'Sector Norte del Humedal',
        ubicacion: Ubicacion(
          altitud: 2540.0,
          longitud: -74.0485,
        ),
        metodologia: MetodologiaMuestreo(
          tipoMuestreo: 'Observación desde punto fijo',
          detalleMuestreo: 'Observación con telescopio desde caseta',
          metodoDeteccion: 'Visual con equipos ópticos',
        ),
        parametrosCenso: ParametrosCenso(
          periodoCenso: 30,
          radioFijo: 100,
        ),
        duracionMuestreo: DuracionMuestreo(
          fechaInicio: DateTime(2024, 2, 1),
          fechaFinalizacion: DateTime(2024, 2, 5),
        ),
        muestras: [
          Muestra(
            id: 'muestra-002-01',
            nombre: 'Censo aves acuáticas mañana',
            temperatura: 18.5,
            humedad: 88,
            condiciones: CondicionesAmbientales(
              precipitacion: 'Sin lluvia',
              nubosidad: 'Despejado',
              luminosidad: 'Buena',
              condiciones: 'Ideales para conteo',
            ),
          ),
        ],
      ),
    ],
    'inv-003': [
      PuntoMuestreo(
        id: 'punto-003-01',
        nombre: 'Jardín de Colibríes',
        ubicacion: Ubicacion(
          altitud: 2558.0,
          longitud: -74.1042,
        ),
        metodologia: MetodologiaMuestreo(
          tipoMuestreo: 'Observación focal',
          detalleMuestreo: 'Seguimiento de individuos marcados',
          metodoDeteccion: 'Visual con cámaras de alta velocidad',
        ),
        parametrosCenso: ParametrosCenso(
          periodoCenso: 20,
          radioFijo: 15,
        ),
        duracionMuestreo: DuracionMuestreo(
          fechaInicio: DateTime(2023, 11, 20),
          fechaFinalizacion: DateTime(2023, 11, 25),
        ),
        muestras: [
          Muestra(
            id: 'muestra-003-01',
            nombre: 'Comportamiento territorial',
            temperatura: 19.2,
            humedad: 65,
            condiciones: CondicionesAmbientales(
              precipitacion: 'Sin lluvia',
              nubosidad: 'Despejado',
              luminosidad: 'Excelente',
              condiciones: 'Perfectas para filmación',
            ),
          ),
        ],
      ),
    ],
  };

  // Métodos para obtener datos específicos
  static List<Especie> getEspeciesPorInvestigacion(String investigacionId) {
    return especiesPorInvestigacion[investigacionId] ?? [];
  }

  static List<PuntoMuestreo> getPuntosPorInvestigacion(String investigacionId) {
    return puntosPorInvestigacion[investigacionId] ?? [];
  }

  static Investigacion? getInvestigacionPorId(String id) {
    try {
      return investigaciones.firstWhere((inv) => inv.id == id);
    } catch (e) {
      return null;
    }
  }

  static Especie? getEspeciePorId(String especieId, String investigacionId) {
    final especies = getEspeciesPorInvestigacion(investigacionId);
    try {
      return especies.firstWhere((esp) => esp.id == especieId);
    } catch (e) {
      return null;
    }
  }

  static PuntoMuestreo? getPuntoPorId(String puntoId, String investigacionId) {
    final puntos = getPuntosPorInvestigacion(investigacionId);
    try {
      return puntos.firstWhere((punto) => punto.id == puntoId);
    } catch (e) {
      return null;
    }
  }
}