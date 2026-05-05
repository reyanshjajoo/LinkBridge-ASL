class AppConfig {
  // For physical Android device via USB: run `adb reverse tcp:5001 tcp:5001` in terminal, then use 'http://127.0.0.1:5001'
  // For same Wi-Fi: use your PC's local IP 'http://192.168.X.X:5001' (and run flask with --host=0.0.0.0)
  // For ngrok (judges): 'https://<your-ngrok-url>.ngrok.io'
  static const String baseUrl = 'http://127.0.0.1:5001'; 
}
