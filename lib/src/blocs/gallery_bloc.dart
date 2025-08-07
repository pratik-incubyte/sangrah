import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/gallery_service.dart';

part 'gallery_event.dart';
part 'gallery_state.dart';

class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  final GalleryService _galleryService;

  GalleryBloc({GalleryService? galleryService})
    : _galleryService = galleryService ?? GalleryServiceImpl(),
      super(GalleryInitial()) {
    on<LoadPhotos>(_onLoadPhotos);
  }

  Future<void> _onLoadPhotos(
    LoadPhotos event,
    Emitter<GalleryState> emit,
  ) async {
    emit(GalleryLoading());

    try {
      final photos = await _galleryService.getPhotos();

      if (photos.isEmpty) {
        emit(GalleryError("Failed to get photos."));
      } else {
        emit(GalleryLoaded(photos: photos));
      }
    } catch (err) {
      emit(GalleryError(err.toString()));
    }
  }
}
