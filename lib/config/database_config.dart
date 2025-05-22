// Configuration de la base de données
class DatabaseConfig {
  // Ces valeurs doivent être définies via des variables d'environnement
  static const String host = String.fromEnvironment('DB_HOST', defaultValue: '172.16.199.254');
  static const int port = int.fromEnvironment('DB_PORT', defaultValue: 3306);
  static const String user = String.fromEnvironment('DB_USER', defaultValue: '');
  static const String password = String.fromEnvironment('DB_PASSWORD', defaultValue: '');
  static const String database = String.fromEnvironment('DB_NAME', defaultValue: 'vroom_prestige');
} 