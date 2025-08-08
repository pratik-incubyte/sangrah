import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoFullScreen extends StatelessWidget {
  final AssetEntity photo;

  const PhotoFullScreen({super.key, required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          photo.title ?? 'Photo',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: FutureBuilder<Widget?>(
          future: _buildFullImage(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              return InteractiveViewer(child: snapshot.data!);
            }
            return const CircularProgressIndicator(color: Colors.white);
          },
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Size: ${photo.width} x ${photo.height}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Type: ${photo.type.name}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Date: ${photo.createDateTime}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Future<Widget?> _buildFullImage() async {
    try {
      final file = await photo.file;
      if (file != null) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.white, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Error loading image',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Error loading full image: $e');
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.white, size: 64),
          SizedBox(height: 16),
          Text('Error loading image', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
