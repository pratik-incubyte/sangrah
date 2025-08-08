import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sangrah/src/widgets/memory_efficient_gallery_grid.dart';
import 'package:sangrah/src/widgets/memory_debug_panel.dart';
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
            body: BlocConsumer<GalleryBloc, GalleryState>(
              listener: (context, state) {      
              },
              builder: (context, state) {
                return switch (state) {
                  GalleryInitial() => _buildLoadingState(),
                  GalleryLoading() => _buildLoadingState(),
                  GalleryLoaded() => MemoryEfficientGalleryGrid(state: state),
                  GalleryError() => _buildErrorState(context, state),
                };
              },
            ),
            floatingActionButton: const MemoryDebugFab(),
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
