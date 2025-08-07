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

  setUp(() {
    mockGalleryService = MockGalleryService();
    galleryBloc = GalleryBloc(galleryService: mockGalleryService);
  });

  tearDown(() {
    galleryBloc.close();
  });

  group('GalleryBloc', () {
    test('initial state is GalleryInitial', () {
      expect(galleryBloc.state, equals(GalleryInitial()));
    });

    blocTest<GalleryBloc, GalleryState>(
      'should emit [GalleryLoading, GalleryLoaded] when LoadPhotos event is added',
      build: () {
        final mockAssets = [MockAssetEntity(), MockAssetEntity()];
        when(
          mockGalleryService.getPhotos(),
        ).thenAnswer((_) async => mockAssets);
        return galleryBloc;
      },
      act: (bloc) => bloc.add(LoadPhotos()),
      expect: () => [
        GalleryLoading(),
        isA<GalleryLoaded>().having(
          (state) => state.photos.length,
          'photos length',
          2,
        ),
      ],
      verify: (_) {
        verify(mockGalleryService.getPhotos()).called(1);
      },
    );

    blocTest<GalleryBloc, GalleryState>(
      'should emit [GalleryLoading, GalleryError] when LoadPhotos fails',
      build: () {
        when(
          mockGalleryService.getPhotos(),
        ).thenThrow(Exception('Failed to get photos.'));
        return galleryBloc;
      },
      act: (bloc) => bloc.add(LoadPhotos()),
      expect: () => [
        GalleryLoading(),
        GalleryError('Exception: Failed to get photos.'),
      ],
    );

    blocTest<GalleryBloc, GalleryState>(
      'should emit [GalleryLoading, GalleryEror] when permission is denied',
      build: () {
        when(mockGalleryService.getPhotos()).thenAnswer((_) async => []);
        return galleryBloc;
      },
      act: (bloc) => bloc.add(LoadPhotos()),
      expect: () => [GalleryLoading(), GalleryError("Failed to get photos.")],
    );
  });
}
