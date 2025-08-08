import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/photo_item.dart';

class ThumbnailWidget extends StatefulWidget {
  const ThumbnailWidget({
    super.key,
    required this.photoItem,
    this.size = const ThumbnailSize(200, 200),
    this.placeholder,
  });

  final PhotoItem photoItem;
  final ThumbnailSize size;
  final Widget? placeholder;

  @override
  State<ThumbnailWidget> createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<ThumbnailWidget> 
    with AutomaticKeepAliveClientMixin {
  
  bool _isLoading = false;
  bool _hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Start loading thumbnail if not already cached
    if (!widget.photoItem.hasCachedThumbnail && !widget.photoItem.isLoadingThumbnail) {
      _loadThumbnail();
    }
  }

  @override
  void didUpdateWidget(ThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If photo item changed, reload thumbnail
    if (oldWidget.photoItem.id != widget.photoItem.id) {
      _hasError = false;
      if (!widget.photoItem.hasCachedThumbnail && !widget.photoItem.isLoadingThumbnail) {
        _loadThumbnail();
      }
    }
  }

  Future<void> _loadThumbnail() async {
    if (!mounted || widget.photoItem.isDisposed) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await widget.photoItem.getThumbnail(size: widget.size);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Check if photo item is disposed
    if (widget.photoItem.isDisposed) {
      return _buildErrorPlaceholder();
    }
    
    // Show cached thumbnail if available
    if (widget.photoItem.hasCachedThumbnail) {
      return FutureBuilder<Uint8List?>(
        future: widget.photoItem.getThumbnail(size: widget.size),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
            );
          }
          return _buildLoadingPlaceholder();
        },
      );
    }
    
    // Show error state
    if (_hasError) {
      return _buildErrorPlaceholder();
    }
    
    // Show loading state
    if (_isLoading || widget.photoItem.isLoadingThumbnail) {
      return _buildLoadingPlaceholder();
    }
    
    // Default: try to load thumbnail
    if (!widget.photoItem.isLoadingThumbnail) {
      _loadThumbnail();
    }
    
    return _buildLoadingPlaceholder();
  }

  Widget _buildLoadingPlaceholder() {
    return widget.placeholder ?? Container(
      color: Colors.grey[300],
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(
        Icons.broken_image,
        color: Colors.grey,
      ),
    );
  }

  @override
  void dispose() {
    // Note: We don't dispose the PhotoItem here as it's managed by the collection
    super.dispose();
  }
}
