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
  
  GalleryLoaded({
    required this.photos
  });
  
  @override
  List<Object> get props => [photos];
}

final class GalleryError extends GalleryState {
  final String message;
  
  GalleryError(this.message);
  
  @override
  List<Object> get props => [message];
}


