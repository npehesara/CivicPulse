import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Encapsulates the processed image data ready for multipart upload.
class ProcessedImageResult {
  final Uint8List bytes;
  final String filename;
  final String mimeType;
  final int byteSize;

  const ProcessedImageResult({
    required this.bytes,
    required this.filename,
    required this.mimeType,
    required this.byteSize,
  });
}

/// Utility for safely handling, validating, resizing, and compressing images
/// on the client side before uploading to CivicPulse backend storage.
class ImageUtils {
  /// Target max size is 3 MB, safely below the 5 MB backend profile image limit.
  static const int maxProfileSizeBytes = 3 * 1024 * 1024;

  /// Processes a selected image from Camera or Gallery:
  /// 1. Reads raw bytes and validates non-emptiness.
  /// 2. Validates supported formats (JPG/JPEG, PNG, WEBP) via magic bytes and extensions.
  /// 3. If file size is within [maxProfileSizeBytes], returns original bytes with correct MIME type.
  /// 4. If file size exceeds the 3 MB limit:
  ///    - Decodes and corrects EXIF orientation.
  ///    - Resizes to standard profile photo dimensions (max 1600px).
  ///    - Encodes as JPEG with high visual quality (quality: 85).
  ///    - Progressively reduces dimensions and/or JPEG quality until safely below [maxProfileSizeBytes].
  /// 5. Throws a friendly exception only if decoding or compression fails.
  static Future<ProcessedImageResult> processProfileImage(XFile file) async {
    final rawBytes = await file.readAsBytes();
    if (rawBytes.isEmpty) {
      throw Exception('Selected image is empty. Please select a valid photo.');
    }

    String rawName = '';
    try {
      if (file.name.isNotEmpty) rawName = file.name;
    } catch (_) {}
    if (rawName.isEmpty) {
      try {
        if (file.path.isNotEmpty) rawName = file.path;
      } catch (_) {}
    }
    if (rawName.isEmpty) rawName = 'profile_photo.jpg';

    rawName = rawName.replaceAll(r'\', '/').split('/').last;
    final dotIndex = rawName.lastIndexOf('.');
    String ext = (dotIndex != -1 && dotIndex < rawName.length - 1)
        ? rawName.substring(dotIndex + 1).toLowerCase()
        : 'jpg';
    String baseName = dotIndex != -1 ? rawName.substring(0, dotIndex) : rawName;
    if (baseName.isEmpty) baseName = 'profile_photo';

    // Verify format by magic bytes if present
    if (rawBytes.length >= 4 &&
        rawBytes[0] == 0x89 &&
        rawBytes[1] == 0x50 &&
        rawBytes[2] == 0x4E &&
        rawBytes[3] == 0x47) {
      ext = 'png';
    } else if (rawBytes.length >= 2 && rawBytes[0] == 0xFF && rawBytes[1] == 0xD8) {
      ext = 'jpg';
    }

    // Normalize MIME type and filename
    String mimeType;
    switch (ext) {
      case 'png':
        mimeType = 'image/png';
        break;
      case 'webp':
        mimeType = 'image/webp';
        break;
      case 'jpg':
      case 'jpeg':
      default:
        mimeType = 'image/jpeg';
        ext = 'jpg';
        break;
    }

    // If already safely below 3 MB, preserve original bytes and format
    if (rawBytes.length <= maxProfileSizeBytes) {
      final safeFilename = '$baseName.$ext';
      return ProcessedImageResult(
        bytes: rawBytes,
        filename: safeFilename,
        mimeType: mimeType,
        byteSize: rawBytes.length,
      );
    }

    // Image exceeds 3 MB client limit: decode, resize, and compress as JPEG
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) {
        throw Exception('Could not decode image format. Please select a valid photo.');
      }

      // Automatically correct orientation from EXIF
      final oriented = img.bakeOrientation(decoded);

      int maxDimension = 1600;
      int quality = 85;
      Uint8List compressedBytes = Uint8List(0);

      // Progressively reduce dimensions and/or quality until strictly <= maxProfileSizeBytes (3 MB)
      for (int attempt = 0; attempt < 5; attempt++) {
        img.Image resized = oriented;
        if (oriented.width > maxDimension || oriented.height > maxDimension) {
          if (oriented.width >= oriented.height) {
            resized = img.copyResize(oriented, width: maxDimension, interpolation: img.Interpolation.cubic);
          } else {
            resized = img.copyResize(oriented, height: maxDimension, interpolation: img.Interpolation.cubic);
          }
        }

        final encoded = img.encodeJpg(resized, quality: quality);
        compressedBytes = Uint8List.fromList(encoded);

        if (compressedBytes.length <= maxProfileSizeBytes) {
          break;
        }

        maxDimension = math.max(640, (maxDimension * 0.75).round());
        quality = math.max(55, quality - 10);
      }

      if (compressedBytes.length > maxProfileSizeBytes) {
        throw Exception('Photo is too large and could not be compressed below 3 MB. Please select a smaller photo.');
      }

      return ProcessedImageResult(
        bytes: compressedBytes,
        filename: '$baseName.jpg',
        mimeType: 'image/jpeg',
        byteSize: compressedBytes.length,
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to process image: $e');
    }
  }
}
