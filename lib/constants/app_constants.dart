class AppConstants {
  // Dimensiones generales
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingExtraLarge = 32.0;
  
  // Márgenes
  static const double marginSmall = 8.0;
  static const double marginMedium = 16.0;
  static const double marginLarge = 24.0;
  
  // Bordes redondeados
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusExtraLarge = 16.0;
  
  // Elevaciones
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  
  // Tamaños de botones
  static const double buttonHeight = 48.0;
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightLarge = 56.0;
  
  // Tamaños de iconos
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  
  // Tamaños específicos de la app
  static const double appBarHeight = 56.0;
  static const double cardMinHeight = 120.0;
  static const double mapContainerHeight = 200.0;
  static const double speciesImageSize = 60.0;
  static const double statsCardSize = 80.0;
  
  // Duraciones de animación
  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);
  
  // Textos de la aplicación
  static const String appName = 'Investigaciones de Biodiversidad';
  static const String homeTitle = 'Lista De Investigaciones';
  static const String noDataMessage = 'No hay información disponible';
  static const String loadingMessage = 'Cargando...';
  static const String errorMessage = 'Ha ocurrido un error';
  
  // Estados
  static const String estadoEjecucion = 'Ejecución';
  static const String estadoCompletado = 'Completado';
  static const String estadoPendiente = 'Pendiente';
  
  // Botones
  static const String verMasDetalles = 'Ver más detalles';
  static const String verPuntosMuestreo = 'Ver puntos de muestreo';
  static const String verEspeciesObservadas = 'Ver especies observadas';
  static const String verDetallesCompletos = 'Ver detalles completos';
  static const String puntosMuestreo = 'Puntos de muestreo';
  static const String especies = 'Especies';
  
  // Validaciones
  static const int maxTituloLength = 100;
  static const int maxDescripcionLength = 500;
  static const int minBusquedaLength = 3;
  
  // Configuración API (para futuro uso)
  static const String baseUrl = 'https://api.biodiversidad.com';
  static const int timeoutSeconds = 30;
  static const String apiVersion = 'v1';
}