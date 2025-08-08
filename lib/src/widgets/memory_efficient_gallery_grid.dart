import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sangrah/src/blocs/gallery_bloc.dart';
import 'package:sangrah/src/config/pagination_config.dart';
import 'package:sangrah/src/widgets/photo_grid_item.dart';

class MemoryEfficientGalleryGrid extends StatefulWidget {
  const MemoryEfficientGalleryGrid({
    super.key, 
    required this.state,
  });
  
  final GalleryLoaded state;

  @override
  State<MemoryEfficientGalleryGrid> createState() => _MemoryEfficientGalleryGridState();
}

class _MemoryEfficientGalleryGridState extends State<MemoryEfficientGalleryGrid> {
  final ScrollController _controller = ScrollController();
  bool _hasTriggeredPagination = false;
  Timer? _scrollTimer;
  Timer? _garbageCollectionTimer;
  
  // Viewport optimization
  int _firstVisibleIndex = 0;
  int _lastVisibleIndex = 0;
  
  // Performance tracking
  int _lastWindowUpdateIndex = -1;
  static const int _windowUpdateThreshold = 10; // Update window every 10 items scrolled

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
    _setupGarbageCollectionTimer();
  }

  @override
  void didUpdateWidget(MemoryEfficientGalleryGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.isLoadingMore && !widget.state.isLoadingMore) {
      _hasTriggeredPagination = false;
    }
  }

  void _setupScrollListener() {
    _controller.addListener(() {
      _onScroll();
      _updateViewportWindow();
      _checkPaginationTrigger();
    });
  }

  void _setupGarbageCollectionTimer() {
    // Perform garbage collection every 2 minutes
    _garbageCollectionTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _performGarbageCollection(),
    );
  }

  void _onScroll() {
    // Debounce scroll events to reduce unnecessary updates
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        _updateViewportIndices();
      }
    });
  }

  void _updateViewportIndices() {
    if (!_controller.hasClients || widget.state.totalItems == 0) return;

    final double scrollPosition = _controller.position.pixels;
    final double viewportHeight = _controller.position.viewportDimension;
    
    // Calculate approximate grid item height (3 columns + spacing)
    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = (screenWidth - (8 * 2) - (4 * 2)) / 3; // padding + spacing / 3 columns
    final double itemHeight = itemWidth; // Square items
    final double rowHeight = itemHeight + 4; // Add spacing
    
    // Calculate visible range with buffer
    final int itemsPerRow = 3;
    final int startRow = ((scrollPosition - 200) / rowHeight).floor().clamp(0, double.infinity).toInt();
    final int endRow = ((scrollPosition + viewportHeight + 200) / rowHeight).ceil();
    
    _firstVisibleIndex = (startRow * itemsPerRow).clamp(0, widget.state.totalItems);
    _lastVisibleIndex = (endRow * itemsPerRow).clamp(_firstVisibleIndex, widget.state.totalItems);
  }

  void _updateViewportWindow() {
    if (widget.state.totalItems == 0) return;
    
    final int centerIndex = (_firstVisibleIndex + _lastVisibleIndex) ~/ 2;
    
    // Only update window if we've scrolled significantly
    if ((centerIndex - _lastWindowUpdateIndex).abs() >= _windowUpdateThreshold) {
      context.read<GalleryBloc>().add(UpdateViewportWindow(centerIndex));
      _lastWindowUpdateIndex = centerIndex;
    }
  }

  void _checkPaginationTrigger() {
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

  void _performGarbageCollection() {
    if (mounted) {
      context.read<GalleryBloc>().add(PerformGarbageCollection());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.isEmpty) {
      return _buildEmptyState();
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
              (context, index) => _buildGridItem(index),
              childCount: widget.state.totalItems,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildBottomIndicator(),
        ),
      ],
    );
  }

  Widget _buildGridItem(int index) {
    final photoItem = widget.state.getPhotoAt(index);
    
    if (photoItem == null) {
      // Return placeholder for null items
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.grey),
        ),
      );
    }

    // Check if item is in viewport for optimization
    final bool isInViewport = index >= _firstVisibleIndex && index <= _lastVisibleIndex;
    
    if (!isInViewport && index > _lastVisibleIndex + 20) {
      // For items far from viewport, show minimal placeholder
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return PhotoGridItem(
      key: ValueKey(photoItem.id),
      photoItem: photoItem,
    );
  }

  Widget _buildEmptyState() {
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
    
    if (widget.state.hasReachedMax && widget.state.isNotEmpty) {
      return Row(
        key: const ValueKey('completed'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Text(
            'All ${widget.state.totalItems} photos loaded',
            style: const TextStyle(color: Colors.grey),
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
    _scrollTimer?.cancel();
    _garbageCollectionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
