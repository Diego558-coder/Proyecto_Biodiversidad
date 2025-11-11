import 'dart:async';

import 'package:investigaciones_biodiversidad/services/investigacion_service.dart';

Future<void> main() async {
  final investigaciones = await InvestigacionService.obtenerInvestigaciones();
  for (final investigacion in investigaciones) {
    print('Investigacion: ${investigacion.titulo} (${investigacion.id})');
    final detalle = await InvestigacionService.obtenerInvestigacionPorId(investigacion.id);
    if (detalle == null) {
      print('  Detalle no disponible');
      continue;
    }
    print('  Puntos de muestreo: ${detalle.puntosMuestreo.length}');
  }
}
