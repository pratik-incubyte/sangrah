import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sangrah/src/screens/photo_full_screen.dart';
import 'package:sangrah/src/widgets/thumbnail_widget.dart';
import '../blocs/gallery_bloc.dart';
import '../services/gallery_service.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          GalleryBloc(galleryService: GalleryServiceImpl())..add(LoadPhotos()),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Photo Manager'),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
            body: BlocBuilder<GalleryBloc, GalleryState>(
              builder: (context, state) {
                return switch (state) {
                  GalleryInitial() => _buildLoadingState(),
                  GalleryLoading() => _buildLoadingState(),
                  GalleryLoaded() => _buildPhotosGrid(context, state),
                  GalleryError() => _buildErrorState(context, state),
                };
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading photos...'),
        ],
      ),
    );
  }

  Widget _buildPhotosGrid(BuildContext context, GalleryLoaded state) {
    if (state.photos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No photos found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: state.photos.length,
            itemBuilder: (context, index) {
              final AssetEntity photo = state.photos[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PhotoFullScreen(photo: photo),
                    ),
                  );
                },
                child: FutureBuilder<Uint8List?>(
                  future: photo.thumbnailDataWithSize(
                    const ThumbnailSize(200, 200),
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ThumbnailWidget(photo: snapshot.data!),
                      );
                    }
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, GalleryError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading photos',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<GalleryBloc>().add(LoadPhotos());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
