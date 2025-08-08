import 'dart:math' as math;
import 'package:photo_manager/photo_manager.dart';
import 'photo_item.dart';

/// Memory-efficient collection that manages photos with windowing and garbage collection
class PaginatedPhotoCollection {
  final Map<String, PhotoItem> _items = {};
  final List<String> _orderedIds = [];
  final Set<int> _loadedPages = {};
  
  int _currentPage = 0;
  bool _hasReachedMax = false;
  bool _isLoadingMore = false;
  
  // Memory management settings
  final int _maxCachedItems;
  final Duration _cacheTimeout;
  
  // Windowing settings for viewport optimization
  final int _windowSize;
  int _currentWindowStart = 0;
  int _currentWindowEnd = 0;
  
  PaginatedPhotoCollection({
    int maxCachedItems = 500,
    Duration cacheTimeout = const Duration(minutes: 10),
    int windowSize = 100, // Number of items to keep in active window
  }) : _maxCachedItems = maxCachedItems,
       _cacheTimeout = cacheTimeout,
       _windowSize = windowSize;

  // Public getters
  int get length => _orderedIds.length;
  int get currentPage => _currentPage;
  bool get hasReachedMax => _hasReachedMax;
  bool get isLoadingMore => _isLoadingMore;
  bool get isEmpty => _orderedIds.isEmpty;
  bool get isNotEmpty => _orderedIds.isNotEmpty;
  Set<int> get loadedPages => Set.from(_loadedPages);
  
  // Window management getters
  int get windowStart => _currentWindowStart;
  int get windowEnd => _currentWindowEnd;
  int get windowSize => _windowSize;

  /// Get photo item by index with bounds checking
  PhotoItem? getItemAt(int index) {
    if (index < 0 || index >= _orderedIds.length) return null;
    final id = _orderedIds[index];
    return _items[id];
  }

  /// Get photo item by ID
  PhotoItem? getItemById(String id) => _items[id];

  /// Get all items in current window
  List<PhotoItem> getWindowItems() {
    final start = math.max(0, _currentWindowStart);
    final end = math.min(_orderedIds.length, _currentWindowEnd);
    
    final windowItems = <PhotoItem>[];
    for (int i = start; i < end; i++) {
      final item = getItemAt(i);
      if (item != null) windowItems.add(item);
    }
    return windowItems;
  }

  /// Get visible items in a specific range (for viewport optimization)
  List<PhotoItem> getItemsInRange(int startIndex, int endIndex) {
    final start = math.max(0, startIndex);
    final end = math.min(_orderedIds.length, endIndex);
    
    final items = <PhotoItem>[];
    for (int i = start; i < end; i++) {
      final item = getItemAt(i);
      if (item != null) items.add(item);
    }
    return items;
  }

  /// Add new photos from a page load
  void addPhotosFromPage({
    required List<AssetEntity> assets,
    required int pageNumber,
    required bool isLastPage,
  }) {
    _loadedPages.add(pageNumber);
    _currentPage = math.max(_currentPage, pageNumber);
    _hasReachedMax = isLastPage;
    
    final newItems = <PhotoItem>[];
    
    for (final asset in assets) {
      final item = PhotoItem(
        id: asset.id,
        asset: asset,
        dateAdded: DateTime.now(),
      );
      
      // Add only if not already present
      if (!_items.containsKey(item.id)) {
        _items[item.id] = item;
        _orderedIds.add(item.id);
        newItems.add(item);
      }
    }
    
    // Update window to include new items
    _updateWindow();
    
    // Trigger garbage collection if needed
    if (_items.length > _maxCachedItems) {
      _performGarbageCollection();
    }
  }

  /// Update the current viewing window
  void updateWindow(int centerIndex, {int? customWindowSize}) {
    final window = customWindowSize ?? _windowSize;
    final halfWindow = window ~/ 2;
    
    _currentWindowStart = math.max(0, centerIndex - halfWindow);
    _currentWindowEnd = math.min(_orderedIds.length, centerIndex + halfWindow);
    
    _updateWindow();
  }

