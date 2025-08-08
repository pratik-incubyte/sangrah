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

