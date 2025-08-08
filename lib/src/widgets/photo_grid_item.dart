import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sangrah/src/screens/photo_full_screen.dart';
import 'package:sangrah/src/widgets/thumbnail_widget.dart';

class PhotoGridItem extends StatelessWidget {
  const PhotoGridItem({super.key, required this.photo});

  final AssetEntity photo;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PhotoFullScreen(photo: photo),
          ),
        );
      },
      child: Hero(
        tag: photo.id,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ThumbnailWidget(
            photo: photo,
            size: const ThumbnailSize(200, 200),
          ),
        ),
      ),
    );
  }
}
