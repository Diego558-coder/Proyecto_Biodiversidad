
class MockData {
  MockData._();

  static Never _unsupported() => throw UnsupportedError(
        'Se consume api',
      );

  static T _fail<T>() => _unsupported();

  static List<Map<String, dynamic>> get investigaciones => _fail();
  static List<Map<String, dynamic>> get especies => _fail();
  static List<Map<String, dynamic>> get puntosMuestreo => _fail();

  static List<dynamic> getInvestigaciones() => _fail();
  static Map<String, dynamic>? getInvestigacionPorId(String id) => _fail();
  static List<dynamic> getEspeciesPorInvestigacion(String id) => _fail();
  static Map<String, dynamic>? getEspeciePorId(String especieId, String investigacionId) => _fail();
  static List<dynamic> getPuntosPorInvestigacion(String investigacionId) => _fail();
  static Map<String, dynamic>? getPuntoPorId(String puntoId, String investigacionId) => _fail();
}