class Especie {
  final String id;
  final String nombre;
  final int individuos;
  final InformacionBasica informacionBasica;
  final ComposicionPoblacional composicionPoblacional;
  final MorfologiaDetallada morfologiaDetallada;
  final String? observaciones;

  Especie({
    required this.id,
    required this.nombre,
    required this.individuos,
    required this.informacionBasica,
    required this.composicionPoblacional,
    required this.morfologiaDetallada,
    this.observaciones,
  });

  factory Especie.fromJson(Map<String, dynamic> json) {
    return Especie(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      individuos: json['individuos'] ?? 0,
      informacionBasica: InformacionBasica.fromJson(json['informacionBasica'] ?? {}),
      composicionPoblacional: ComposicionPoblacional.fromJson(json['composicionPoblacional'] ?? {}),
      morfologiaDetallada: MorfologiaDetallada.fromJson(json['morfologiaDetallada'] ?? {}),
      observaciones: json['observaciones'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'individuos': individuos,
      'informacionBasica': informacionBasica.toJson(),
      'composicionPoblacional': composicionPoblacional.toJson(),
      'morfologiaDetallada': morfologiaDetallada.toJson(),
      'observaciones': observaciones,
    };
  }
}

class InformacionBasica {
  final String metodoDeteccion;
  final String distancia;
  final String actividad;
  final String sustrato;
  final String estrato;

  InformacionBasica({
    required this.metodoDeteccion,
    required this.distancia,
    required this.actividad,
    required this.sustrato,
    required this.estrato,
  });

  factory InformacionBasica.fromJson(Map<String, dynamic> json) {
    return InformacionBasica(
      metodoDeteccion: json['metodoDeteccion'] ?? '',
      distancia: json['distancia'] ?? '',
      actividad: json['actividad'] ?? '',
      sustrato: json['sustrato'] ?? '',
      estrato: json['estrato'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metodoDeteccion': metodoDeteccion,
      'distancia': distancia,
      'actividad': actividad,
      'sustrato': sustrato,
      'estrato': estrato,
    };
  }
}

class ComposicionPoblacional {
  final int abundancia;
  final int machos;
  final int hembras;
  final int indeterminados;
  final int adultos;
  final int juveniles;

  ComposicionPoblacional({
    required this.abundancia,
    required this.machos,
    required this.hembras,
    required this.indeterminados,
    required this.adultos,
    required this.juveniles,
  });

  factory ComposicionPoblacional.fromJson(Map<String, dynamic> json) {
    return ComposicionPoblacional(
      abundancia: json['abundancia'] ?? 0,
      machos: json['machos'] ?? 0,
      hembras: json['hembras'] ?? 0,
      indeterminados: json['indeterminados'] ?? 0,
      adultos: json['adultos'] ?? 0,
      juveniles: json['juveniles'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'abundancia': abundancia,
      'machos': machos,
      'hembras': hembras,
      'indeterminados': indeterminados,
      'adultos': adultos,
      'juveniles': juveniles,
    };
  }
}

class MorfologiaDetallada {
  final Pico pico;
  final Alas alas;
  final Patas patas;
  final Cola cola;
  final double? masaCorporal;

  MorfologiaDetallada({
    required this.pico,
    required this.alas,
    required this.patas,
    required this.cola,
    this.masaCorporal,
  });

  factory MorfologiaDetallada.fromJson(Map<String, dynamic> json) {
    return MorfologiaDetallada(
      pico: Pico.fromJson(json['pico'] ?? {}),
      alas: Alas.fromJson(json['alas'] ?? {}),
      patas: Patas.fromJson(json['patas'] ?? {}),
      cola: Cola.fromJson(json['cola'] ?? {}),
      masaCorporal: json['masaCorporal']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pico': pico.toJson(),
      'alas': alas.toJson(),
      'patas': patas.toJson(),
      'cola': cola.toJson(),
      'masaCorporal': masaCorporal,
    };
  }
}

class Pico {
  final String? altura;
  final String? ancho;
  final String? anchoNarinas;
  final String? anchoComisura;
  final String? curvatura;
  final double? culmenTotal;
  final double? culmenExpuesto;

  Pico({
    this.altura,
    this.ancho,
    this.anchoNarinas,
    this.anchoComisura,
    this.curvatura,
    this.culmenTotal,
    this.culmenExpuesto,
  });

  factory Pico.fromJson(Map<String, dynamic> json) {
    return Pico(
      altura: json['altura'],
      ancho: json['ancho'],
      anchoNarinas: json['anchoNarinas'],
      anchoComisura: json['anchoComisura'],
      curvatura: json['curvatura'],
      culmenTotal: json['culmenTotal']?.toDouble(),
      culmenExpuesto: json['culmenExpuesto']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'altura': altura,
      'ancho': ancho,
      'anchoNarinas': anchoNarinas,
      'anchoComisura': anchoComisura,
      'curvatura': curvatura,
      'culmenTotal': culmenTotal,
      'culmenExpuesto': culmenExpuesto,
    };
  }
}

class Alas {
  final String? altura;
  final double? cuerda;
  final String? distanciaPrimariaSecundaria;
  final double? envergadura;

  Alas({
    this.altura,
    this.cuerda,
    this.distanciaPrimariaSecundaria,
    this.envergadura,
  });

  factory Alas.fromJson(Map<String, dynamic> json) {
    return Alas(
      altura: json['altura'],
      cuerda: json['cuerda']?.toDouble(),
      distanciaPrimariaSecundaria: json['distanciaPrimariaSecundaria'],
      envergadura: json['envergadura']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'altura': altura,
      'cuerda': cuerda,
      'distanciaPrimariaSecundaria': distanciaPrimariaSecundaria,
      'envergadura': envergadura,
    };
  }
}

class Patas {
  final double? garraHallux;
  final String? longitudHallux;
  final double? longitudTarso;

  Patas({
    this.garraHallux,
    this.longitudHallux,
    this.longitudTarso,
  });

  factory Patas.fromJson(Map<String, dynamic> json) {
    return Patas(
      garraHallux: json['garraHallux']?.toDouble(),
      longitudHallux: json['longitudHallux'],
      longitudTarso: json['longitudTarso']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'garraHallux': garraHallux,
      'longitudHallux': longitudHallux,
      'longitudTarso': longitudTarso,
    };
  }
}

class Cola {
  final double? longitud;
  final String? graduacion;

  Cola({
    this.longitud,
    this.graduacion,
  });

  factory Cola.fromJson(Map<String, dynamic> json) {
    return Cola(
      longitud: json['longitud']?.toDouble(),
      graduacion: json['graduacion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'longitud': longitud,
      'graduacion': graduacion,
    };
  }
}