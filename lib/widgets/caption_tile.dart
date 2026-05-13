import 'package:flutter/material.dart';

import '../models/caption.dart';

class CaptionTile extends StatelessWidget {
  final Caption caption;
  final Color speakerColor;

  const CaptionTile({
    super.key,
    required this.caption,
    required this.speakerColor,
  });

  @override
  Widget build(BuildContext context) {
    final time =
        '${caption.receivedAt.hour.toString().padLeft(2, '0')}:${caption.receivedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAB9).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: speakerColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            caption.speaker,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: speakerColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption.text,
            style: const TextStyle(
              color: Color(0xFF3C3C3C),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(color: Color(0xFFC67C4E), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
