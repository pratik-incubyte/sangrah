import 'package:photo_manager/photo_manager.dart';

abstract class GalleryService {
  Future<List<AssetEntity>> getPhotos({required int page, required int limit});
}

class GalleryServiceImpl implements GalleryService {
  GalleryServiceImpl();

  @override
  Future<List<AssetEntity>> getPhotos({required int page, required int limit}) async {
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
        page: page,
        size: limit,
      );

      return photos;
    } catch (e) {
      throw Exception('Failed to get photos: $e');
    }
  }
}
