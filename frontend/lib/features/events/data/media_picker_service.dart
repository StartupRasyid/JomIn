import 'package:image_picker/image_picker.dart';

enum PickedMediaType { image, video }

class PickedMediaResult {
  final XFile file;
  final PickedMediaType type;

  const PickedMediaResult({
    required this.file,
    required this.type,
  });
}

class MediaPickerService {
  final ImagePicker _picker = ImagePicker();

  /// Opens the gallery to pick a poster image (compressed reasonably for upload).
  Future<PickedMediaResult?> pickImageFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (file == null) return null;
    return PickedMediaResult(file: file, type: PickedMediaType.image);
  }

  /// Opens the gallery to pick a promotional video (capped at 60 seconds).
  Future<PickedMediaResult?> pickVideoFromGallery() async {
    final XFile? file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (file == null) return null;
    return PickedMediaResult(file: file, type: PickedMediaType.video);
  }
}