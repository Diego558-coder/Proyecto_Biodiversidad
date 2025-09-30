class ApiConfig {
  static const String baseUrl = 'https://api-bird-field-logs.coderhub.run/api/external';
  
  // Endpoints
  static const String researchEndpoint = '/research';
  static const String researchDetailsEndpoint = '/details/research'; // /:uuid se agrega dinámicamente
  
  // API Key (en producción esto debería venir de variables de entorno)
  static const String apiKey = 'YOUR_API_KEY_HERE'; // Reemplaza con tu API key real
  
  // Headers por defecto
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey', // o el formato que use tu API
    // Si usa otro formato de autenticación, ajustar aquí
    // 'X-API-Key': apiKey, // Por ejemplo, si usa este formato
  };
  
  // URLs completas
  static String get researchUrl => '$baseUrl$researchEndpoint';
  static String researchDetailsUrl(String uuid) => '$baseUrl$researchDetailsEndpoint/$uuid';
}