class AppConfig {
  static const String baseUrl = 'https://linkbridgetsa.org';

  /// Returns a websocket base URL derived from [baseUrl].
  static String wsBase() => baseUrl.replaceFirst(RegExp(r'^https?'), 'wss');

  /// Build an HTTP `Uri` for the given [path] (should begin with '/').
  static Uri httpUri(String path) => Uri.parse('$baseUrl$path');

  /// Build a WebSocket `Uri` for the given [path] (should begin with '/').
  static Uri wsUri(String path) => Uri.parse('${wsBase()}$path');
}
