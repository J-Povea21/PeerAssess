class AppConfig {
  static const String robleBaseUrl =
      'https://roble-api.openlab.uninorte.edu.co';

  /// Passed at build/run time via --dart-define=ROBLE_TOKEN=<value>
  static const String robleToken = String.fromEnvironment('ROBLE_TOKEN');
}
