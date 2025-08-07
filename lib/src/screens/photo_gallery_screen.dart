import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
// import 'package:permission_handler/permission_handler.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({Key? key}) : super(key: key);

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  List<AssetEntity> _photos = [];
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoadPhotos();
  }

  Future<void> _requestPermissionAndLoadPhotos() async {
    // Request storage permission
    final PermissionState permission =
        await PhotoManager.requestPermissionExtend();

    if (permission.isAuth) {
      setState(() {
        _hasPermission = true;
      });
      await _loadPhotos();
    } else {
      setState(() {
        _isLoading = false;
        _hasPermission = false;
      });

      // Show permission dialog
      _showPermissionDialog();
    }
  }

  Future<void> _loadPhotos() async {
    try {
      // Get all photo albums
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      if (paths.isNotEmpty) {
        // Get photos from the first album (Camera Roll)
        final List<AssetEntity> photos = await paths.first.getAssetListPaged(
          page: 0,
          size: 100, // Load first 100 photos
        );

        setState(() {
          _photos = photos;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading photos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'This app needs access to your photos to display them. Please grant permission in settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No permission to access photos',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _requestPermissionAndLoadPhotos,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    if (_photos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No photos found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final AssetEntity photo = _photos[index];
        return GestureDetector(
          onTap: () => _viewPhoto(photo),
          child: FutureBuilder<Widget?>(
            future: _buildThumbnail(photo),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: snapshot.data!,
                );
              }
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          ),
        );
      },
    );
  }

  Future<Widget?> _buildThumbnail(AssetEntity photo) async {
    try {
      final thumbnailData = await photo.thumbnailDataWithSize(
        const ThumbnailSize(200, 200),
      );

      if (thumbnailData != null) {
        return Image.memory(thumbnailData, fit: BoxFit.cover);
      }
    } catch (e) {
      print('Error loading thumbnail: $e');
    }

    return Container(color: Colors.grey[300], child: const Icon(Icons.error));
  }

  void _viewPhoto(AssetEntity photo) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PhotoViewScreen(photo: photo)),
    );
  }
}

class PhotoViewScreen extends StatelessWidget {
  final AssetEntity photo;

  const PhotoViewScreen({Key? key, required this.photo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: FutureBuilder<Widget?>(
          future: _buildFullImage(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              return snapshot.data!;
            }
            return const CircularProgressIndicator(color: Colors.white);
          },
        ),
      ),
    );
  }

  Future<Widget?> _buildFullImage() async {
    try {
      final file = await photo.file;
      if (file != null) {
        return Image.file(file, fit: BoxFit.contain);
      }
    } catch (e) {
      print('Error loading full image: $e');
    }

    return const Center(
      child: Text('Error loading image', style: TextStyle(color: Colors.white)),
    );
  }
}
