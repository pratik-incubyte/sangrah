import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sangrah/src/models/photo_item.dart';
import 'package:sangrah/src/screens/photo_full_screen.dart';
import 'package:sangrah/src/widgets/thumbnail_widget.dart';

class PhotoGridItem extends StatelessWidget {
  const PhotoGridItem({
    super.key, 
    required this.photoItem,
    this.onTap,
  });

  final PhotoItem photoItem;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PhotoFullScreen(photo: photoItem.asset),
          ),
        );
      },
      child: Hero(
        tag: photoItem.id,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ThumbnailWidget(
            photoItem: photoItem,
            size: const ThumbnailSize(200, 200),
          ),
        ),
      ),
    );
  }
}
