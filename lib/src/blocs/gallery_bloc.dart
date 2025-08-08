import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:photo_manager/photo_manager.dart';
import '../config/pagination_config.dart';
import '../services/gallery_service.dart';

part 'gallery_event.dart';
part 'gallery_state.dart';

class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  final GalleryService _galleryService;

  GalleryBloc({GalleryService? galleryService})
    : _galleryService = galleryService ?? GalleryServiceImpl(),
      super(GalleryInitial()) {
    on<LoadPhotos>(_onLoadPhotos);
    on<LoadMorePhotos>(_onLoadMorePhotos);
  }

  Future<void> _onLoadPhotos(
    LoadPhotos event,
    Emitter<GalleryState> emit,
  ) async {
    emit(GalleryLoading());
    await _loadPhotosPage(emit, page: 0, isInitialLoad: true);
  }

  Future<void> _onLoadMorePhotos(
    LoadMorePhotos event,
    Emitter<GalleryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! GalleryLoaded || 
        currentState.hasReachedMax || 
        currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));
    await _loadPhotosPage(emit, 
        page: currentState.currentPage + 1, 
        existingPhotos: currentState.photos);
  }


  Future<void> _loadPhotosPage(
    Emitter<GalleryState> emit, {
    required int page,
    List<AssetEntity>? existingPhotos,
    bool isInitialLoad = false,
  }) async {
    try {
      final newPhotos = await _galleryService.getPhotos(
        page: page, 
        limit: PaginationConfig.photosPerPage,
      );

      final currentPhotos = existingPhotos ?? <AssetEntity>[];
      final updatedPhotos = currentPhotos + newPhotos;
      final hasReachedMax = newPhotos.length < PaginationConfig.photosPerPage;

      if (isInitialLoad && updatedPhotos.isEmpty) {
        emit(GalleryError("No photos found. Please check your gallery permissions."));
        return;
      }

      emit(GalleryLoaded(
        photos: updatedPhotos,
        currentPage: page,
        hasReachedMax: hasReachedMax,
        isLoadingMore: false,
      ));
    } catch (err) {
      if (existingPhotos != null && existingPhotos.isNotEmpty) {
        // If we have existing photos, don't show error, just stop loading more
        final currentState = state as GalleryLoaded;
        emit(currentState.copyWith(
          isLoadingMore: false,
          hasReachedMax: true,
        ));
      } else {
        emit(GalleryError(err.toString()));
      }
    }
  }
}
