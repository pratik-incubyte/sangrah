import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

/// Memory-efficient photo item that manages thumbnail lifecycle
class PhotoItem {
  final String id;
  final AssetEntity _asset;
  final DateTime dateAdded;
  
  // Cached thumbnail data with lifecycle management
  Uint8List? _thumbnailCache;
  DateTime? _lastAccessed;
  bool _isDisposed = false;
  
  // Thumbnail loading state
  bool _isLoadingThumbnail = false;
  
  PhotoItem({
    required this.id,
    required AssetEntity asset,
    DateTime? dateAdded,
  }) : _asset = asset, 
       dateAdded = dateAdded ?? DateTime.now();

  // Getters for asset properties
  AssetEntity get asset => _asset;
  int get width => _asset.width;
  int get height => _asset.height;
  AssetType get type => _asset.type;
  DateTime? get createDateTime => _asset.createDateTime;
  String? get title => _asset.title;
  
  // Memory management getters
  bool get hasCachedThumbnail => _thumbnailCache != null && !_isDisposed;
  bool get isLoadingThumbnail => _isLoadingThumbnail;
  DateTime? get lastAccessed => _lastAccessed;
  bool get isDisposed => _isDisposed;

  /// Load and cache thumbnail with size optimization
  Future<Uint8List?> getThumbnail({
    ThumbnailSize size = const ThumbnailSize(200, 200),
    bool forceReload = false,
  }) async {
    if (_isDisposed) return null;
    
    _lastAccessed = DateTime.now();
    
    // Return cached thumbnail if available and not forcing reload
    if (_thumbnailCache != null && !forceReload) {
      return _thumbnailCache;
    }
    
    // Prevent multiple simultaneous loads
    if (_isLoadingThumbnail) {
      // Wait for current loading to complete
      while (_isLoadingThumbnail && !_isDisposed) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _thumbnailCache;
    }
    
    try {
      _isLoadingThumbnail = true;
      final thumbnail = await _asset.thumbnailDataWithSize(size);
      
      if (!_isDisposed && thumbnail != null) {
        _thumbnailCache = thumbnail;
        _lastAccessed = DateTime.now();
      }
      
      return thumbnail;
    } catch (e) {
      // Handle errors gracefully
      return null;
    } finally {
      _isLoadingThumbnail = false;
    }
  }

  /// Preload thumbnail for better user experience
  Future<void> preloadThumbnail({
    ThumbnailSize size = const ThumbnailSize(200, 200),
  }) async {
    if (_thumbnailCache == null && !_isLoadingThumbnail) {
      await getThumbnail(size: size);
    }
  }

  /// Clear cached thumbnail to free memory
  void clearThumbnailCache() {
    if (!_isDisposed) {
      _thumbnailCache = null;
      _lastAccessed = null;
    }
  }

  /// Check if this item should be garbage collected
  bool shouldGarbageCollect({
    Duration maxAge = const Duration(minutes: 10),
    bool respectRecentAccess = true,
  }) {
    if (_isDisposed || _thumbnailCache == null) return false;
    
    if (!respectRecentAccess) return true;
    
    final now = DateTime.now();
    final lastAccess = _lastAccessed ?? dateAdded;
    
    return now.difference(lastAccess) > maxAge;
  }

  /// Dispose of resources and mark as disposed
  void dispose() {
    if (!_isDisposed) {
      _thumbnailCache = null;
      _lastAccessed = null;
      _isDisposed = true;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhotoItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PhotoItem(id: $id, cached: $hasCachedThumbnail, disposed: $_isDisposed)';
}
