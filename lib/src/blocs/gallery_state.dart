part of 'gallery_bloc.dart';

@immutable
sealed class GalleryState extends Equatable {}

final class GalleryInitial extends GalleryState {
  @override
  List<Object> get props => [];
}

final class GalleryLoading extends GalleryState {
  @override
  List<Object> get props => [];
}

final class GalleryLoaded extends GalleryState {
  final PaginatedPhotoCollection photoCollection;
  final DateTime lastUpdated;
  
  GalleryLoaded({
    required this.photoCollection,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
  
  // Convenience getters for backward compatibility
  List<PhotoItem> get photos => List.generate(
    photoCollection.length,
    (index) => photoCollection.getItemAt(index)!,
  );
  
  bool get isLoadingMore => photoCollection.isLoadingMore;
  bool get hasReachedMax => photoCollection.hasReachedMax;
  int get currentPage => photoCollection.currentPage;
  int get totalItems => photoCollection.length;
  bool get isEmpty => photoCollection.isEmpty;
  bool get isNotEmpty => photoCollection.isNotEmpty;
  
  // Memory management getters
  Map<String, dynamic> get memoryStats => photoCollection.getMemoryStats();
  Set<int> get loadedPages => photoCollection.loadedPages;
  int get windowStart => photoCollection.windowStart;
  int get windowEnd => photoCollection.windowEnd;
  
  @override
  List<Object> get props => [
    photoCollection.length,
    photoCollection.isLoadingMore,
    photoCollection.hasReachedMax,
    photoCollection.currentPage,
    lastUpdated,
  ];
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is GalleryLoaded &&
           other.photoCollection.length == photoCollection.length &&
           other.photoCollection.isLoadingMore == photoCollection.isLoadingMore &&
           other.photoCollection.hasReachedMax == photoCollection.hasReachedMax &&
           other.photoCollection.currentPage == photoCollection.currentPage;
  }
  
  @override
  int get hashCode {
    return photoCollection.length.hashCode ^
           photoCollection.isLoadingMore.hashCode ^
           photoCollection.hasReachedMax.hashCode ^
           photoCollection.currentPage.hashCode ^
           lastUpdated.hashCode;
  }
  
  GalleryLoaded copyWith({
    PaginatedPhotoCollection? photoCollection,
    DateTime? lastUpdated,
  }) {
    return GalleryLoaded(
      photoCollection: photoCollection ?? this.photoCollection,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  /// Update window for viewport optimization
  void updateViewportWindow(int centerIndex) {
    photoCollection.updateWindow(centerIndex);
  }
  
  /// Get photo item by index (null-safe)
  PhotoItem? getPhotoAt(int index) => photoCollection.getItemAt(index);
  
  /// Get photos in a specific range for efficient rendering
  List<PhotoItem> getPhotosInRange(int startIndex, int endIndex) {
    return photoCollection.getItemsInRange(startIndex, endIndex);
  }
  
  /// Perform memory cleanup
  void performGarbageCollection() {
    photoCollection.performGarbageCollection();
  }
}

final class GalleryError extends GalleryState {
  final String message;
  
  GalleryError(this.message);
  
  @override
  List<Object> get props => [message];
}


