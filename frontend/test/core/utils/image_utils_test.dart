import 'dart:io';
import 'dart:typed_data';
import 'package:civicpulse_frontend/core/utils/image_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

void main() {
  group('ImageUtils Profile Image Processing Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('image_utils_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Preserves JPG/JPEG file format and assigns image/jpeg MIME type', () async {
      final sampleBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
      final file = File('${tempDir.path}/avatar.jpg');
      await file.writeAsBytes(sampleBytes);
      final xFile = XFile(file.path);

      final result = await ImageUtils.processProfileImage(xFile);

      expect(result.mimeType, 'image/jpeg');
      expect(result.filename, 'avatar.jpg');
      expect(result.bytes, equals(sampleBytes));
      expect(result.byteSize, sampleBytes.length);
    });

    test('Preserves PNG file format and assigns image/png MIME type', () async {
      final sampleBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      final file = File('${tempDir.path}/user_profile.png');
      await file.writeAsBytes(sampleBytes);
      final xFile = XFile(file.path);

      final result = await ImageUtils.processProfileImage(xFile);

      expect(result.mimeType, 'image/png');
      expect(result.filename, 'user_profile.png');
      expect(result.bytes, equals(sampleBytes));
      expect(result.byteSize, sampleBytes.length);
    });

    test('Normalizes JPEG extension to .jpg and image/jpeg', () async {
      final sampleBytes = Uint8List.fromList([0xFF, 0xD8, 1, 2, 3]);
      final file = File('${tempDir.path}/camera_shot.jpeg');
      await file.writeAsBytes(sampleBytes);
      final xFile = XFile(file.path);

      final result = await ImageUtils.processProfileImage(xFile);

      expect(result.mimeType, 'image/jpeg');
      expect(result.filename, 'camera_shot.jpg');
    });

    test('Throws friendly exception on empty image data', () async {
      final emptyBytes = Uint8List(0);
      final xFile = XFile.fromData(emptyBytes, name: 'empty.jpg');

      expect(
        () => ImageUtils.processProfileImage(xFile),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Selected image is empty'))),
      );
    });

    test('Compresses oversized photo (> 3 MB) as JPEG safely below 3 MB limit', () async {
      // Create a large image (> 3 MB)
      final largeImage = img.Image(width: 2000, height: 2000);
      // Fill with varied pixels so it doesn't compress away to nothing
      for (int y = 0; y < 2000; y += 10) {
        for (int x = 0; x < 2000; x += 10) {
          largeImage.setPixelRgb(x, y, (x * 7) % 256, (y * 13) % 256, ((x + y) * 17) % 256);
        }
      }
      final rawPng = img.encodePng(largeImage);
      // If needed, pad to ensure it strictly exceeds 3 MB
      final targetSize = 3 * 1024 * 1024 + 10000;
      Uint8List oversizedBytes;
      if (rawPng.length < targetSize) {
        // Encode as uncompressed BMP or pad bytes
        final bmp = img.encodeBmp(largeImage);
        oversizedBytes = bmp.length > targetSize ? bmp : Uint8List.fromList([...bmp, ...List.filled(targetSize - bmp.length, 0)]);
      } else {
        oversizedBytes = rawPng;
      }

      final file = File('${tempDir.path}/large_photo.png');
      await file.writeAsBytes(oversizedBytes);
      final xFile = XFile(file.path);

      final result = await ImageUtils.processProfileImage(xFile);

      // Verify strict client-side 3 MB limit
      expect(result.byteSize, lessThanOrEqualTo(ImageUtils.maxProfileSizeBytes));
      expect(result.mimeType, 'image/jpeg');
      expect(result.filename, 'large_photo.jpg');

      // Verify the resulting bytes are a valid JPEG
      final decodedResult = img.decodeJpg(result.bytes);
      expect(decodedResult, isNotNull);
      expect(decodedResult!.width, lessThanOrEqualTo(1600));
    });
  });
}
