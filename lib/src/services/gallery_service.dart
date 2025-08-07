import 'package:photo_manager/photo_manager.dart';

abstract class GalleryService {
  List<AssetEntity> getPhotos();
}

class GalleryServiceImpl implements GalleryService {
  final PhotoManager photoManager;

  GalleryServiceImpl(this.photoManager);

  @override
  List<AssetEntity> getPhotos() {
    // TODO: implement getPhotoss
    throw UnimplementedError();
  }
}
