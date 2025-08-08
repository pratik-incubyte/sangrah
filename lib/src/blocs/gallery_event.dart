part of 'gallery_bloc.dart';

@immutable
sealed class GalleryEvent extends Equatable {}

final class LoadPhotos extends GalleryEvent {
  @override
  List<Object> get props => [];
}

final class LoadMorePhotos extends GalleryEvent {
  @override
  List<Object> get props => [];
}

final class UpdateViewportWindow extends GalleryEvent {
  final int centerIndex;
  
  UpdateViewportWindow(this.centerIndex);
  
  @override
  List<Object> get props => [centerIndex];
}

final class PerformGarbageCollection extends GalleryEvent {
  @override
  List<Object> get props => [];
}

