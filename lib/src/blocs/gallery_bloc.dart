import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import '../config/pagination_config.dart';
import '../services/gallery_service.dart';
import '../models/paginated_photo_collection.dart';
import '../models/photo_item.dart';

part 'gallery_event.dart';
part 'gallery_state.dart';

class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  final GalleryService _galleryService;
  PaginatedPhotoCollection? _photoCollection;

  GalleryBloc({GalleryService? galleryService})
    : _galleryService = galleryService ?? GalleryServiceImpl(),
      super(GalleryInitial()) {
    on<LoadPhotos>(_onLoadPhotos);
    on<LoadMorePhotos>(_onLoadMorePhotos);
    on<UpdateViewportWindow>(_onUpdateViewportWindow);
    on<PerformGarbageCollection>(_onPerformGarbageCollection);
  }

  Future<void> _onLoadPhotos(
    LoadPhotos event,
    Emitter<GalleryState> emit,
  ) async {
    // Dispose existing collection if any
    _photoCollection?.dispose();
    
    // Create new collection with memory management settings
    _photoCollection = PaginatedPhotoCollection(
      maxCachedItems: 500,
      cacheTimeout: const Duration(minutes: 10),
      windowSize: 150, // Larger window for smoother scrolling
    );
    
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
        currentState.isLoadingMore ||
        _photoCollection == null) {
      return;
    }

    // Set loading state in collection
    _photoCollection!.setLoadingState(true);
    
    emit(currentState.copyWith(
      photoCollection: _photoCollection,
      lastUpdated: DateTime.now(),
    ));
    
    await _loadPhotosPage(emit, page: currentState.currentPage + 1);
  }
  
  void _onUpdateViewportWindow(
    UpdateViewportWindow event,
    Emitter<GalleryState> emit,
  ) {
    final currentState = state;
    if (currentState is GalleryLoaded && _photoCollection != null) {
      currentState.updateViewportWindow(event.centerIndex);
      // No need to emit new state as this is an optimization update
    }
  }
  
  void _onPerformGarbageCollection(
    PerformGarbageCollection event,
    Emitter<GalleryState> emit,
  ) {
    final currentState = state;
    if (currentState is GalleryLoaded) {
      currentState.performGarbageCollection();
      // Optionally emit updated state to reflect memory stats changes
      emit(currentState.copyWith(lastUpdated: DateTime.now()));
    }
  }

  Future<void> _loadPhotosPage(
    Emitter<GalleryState> emit, {
    required int page,
    bool isInitialLoad = false,
  }) async {
    if (_photoCollection == null) return;
    
    try {
      final newPhotos = await _galleryService.getPhotos(
        page: page, 
        limit: PaginationConfig.photosPerPage,
      );

      final hasReachedMax = newPhotos.length < PaginationConfig.photosPerPage;

      if (isInitialLoad && newPhotos.isEmpty) {
        emit(GalleryError("No photos found. Please check your gallery permissions."));
        return;
      }

      // Add photos to collection with memory management
      _photoCollection!.addPhotosFromPage(
        assets: newPhotos,
        pageNumber: page,
        isLastPage: hasReachedMax,
      );
      
      // Set loading state to false
      _photoCollection!.setLoadingState(false);

      emit(GalleryLoaded(
        photoCollection: _photoCollection!,
        lastUpdated: DateTime.now(),
      ));
    } catch (err) {
      if (_photoCollection!.isNotEmpty) {
        // If we have existing photos, don't show error, just stop loading more
        _photoCollection!.setLoadingState(false);
        
        // Mark as reached max to prevent further loading attempts
        final currentState = state as GalleryLoaded;
        emit(currentState.copyWith(lastUpdated: DateTime.now()));
      } else {
        emit(GalleryError(err.toString()));
      }
    }
  }
  
  @override
  Future<void> close() {
    _photoCollection?.dispose();
    return super.close();
  }
}
