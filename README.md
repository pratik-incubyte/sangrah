# Sangrah - Photo Gallery App

A Flutter app that displays photos from the device using the photo_manager package.

## Features

- **Photo Grid View**: Displays device photos in a 3-column grid layout
- **Full-Screen Photo View**: Tap any photo to view it in full screen
- **Permission Handling**: Automatically requests storage permissions
- **Optimized Thumbnails**: Loads efficient thumbnails for the grid view
- **Error Handling**: Graceful handling of permission denials and loading errors

## Dependencies

- **photo_manager**: ^3.5.0 - For accessing device photos
- **permission_handler**: ^11.3.1 - For handling storage permissions

## Permissions

The app requires the following Android permissions (automatically handled):
- `READ_EXTERNAL_STORAGE` (for older Android versions)
- `READ_MEDIA_IMAGES` (for Android 13+)
- `READ_MEDIA_VIDEO` (for video support)

## How it Works

1. **Permission Request**: On first launch, the app requests storage permissions
2. **Photo Loading**: Accesses device photo albums using PhotoManager
3. **Grid Display**: Shows first 100 photos in a responsive grid
4. **Full Screen**: Navigate to individual photo view by tapping thumbnails

## Project Structure

```
lib/
├── main.dart                 # App entry point
└── photo_gallery_screen.dart # Main photo gallery implementation
```

## Usage

1. Install dependencies: `flutter pub get`
2. Run on device: `flutter run`
3. Grant photo permissions when prompted
4. Browse your photos in the gallery view

## Notes

- The app loads the first 100 photos from the device's main photo album
- Thumbnails are generated at 200x200 pixels for optimal performance
- Full-resolution images are loaded only when viewing individual photos
- All image processing is handled natively for best performance
