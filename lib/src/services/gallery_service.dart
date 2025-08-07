import 'package:photo_manager/photo_manager.dart';

abstract class GalleryService {
  Future<List<AssetEntity>> getPhotos({int limit = 100});
}

class GalleryServiceImpl implements GalleryService {
  GalleryServiceImpl();

  @override
  Future<List<AssetEntity>> getPhotos({int limit = 100}) async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        return [];
      }

      final assetPaths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      if (assetPaths.isEmpty) {
        return [];
      }

      final List<AssetEntity> photos = await assetPaths.first.getAssetListPaged(
        page: 0,
        size: limit,
      );

      return photos;
    } catch (e) {
      throw Exception('Failed to get photos: $e');
    }
  }
}
