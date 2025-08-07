import 'dart:typed_data';

import 'package:flutter/material.dart';

class ThumbnailWidget extends StatelessWidget {
  const ThumbnailWidget({super.key, required this.photo});

  final Uint8List? photo;

  @override
  Widget build(BuildContext context) {
    try {
      if (photo != null) {
        return Image.memory(
          photo!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        );
      }
    } catch (e) {
      print('Error loading thumbnail: $e');
    }

    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}
