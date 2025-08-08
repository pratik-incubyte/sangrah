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
  final List<AssetEntity> photos;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final int currentPage;
  
  GalleryLoaded({
    required this.photos,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.currentPage = 0,
  });
  
  @override
  List<Object> get props => [photos.length, isLoadingMore, hasReachedMax, currentPage];
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is GalleryLoaded &&
           other.photos.length == photos.length &&
           other.isLoadingMore == isLoadingMore &&
           other.hasReachedMax == hasReachedMax &&
           other.currentPage == currentPage;
  }
  
  @override
  int get hashCode {
    return photos.length.hashCode ^
           isLoadingMore.hashCode ^
           hasReachedMax.hashCode ^
           currentPage.hashCode;
  }
  
  GalleryLoaded copyWith({
    List<AssetEntity>? photos,
    bool? isLoadingMore,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return GalleryLoaded(
      photos: photos ?? this.photos,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

final class GalleryError extends GalleryState {
  final String message;
  
  GalleryError(this.message);
  
  @override
  List<Object> get props => [message];
}


