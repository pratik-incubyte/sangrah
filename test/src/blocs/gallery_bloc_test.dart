import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sangrah/src/blocs/gallery_bloc.dart';
import 'package:sangrah/src/services/gallery_service.dart';

import 'gallery_bloc_test.mocks.dart';

@GenerateMocks([GalleryService, AssetEntity])
void main() {
  late MockGalleryService mockGalleryService;
  late GalleryBloc galleryBloc;
  late List<MockAssetEntity> mockPhotos;

  setUp(() {
    mockGalleryService = MockGalleryService();
    galleryBloc = GalleryBloc(galleryService: mockGalleryService);
    mockPhotos = List.generate(60, (index) => MockAssetEntity());
  });

  tearDown(() {
    galleryBloc.close();
  });

  group('GalleryBloc', () {
    test('initial state is GalleryInitial', () {
      expect(galleryBloc.state, equals(GalleryInitial()));
    });

    group('LoadPhotos', () {
      blocTest<GalleryBloc, GalleryState>(
        'should emit [GalleryLoading, GalleryLoaded] when LoadPhotos succeeds',
        build: () {
          when(
            mockGalleryService.getPhotos(page: 0, limit: 60),
          ).thenAnswer((_) async => mockPhotos);
          return galleryBloc;
        },
        act: (bloc) => bloc.add(LoadPhotos()),
        expect: () => [
          GalleryLoading(),
          isA<GalleryLoaded>()
              .having((state) => state.photos.length, 'photos length', 60)
              .having((state) => state.currentPage, 'current page', 0)
              .having((state) => state.isLoadingMore, 'is loading more', false)
              .having((state) => state.hasReachedMax, 'has reached max', false),
        ],
        verify: (_) {
          verify(mockGalleryService.getPhotos(page: 0, limit: 60)).called(1);
        },
      );

      blocTest<GalleryBloc, GalleryState>(
        'should emit [GalleryLoading, GalleryLoaded] with hasReachedMax=true when fewer photos returned',
        build: () {
          final fewPhotos = mockPhotos.take(30).toList();
          when(
            mockGalleryService.getPhotos(page: 0, limit: 60),
          ).thenAnswer((_) async => fewPhotos);
          return galleryBloc;
        },
        act: (bloc) => bloc.add(LoadPhotos()),
        expect: () => [
          GalleryLoading(),
          isA<GalleryLoaded>()
              .having((state) => state.photos.length, 'photos length', 30)
              .having((state) => state.hasReachedMax, 'has reached max', true),
        ],
      );

      blocTest<GalleryBloc, GalleryState>(
        'should emit [GalleryLoading, GalleryError] when LoadPhotos fails',
        build: () {
          when(
            mockGalleryService.getPhotos(page: 0, limit: 60),
          ).thenThrow(Exception('Failed to get photos'));
          return galleryBloc;
        },
        act: (bloc) => bloc.add(LoadPhotos()),
        expect: () => [
          GalleryLoading(),
          GalleryError('Exception: Failed to get photos'),
        ],
      );

      blocTest<GalleryBloc, GalleryState>(
        'should emit [GalleryLoading, GalleryError] when no photos are found',
        build: () {
          when(
            mockGalleryService.getPhotos(page: 0, limit: 60),
          ).thenAnswer((_) async => []);
          return galleryBloc;
        },
        act: (bloc) => bloc.add(LoadPhotos()),
        expect: () => [
          GalleryLoading(),
          GalleryError('No photos found. Please check your gallery permissions.'),
        ],
      );
    });

    group('LoadMorePhotos', () {
      blocTest<GalleryBloc, GalleryState>(
        'should load more photos when state is GalleryLoaded and not at max',
        build: () {
          when(mockGalleryService.getPhotos(page: 0, limit: 60))
              .thenAnswer((_) async => mockPhotos);
          when(mockGalleryService.getPhotos(page: 1, limit: 60))
              .thenAnswer((_) async => mockPhotos.take(30).toList());
          return galleryBloc;
        },
        seed: () => GalleryLoaded(
          photos: mockPhotos,
          currentPage: 0,
          hasReachedMax: false,
        ),
        act: (bloc) => bloc.add(LoadMorePhotos()),
        expect: () => [
          isA<GalleryLoaded>()
              .having((state) => state.isLoadingMore, 'is loading more', true),
          isA<GalleryLoaded>()
              .having((state) => state.photos.length, 'photos length', 90)
              .having((state) => state.currentPage, 'current page', 1)
              .having((state) => state.isLoadingMore, 'is loading more', false)
              .having((state) => state.hasReachedMax, 'has reached max', true),
        ],
        verify: (_) {
          verify(mockGalleryService.getPhotos(page: 1, limit: 60)).called(1);
        },
      );

      blocTest<GalleryBloc, GalleryState>(
        'should not load more photos when hasReachedMax is true',
        build: () => galleryBloc,
        seed: () => GalleryLoaded(
          photos: [],
          currentPage: 0,
          hasReachedMax: true,
        ),
        act: (bloc) => bloc.add(LoadMorePhotos()),
        expect: () => [],
        verify: (_) {
          verifyNever(mockGalleryService.getPhotos(page: anyNamed('page'), limit: anyNamed('limit')));
        },
      );

      blocTest<GalleryBloc, GalleryState>(
        'should not load more photos when already loading',
        build: () => galleryBloc,
        seed: () => GalleryLoaded(
          photos: [],
          currentPage: 0,
          isLoadingMore: true,
        ),
        act: (bloc) => bloc.add(LoadMorePhotos()),
        expect: () => [],
        verify: (_) {
          verifyNever(mockGalleryService.getPhotos(page: anyNamed('page'), limit: anyNamed('limit')));
        },
      );

      blocTest<GalleryBloc, GalleryState>(
        'should handle error gracefully during load more and set hasReachedMax',
        build: () {
          when(mockGalleryService.getPhotos(page: 1, limit: 60))
              .thenThrow(Exception('Network error'));
          return galleryBloc;
        },
        seed: () => GalleryLoaded(
          photos: mockPhotos,
          currentPage: 0,
          hasReachedMax: false,
        ),
        act: (bloc) => bloc.add(LoadMorePhotos()),
        expect: () => [
          isA<GalleryLoaded>()
              .having((state) => state.isLoadingMore, 'is loading more', true),
          isA<GalleryLoaded>()
              .having((state) => state.photos.length, 'photos length', 60)
              .having((state) => state.isLoadingMore, 'is loading more', false)
              .having((state) => state.hasReachedMax, 'has reached max', true),
        ],
      );
    });

    group('State transitions', () {
      blocTest<GalleryBloc, GalleryState>(
        'should ignore LoadMorePhotos when state is not GalleryLoaded',
        build: () => galleryBloc,
        seed: () => GalleryLoading(),
        act: (bloc) => bloc.add(LoadMorePhotos()),
        expect: () => [],
        verify: (_) {
          verifyNever(mockGalleryService.getPhotos(page: anyNamed('page'), limit: anyNamed('limit')));
        },
      );

      blocTest<GalleryBloc, GalleryState>(
        'should handle multiple rapid LoadMorePhotos events correctly',
        build: () {
          when(mockGalleryService.getPhotos(page: 1, limit: 60))
              .thenAnswer((_) async {
            // Simulate some delay
            await Future.delayed(Duration(milliseconds: 50));
            return mockPhotos.take(30).toList();
          });
          return galleryBloc;
        },
        seed: () => GalleryLoaded(
          photos: mockPhotos,
          currentPage: 0,
          hasReachedMax: false,
        ),
        act: (bloc) {
          bloc.add(LoadMorePhotos());
          bloc.add(LoadMorePhotos()); // This should be ignored
          bloc.add(LoadMorePhotos()); // This should be ignored
        },
        wait: const Duration(milliseconds: 200),
        expect: () => [
          isA<GalleryLoaded>()
              .having((state) => state.isLoadingMore, 'is loading more', true),
          isA<GalleryLoaded>()
              .having((state) => state.photos.length, 'photos length', 90)
              .having((state) => state.isLoadingMore, 'is loading more', false),
        ],
        verify: (_) {
          // Should only be called once despite multiple events
          verify(mockGalleryService.getPhotos(page: 1, limit: 60)).called(1);
        },
      );
    });
  });
}
