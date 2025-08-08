import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sangrah/src/blocs/gallery_bloc.dart';
import 'package:sangrah/src/config/pagination_config.dart';
import 'package:sangrah/src/widgets/photo_grid_item.dart';

class GalleryGrid extends StatefulWidget {
  const GalleryGrid({super.key, required this.state});
  final GalleryLoaded state;

  @override
  State<GalleryGrid> createState() => _GalleryGridState();
}

class _GalleryGridState extends State<GalleryGrid> {
  final ScrollController _controller = ScrollController();
  bool _hasTriggeredPagination = false;

  @override
  void initState() {
    super.initState();
    _onScroll();
  }

  @override
  void didUpdateWidget(GalleryGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.isLoadingMore && !widget.state.isLoadingMore) {
      _hasTriggeredPagination = false;
    }
  }

  double _calculateThreshold() {
    final double viewportHeight = _controller.position.viewportDimension;
    
    if (viewportHeight <= 0) {
      return PaginationConfig.minThresholdPixels;
    }
    
    final double dynamicThreshold = viewportHeight * PaginationConfig.scrollThreshold;
    
    return dynamicThreshold.clamp(
      PaginationConfig.minThresholdPixels,
      PaginationConfig.maxThresholdPixels,
    );
  }

  _onScroll() {
    _controller.addListener(() {
      if (_hasTriggeredPagination) return;
      
      final double currentPosition = _controller.position.pixels;
      final double maxExtent = _controller.position.maxScrollExtent;
      
      if (maxExtent <= 0) return;
      
      final double threshold = _calculateThreshold();
      final double triggerPoint = maxExtent - threshold;
      
      if (currentPosition >= triggerPoint) {
        final bloc = context.read<GalleryBloc>();
        if (!widget.state.hasReachedMax && !widget.state.isLoadingMore) {
          _hasTriggeredPagination = true;
          bloc.add(LoadMorePhotos());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.photos.isEmpty) {
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

    return CustomScrollView(
      controller: _controller,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final AssetEntity photo = widget.state.photos[index];
                return PhotoGridItem(
                  photo: photo,
                  key: ValueKey(photo.id),
                );
              },
              childCount: widget.state.photos.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildBottomIndicator(),
        ),
      ],
    );
  }

  Widget _buildBottomIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16.0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _getIndicatorContent(),
      ),
    );
  }

  Widget _getIndicatorContent() {
    if (widget.state.isLoadingMore) {
      return const Row(
        key: ValueKey('loading'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(
            'Loading more photos...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }
    
    if (widget.state.hasReachedMax && widget.state.photos.isNotEmpty) {
      return const Row(
        key: ValueKey('completed'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.grey, size: 20),
          SizedBox(width: 8),
          Text(
            'All photos loaded',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }
    
    return const SizedBox(
      key: ValueKey('empty'),
      height: 0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
