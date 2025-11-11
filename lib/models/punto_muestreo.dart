class PuntoMuestreo {
  final String id;
  final int numero;
  final CoordenadasPunto coordenadas;
  final String tipoMuestreo;
  final String? detalleTipoMuestreo;
  final String deteccion;
  final String? figura;
  final int? periodoCenso;
  final int? radioFijo;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final List<Muestra> muestras;

  const PuntoMuestreo({
    required this.id,
    required this.numero,
    required this.coordenadas,
    required this.tipoMuestreo,
    required this.detalleTipoMuestreo,
    required this.deteccion,
    required this.figura,
    required this.periodoCenso,
    required this.radioFijo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.muestras,
  });

  factory PuntoMuestreo.fromApi(Map<String, dynamic> json) {
    return PuntoMuestreo(
      id: _stringValue(json['uuid']) ?? _stringValue(json['_id']) ?? '',
      numero: _intValue(json['pointNumber']) ?? 0,
  coordenadas: CoordenadasPunto.fromApi(json['coordinates']),
      tipoMuestreo: (json['samplingType'] as String?) ?? 'No especificado',
      detalleTipoMuestreo: json['detailSamplingType'] as String?,
      deteccion: (json['detection'] as String?) ?? 'No especificado',
      figura: json['figure'] as String?,
      periodoCenso: _intValue(json['censusPeriod']),
      radioFijo: _intValue(json['fixedRadius']),
      fechaInicio: _parseDate(json['startDate'] as String?),
      fechaFin: _parseDate(json['endDate'] as String?),
      muestras: (json['samples'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(Muestra.fromApi)
              .toList() ??
          const <Muestra>[],
    );
  }

  bool get tieneCoordenadas => coordenadas.latitud != null && coordenadas.longitud != null;
}

class CoordenadasPunto {
  final double? latitud;
  final double? longitud;

  const CoordenadasPunto({this.latitud, this.longitud});

  factory CoordenadasPunto.fromApi(dynamic json) {
    if (json == null) {
      return const CoordenadasPunto();
    }
    if (json is Map<String, dynamic>) {
      return CoordenadasPunto(
        latitud: _doubleValue(json['latitude']),
        longitud: _doubleValue(json['longitude']),
      );
    }
    if (json is String) {
      final parsed = _parseCoordinateString(json);
      if (parsed != null) {
        return CoordenadasPunto(
          latitud: parsed['latitude'],
          longitud: parsed['longitude'],
        );
      }
    }
    return const CoordenadasPunto();
  }
}

class Muestra {
  final String id;
  final DateTime? fecha;
  final double? temperatura;
  final double? humedadRelativa;
  final String? estadoPrecipitacion;
  final double? coberturaNubosa;
  final String? luminosidad;
  final String? condicionesGenerales;
  final String? recolectadoPor;
  final List<ObservacionEspecie> especiesObservadas;

  const Muestra({
    required this.id,
    required this.fecha,
    required this.temperatura,
    required this.humedadRelativa,
    required this.estadoPrecipitacion,
    required this.coberturaNubosa,
    required this.luminosidad,
    required this.condicionesGenerales,
    required this.recolectadoPor,
    required this.especiesObservadas,
  });

  factory Muestra.fromApi(Map<String, dynamic> json) {
    return Muestra(
      id: _stringValue(json['uuid']) ?? _stringValue(json['_id']) ?? '',
      fecha: _parseDate(json['date'] as String?),
      temperatura: _doubleValue(json['temperature']),
      humedadRelativa: _doubleValue(json['relativeHumidity']),
      estadoPrecipitacion: json['precipitationState'] as String?,
      coberturaNubosa: _doubleValue(json['cloudCoverage']),
      luminosidad: json['luminosity'] as String?,
      condicionesGenerales: json['overallConditions'] as String?,
      recolectadoPor: (json['collectedBy'] as Map<String, dynamic>?)?['uuid'] as String?,
      especiesObservadas: (json['observedSpecies'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ObservacionEspecie.fromApi)
              .toList() ??
          const <ObservacionEspecie>[],
    );
  }
}

class ObservacionEspecie {
  final String id;
  final String nombre;
  final int abundancia;
  final String deteccion;
  final double? distancia;
  final int? machos;
  final int? hembras;
  final int? indeterminados;
  final int? adultos;
  final int? juveniles;
  final String? actividad;
  final String? sustrato;
  final String? estrato;
  final String? observacion;
  final Map<String, dynamic> morfologia;
  final List<String> imagenes;

  const ObservacionEspecie({
    required this.id,
    required this.nombre,
    required this.abundancia,
    required this.deteccion,
    required this.distancia,
    required this.machos,
    required this.hembras,
    required this.indeterminados,
    required this.adultos,
    required this.juveniles,
    required this.actividad,
    required this.sustrato,
    required this.estrato,
    required this.observacion,
    required this.morfologia,
    required this.imagenes,
  });

  factory ObservacionEspecie.fromApi(Map<String, dynamic> json) {
    return ObservacionEspecie(
      id: _stringValue(json['uuid']) ?? _stringValue(json['_id']) ?? '',
      nombre: (json['species'] as String?) ?? 'Especie sin nombre',
      abundancia: _intValue(json['abundance']) ?? 0,
      deteccion: (json['detection'] as String?) ?? 'No especificado',
      distancia: _doubleValue(json['distance']),
      machos: _intValue(json['males']),
      hembras: _intValue(json['females']),
      indeterminados: _intValue(json['UndeterminedSexCount']),
      adultos: _intValue(json['numberAdults']),
      juveniles: _intValue(json['JuvenileCount']),
      actividad: json['activity'] as String?,
      sustrato: json['substrate'] as String?,
      estrato: json['stratum'] as String?,
      observacion: json['observation'] as String?,
      morfologia: (json['morphology'] as Map<String, dynamic>?) ?? const {},
      imagenes: (json['images'] as List?)
              ?.whereType<String>()
              .toList() ??
          const <String>[],
    );
  }
}

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

int? _intValue(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value.toString());
}

double? _doubleValue(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}

String? _stringValue(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

Map<String, double>? _parseCoordinateString(String value) {
  final latMatch = RegExp(r'latitude=([\-0-9\.]+)').firstMatch(value);
  final lonMatch = RegExp(r'longitude=([\-0-9\.]+)').firstMatch(value);
  if (latMatch == null || lonMatch == null) {
    return null;
  }
  final lat = double.tryParse(latMatch.group(1) ?? '');
  final lon = double.tryParse(lonMatch.group(1) ?? '');
  if (lat == null || lon == null) {
    return null;
  }
  return {
    'latitude': lat,
    'longitude': lon,
  };
}