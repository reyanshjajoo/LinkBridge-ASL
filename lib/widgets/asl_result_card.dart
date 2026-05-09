import 'package:flutter/material.dart';
import '../services/asl_service.dart';

class AslResultCard extends StatelessWidget {
  final AslResult result;

  const AslResultCard({Key? key, required this.result}) : super(key: key);

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.80) return Colors.green;
    if (confidence > 0.60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              result.bestLabel.toUpperCase(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(result.bestConfidence * 100).toStringAsFixed(0)}% confident',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getConfidenceColor(result.bestConfidence),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            ...result.topPredictions.skip(1).map((prediction) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      prediction.label,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${(prediction.confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