  /// Internal window update with preloading
  void _updateWindow() {
    final windowItems = getWindowItems();
    
    // Preload thumbnails for items in window
    for (final item in windowItems) {
      if (!item.hasCachedThumbnail && !item.isLoadingThumbnail) {
        item.preloadThumbnail();
      }
    }
  }

  /// Set loading state
  void setLoadingState(bool isLoading) {
    _isLoadingMore = isLoading;
  }

  /// Clear specific page data
  void clearPage(int pageNumber) {
    _loadedPages.remove(pageNumber);
    // Note: We don't remove items here as they might be needed
    // Let garbage collection handle cleanup
  }

  /// Perform garbage collection to free memory
  void _performGarbageCollection() {
    final itemsToRemove = <String>[];
    
    // Find items to remove based on various criteria
    for (final entry in _items.entries) {
      final id = entry.key;
      final item = entry.value;
      
      // Skip items in current window
      final index = _orderedIds.indexOf(id);
      if (index >= _currentWindowStart && index < _currentWindowEnd) {
        continue;
      }
      
      // Mark for removal if it should be garbage collected
      if (item.shouldGarbageCollect(maxAge: _cacheTimeout)) {
        itemsToRemove.add(id);
      }
    }
    
    // Remove oldest items if we're still over the limit
    if (_items.length - itemsToRemove.length > _maxCachedItems) {
      final sortedItems = _items.entries
          .where((e) => !itemsToRemove.contains(e.key))
          .toList();
          
      sortedItems.sort((a, b) {
        final aAccess = a.value.lastAccessed ?? a.value.dateAdded;
        final bAccess = b.value.lastAccessed ?? b.value.dateAdded;
        return aAccess.compareTo(bAccess);
      });
      
      final additionalToRemove = (_items.length - itemsToRemove.length) - _maxCachedItems;
      for (int i = 0; i < additionalToRemove && i < sortedItems.length; i++) {
        itemsToRemove.add(sortedItems[i].key);
      }
    }
    
    // Remove items and dispose resources
    for (final id in itemsToRemove) {
      final item = _items.remove(id);
      item?.dispose();
    }
  }

  /// Force garbage collection
  void performGarbageCollection() => _performGarbageCollection();

  /// Clear all cached thumbnails to free memory
  void clearAllThumbnailCaches() {
    for (final item in _items.values) {
      item.clearThumbnailCache();
    }
  }

  /// Clear specific item from cache
  void clearItem(String id) {
    final item = _items.remove(id);
    if (item != null) {
      item.dispose();
      _orderedIds.remove(id);
    }
  }

  /// Reset collection
  void clear() {
    // Dispose all items
    for (final item in _items.values) {
      item.dispose();
    }
    
    _items.clear();
    _orderedIds.clear();
    _loadedPages.clear();
    _currentPage = 0;
    _hasReachedMax = false;
    _isLoadingMore = false;
    _currentWindowStart = 0;
    _currentWindowEnd = 0;
  }

  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    int cachedThumbnails = 0;
    int totalMemoryBytes = 0;
    
    for (final item in _items.values) {
      if (item.hasCachedThumbnail) {
        cachedThumbnails++;
        // Estimate memory usage (this is approximate)
        totalMemoryBytes += 200 * 200 * 4; // RGBA bytes
      }
    }
    
    return {
      'totalItems': _items.length,
      'orderedItems': _orderedIds.length,
      'cachedThumbnails': cachedThumbnails,
      'estimatedMemoryMB': (totalMemoryBytes / (1024 * 1024)).toStringAsFixed(2),
      'loadedPages': _loadedPages.length,
      'currentWindow': '$_currentWindowStart-$_currentWindowEnd',
      'windowSize': _windowSize,
    };
  }

  /// Dispose of all resources
  void dispose() {
    clear();
  }
}
