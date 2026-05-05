import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class AslPrediction {
  final String label;
  final double confidence;
  final int index;

  AslPrediction({
    required this.label,
    required this.confidence,
    required this.index,
  });

  factory AslPrediction.fromJson(Map<String, dynamic> json) {
    return AslPrediction(
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      index: json['index'] as int,
    );
  }
}

class AslResult {
  final String text;
  final String bestLabel;
  final double bestConfidence;
  final List<AslPrediction> topPredictions;

  AslResult({
    required this.text,
    required this.bestLabel,
    required this.bestConfidence,
    required this.topPredictions,
  });

  factory AslResult.fromJson(Map<String, dynamic> json) {
    var topPredsList = json['top_predictions'] as List;
    List<AslPrediction> topPredictions =
        topPredsList.map((i) => AslPrediction.fromJson(i)).toList();

    return AslResult(
      text: json['text'] as String,
      bestLabel: json['best_prediction']['label'] as String,
      bestConfidence: (json['best_prediction']['confidence'] as num).toDouble(),
      topPredictions: topPredictions,
    );
  }
}

class AslService {
  final String baseUrl;
  static const Duration _networkTimeout = Duration(seconds: 20);

  AslService({this.baseUrl = AppConfig.baseUrl});

  Future<AslResult> transcribeVideo(File videoFile) async {
    final uri = Uri.parse('$baseUrl/asl/transcribe');
    final exists = await videoFile.exists();
    final bytes = exists ? await videoFile.length() : -1;

    _log('POST $uri');
    _log('Video path=${videoFile.path} exists=$exists bytes=$bytes');

    if (!exists) {
      throw Exception('ASL upload failed: video file not found at ${videoFile.path}');
    }

    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('video', videoFile.path));

    try {
      final startedAt = DateTime.now();
      final streamedResponse = await request.send().timeout(_networkTimeout);
      final response =
          await http.Response.fromStream(streamedResponse).timeout(_networkTimeout);
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;

      final previewBody = response.body.length > 300
          ? '${response.body.substring(0, 300)}...'
          : response.body;
      _log('Response status=${response.statusCode} in ${elapsedMs}ms body="$previewBody"');

      if (response.statusCode == 200) {
        return AslResult.fromJson(json.decode(response.body));
      }

      throw Exception(
        'ASL server error ${response.statusCode} at $uri. Body: ${response.body}',
      );
    } on SocketException catch (e) {
      _log('SocketException while calling $uri: $e');
      throw Exception(
        'Could not reach ASL server at $uri. Check baseUrl/network/adb reverse. Details: $e',
      );
    } on TimeoutException catch (e) {
      _log('Timeout while calling $uri: $e');
      throw Exception('ASL request timed out after ${_networkTimeout.inSeconds}s at $uri.');
    } on http.ClientException catch (e) {
      _log('ClientException while calling $uri: $e');
      throw Exception('HTTP client error while calling ASL server at $uri. Details: $e');
    } catch (e) {
      _log('Unexpected error while calling $uri: $e');
      rethrow;
    }
  }

  void _log(String message) {
    developer.log(message, name: 'ASL_SERVICE');
  }
}
