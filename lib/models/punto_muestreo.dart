class PuntoMuestreo {
  final String id;
  final String nombre;
  final Ubicacion ubicacion;
  final MetodologiaMuestreo metodologia;
  final ParametrosCenso parametrosCenso;
  final DuracionMuestreo duracionMuestreo;
  final List<Muestra> muestras;

  PuntoMuestreo({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    required this.metodologia,
    required this.parametrosCenso,
    required this.duracionMuestreo,
    required this.muestras,
  });

  factory PuntoMuestreo.fromJson(Map<String, dynamic> json) {
    return PuntoMuestreo(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      ubicacion: Ubicacion.fromJson(json['ubicacion'] ?? {}),
      metodologia: MetodologiaMuestreo.fromJson(json['metodologia'] ?? {}),
      parametrosCenso: ParametrosCenso.fromJson(json['parametrosCenso'] ?? {}),
      duracionMuestreo: DuracionMuestreo.fromJson(json['duracionMuestreo'] ?? {}),
      muestras: (json['muestras'] as List<dynamic>?)
              ?.map((e) => Muestra.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'ubicacion': ubicacion.toJson(),
      'metodologia': metodologia.toJson(),
      'parametrosCenso': parametrosCenso.toJson(),
      'duracionMuestreo': duracionMuestreo.toJson(),
      'muestras': muestras.map((e) => e.toJson()).toList(),
    };
  }
}

class Ubicacion {
  final double altitud;
  final double longitud;

  Ubicacion({
    required this.altitud,
    required this.longitud,
  });

  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    return Ubicacion(
      altitud: (json['altitud'] ?? 0.0).toDouble(),
      longitud: (json['longitud'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'altitud': altitud,
      'longitud': longitud,
    };
  }
}

class MetodologiaMuestreo {
  final String tipoMuestreo;
  final String detalleMuestreo;
  final String metodoDeteccion;

  MetodologiaMuestreo({
    required this.tipoMuestreo,
    required this.detalleMuestreo,
    required this.metodoDeteccion,
  });

  factory MetodologiaMuestreo.fromJson(Map<String, dynamic> json) {
    return MetodologiaMuestreo(
      tipoMuestreo: json['tipoMuestreo'] ?? '',
      detalleMuestreo: json['detalleMuestreo'] ?? '',
      metodoDeteccion: json['metodoDeteccion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipoMuestreo': tipoMuestreo,
      'detalleMuestreo': detalleMuestreo,
      'metodoDeteccion': metodoDeteccion,
    };
  }
}

class ParametrosCenso {
  final int periodoCenso;
  final int radioFijo;

  ParametrosCenso({
    required this.periodoCenso,
    required this.radioFijo,
  });

  factory ParametrosCenso.fromJson(Map<String, dynamic> json) {
    return ParametrosCenso(
      periodoCenso: json['periodoCenso'] ?? 0,
      radioFijo: json['radioFijo'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'periodoCenso': periodoCenso,
      'radioFijo': radioFijo,
    };
  }
}

class DuracionMuestreo {
  final DateTime fechaInicio;
  final DateTime fechaFinalizacion;

  DuracionMuestreo({
    required this.fechaInicio,
    required this.fechaFinalizacion,
  });

  factory DuracionMuestreo.fromJson(Map<String, dynamic> json) {
    return DuracionMuestreo(
      fechaInicio: DateTime.tryParse(json['fechaInicio'] ?? '') ?? DateTime.now(),
      fechaFinalizacion: DateTime.tryParse(json['fechaFinalizacion'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFinalizacion': fechaFinalizacion.toIso8601String(),
    };
  }
}

class Muestra {
  final String id;
  final String nombre;
  final double temperatura;
  final int humedad;
  final CondicionesAmbientales condiciones;

  Muestra({
    required this.id,
    required this.nombre,
    required this.temperatura,
    required this.humedad,
    required this.condiciones,
  });

  factory Muestra.fromJson(Map<String, dynamic> json) {
    return Muestra(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      temperatura: (json['temperatura'] ?? 0.0).toDouble(),
      humedad: json['humedad'] ?? 0,
      condiciones: CondicionesAmbientales.fromJson(json['condiciones'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'temperatura': temperatura,
      'humedad': humedad,
      'condiciones': condiciones.toJson(),
    };
  }
}

class CondicionesAmbientales {
  final String precipitacion;
  final String nubosidad;
  final String luminosidad;
  final String condiciones;

  CondicionesAmbientales({
    required this.precipitacion,
    required this.nubosidad,
    required this.luminosidad,
    required this.condiciones,
  });

  factory CondicionesAmbientales.fromJson(Map<String, dynamic> json) {
    return CondicionesAmbientales(
      precipitacion: json['precipitacion'] ?? '',
      nubosidad: json['nubosidad'] ?? '',
      luminosidad: json['luminosidad'] ?? '',
      condiciones: json['condiciones'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'precipitacion': precipitacion,
      'nubosidad': nubosidad,
      'luminosidad': luminosidad,
      'condiciones': condiciones,
    };
  }
}