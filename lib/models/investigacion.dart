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