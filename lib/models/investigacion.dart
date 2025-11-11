import 'punto_muestreo.dart';

class Investigacion {
  final String id;
  final String titulo;
  final String ubicacion;
  final String descripcion;
  final String fecha;
  final String habitat;
  final String vegetacion;
  final String estado;
  final UbicacionEstudio ubicacionEstudio;
  final EquipoTrabajo equipoTrabajo;
  final List<String> objetivos;
  final List<String> resultados;
  final DatosGenerales datosGenerales;
  final List<PuntoMuestreo> puntosMuestreo;

  Investigacion({
    required this.id,
    required this.titulo,
    required this.ubicacion,
    required this.descripcion,
    required this.fecha,
    required this.habitat,
    required this.vegetacion,
    required this.estado,
    required this.ubicacionEstudio,
    required this.equipoTrabajo,
    required this.objetivos,
    required this.resultados,
    required this.datosGenerales,
    required this.puntosMuestreo,
  });

  factory Investigacion.fromJson(Map<String, dynamic> json) {
    return Investigacion(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      ubicacion: json['ubicacion'] ?? '',
      descripcion: json['descripcion'] ?? '',
      fecha: json['fecha'] ?? '',
      habitat: json['habitat'] ?? '',
      vegetacion: json['vegetacion'] ?? '',
      estado: json['estado'] ?? '',
      ubicacionEstudio: UbicacionEstudio.fromJson(json['ubicacionEstudio'] ?? {}),
      equipoTrabajo: EquipoTrabajo.fromJson(json['equipoTrabajo'] ?? {}),
      objetivos: List<String>.from(json['objetivos'] ?? []),
      resultados: List<String>.from(json['resultados'] ?? []),
      datosGenerales: DatosGenerales.fromJson(json['datosGenerales'] ?? {}),
      puntosMuestreo: (json['puntosMuestreo'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(PuntoMuestreo.fromApi)
              .toList() ??
          const <PuntoMuestreo>[],
    );
  }

  factory Investigacion.fromApi(Map<String, dynamic> json) {
    final startDate = _parseDate(json['startDate'] as String?);
    final endDate = _parseDate(json['endDate'] as String?);
    final locality = json['locality'] as Map<String, dynamic>?;
    final coordinates = json['coordinates'] as Map<String, dynamic>?;
    final heightValue = _toNullableDouble(json['height']);

    final lat = _toNullableDouble(coordinates?['latitude']);
    final lon = _toNullableDouble(coordinates?['longitude']);

    final objetivos = (json['objectives'] as List?)
            ?.whereType<String>()
            .toList() ??
        <String>[];
    final resultados = (json['results'] as List?)
            ?.whereType<String>()
            .toList() ??
        <String>[];

    final leaderUuid = (json['leader'] as Map<String, dynamic>?)?['uuid'] as String? ?? 'No disponible';
    final teamMembers = (json['team'] as List?)
            ?.map((member) => (member as Map<String, dynamic>)['uuid'] as String?)
            .whereType<String>()
            .toList() ??
        <String>[];
    final miembros = teamMembers.isEmpty ? <String>['Sin miembros registrados'] : teamMembers;

    final coordenadas = CoordenadasGPS(
      latitud: lat ?? 0.0,
      longitud: lon ?? 0.0,
      descripcion: _coordinatesDescription(lat, lon),
    );

    return Investigacion(
      id: json['uuid'] as String? ?? '',
      titulo: json['name'] as String? ?? 'Sin título',
      ubicacion: _buildLocationSummary(locality),
      descripcion: json['description'] as String? ?? 'Sin descripción disponible',
      fecha: _formatDate(startDate),
      habitat: json['habitatType'] as String? ?? 'No especificado',
      vegetacion: json['dominantVegetation'] as String? ?? 'No especificada',
      estado: json['status'] as String? ?? 'Sin estado',
      ubicacionEstudio: UbicacionEstudio(
        pais: locality?['country'] as String? ?? 'No disponible',
        departamento: locality?['state'] as String? ?? 'No disponible',
        ciudad: locality?['city'] as String? ?? 'No disponible',
        barrioVereda: locality?['neighborhood'] as String? ?? 'No disponible',
        lugarEspecifico: locality?['name'] as String? ?? 'No disponible',
        coordenadas: coordenadas,
      ),
      equipoTrabajo: EquipoTrabajo(
        lider: leaderUuid,
        miembros: miembros,
      ),
      objetivos: objetivos,
      resultados: resultados,
      datosGenerales: DatosGenerales(
        periodoEstudio: _formatPeriod(startDate, endDate),
        habitat: json['habitatType'] as String? ?? 'No especificado',
        vegetacion: json['dominantVegetation'] as String? ?? 'No especificada',
        altitud: heightValue != null
            ? '${heightValue.toStringAsFixed(0)} msnm'
            : 'No reportada',
      ),
      puntosMuestreo: (json['samplingPoints'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(PuntoMuestreo.fromApi)
              .toList() ??
          const <PuntoMuestreo>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'ubicacion': ubicacion,
      'descripcion': descripcion,
      'fecha': fecha,
      'habitat': habitat,
      'vegetacion': vegetacion,
      'estado': estado,
      'ubicacionEstudio': ubicacionEstudio.toJson(),
      'equipoTrabajo': equipoTrabajo.toJson(),
      'objetivos': objetivos,
      'resultados': resultados,
      'datosGenerales': datosGenerales.toJson(),
      'puntosMuestreo': puntosMuestreo.map((p) => {
            'uuid': p.id,
            'pointNumber': p.numero,
          }).toList(),
    };
  }
}

class UbicacionEstudio {
  final String pais;
  final String departamento;
  final String ciudad;
  final String barrioVereda;
  final String lugarEspecifico;
  final CoordenadasGPS coordenadas;

  UbicacionEstudio({
    required this.pais,
    required this.departamento,
    required this.ciudad,
    required this.barrioVereda,
    required this.lugarEspecifico,
    required this.coordenadas,
  });

  factory UbicacionEstudio.fromJson(Map<String, dynamic> json) {
    return UbicacionEstudio(
      pais: json['pais'] ?? '',
      departamento: json['departamento'] ?? '',
      ciudad: json['ciudad'] ?? '',
      barrioVereda: json['barrioVereda'] ?? '',
      lugarEspecifico: json['lugarEspecifico'] ?? '',
      coordenadas: CoordenadasGPS.fromJson(json['coordenadas'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pais': pais,
      'departamento': departamento,
      'ciudad': ciudad,
      'barrioVereda': barrioVereda,
      'lugarEspecifico': lugarEspecifico,
      'coordenadas': coordenadas.toJson(),
    };
  }
}

class CoordenadasGPS {
  final double latitud;
  final double longitud;
  final String descripcion;

  CoordenadasGPS({
    required this.latitud,
    required this.longitud,
    required this.descripcion,
  });

  factory CoordenadasGPS.fromJson(Map<String, dynamic> json) {
    return CoordenadasGPS(
      latitud: (json['latitud'] ?? 0.0).toDouble(),
      longitud: (json['longitud'] ?? 0.0).toDouble(),
      descripcion: json['descripcion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitud': latitud,
      'longitud': longitud,
      'descripcion': descripcion,
    };
  }
}

class EquipoTrabajo {
  final String lider;
  final List<String> miembros;

  EquipoTrabajo({
    required this.lider,
    required this.miembros,
  });

  factory EquipoTrabajo.fromJson(Map<String, dynamic> json) {
    return EquipoTrabajo(
      lider: json['lider'] ?? '',
      miembros: List<String>.from(json['miembros'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lider': lider,
      'miembros': miembros,
    };
  }
}

class DatosGenerales {
  final String periodoEstudio;
  final String habitat;
  final String vegetacion;
  final String altitud;

  DatosGenerales({
    required this.periodoEstudio,
    required this.habitat,
    required this.vegetacion,
    required this.altitud,
  });

  factory DatosGenerales.fromJson(Map<String, dynamic> json) {
    return DatosGenerales(
      periodoEstudio: json['periodoEstudio'] ?? '',
      habitat: json['habitat'] ?? '',
      vegetacion: json['vegetacion'] ?? '',
      altitud: json['altitud'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'periodoEstudio': periodoEstudio,
      'habitat': habitat,
      'vegetacion': vegetacion,
      'altitud': altitud,
    };
  }
}

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

double? _toNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String _coordinatesDescription(double? lat, double? lon) {
  if (lat == null || lon == null) {
    return 'Coordenadas no disponibles';
  }
  return 'Lat: ${lat.toStringAsFixed(4)}, Long: ${lon.toStringAsFixed(4)}';
}

String _buildLocationSummary(Map<String, dynamic>? locality) {
  if (locality == null || locality.isEmpty) {
    return 'Ubicación no disponible';
  }

  final parts = <String>[
    locality['city'] as String? ?? '',
    locality['state'] as String? ?? '',
    locality['country'] as String? ?? '',
  ].where((element) => element.trim().isNotEmpty).toList();

  if (parts.isEmpty) {
    return locality['name'] as String? ?? 'Ubicación no disponible';
  }

  return parts.join(', ');
}

String _formatDate(DateTime? date) {
  if (date == null) {
    return 'Sin fecha';
  }

  final twoDigits = (int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}';
}

String _formatPeriod(DateTime? start, DateTime? end) {
  if (start == null && end == null) {
    return 'Periodo no especificado';
  }

  final startText = start != null ? _formatDate(start) : 'Inicio no especificado';
  final endText = end != null ? _formatDate(end) : 'Fin no especificado';
  return '$startText - $endText';
}