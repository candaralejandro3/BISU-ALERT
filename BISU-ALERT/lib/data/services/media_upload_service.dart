import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

// Re-exported so callers can say `ImageSource.camera` by importing this file
// alone, without also depending on image_picker directly.
export 'package:image_picker/image_picker.dart' show ImageSource;

/// Model for media file
class MediaFile {
  final String path;
  final String fileName;
  final MediaType type;
  final int fileSizeBytes;

  MediaFile({
    required this.path,
    required this.fileName,
    required this.type,
    required this.fileSizeBytes,
  });

  /// Check if file size is within limits (max 10MB)
  bool isValidSize() {
    const maxSizeBytes = 10 * 1024 * 1024; // 10MB
    return fileSizeBytes <= maxSizeBytes;
  }

  /// Get human-readable file size
  String getReadableSize() {
    if (fileSizeBytes < 1024) {
      return '${fileSizeBytes}B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(2)}KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)}MB';
    }
  }
}

enum MediaType { image, video, audio }

/// Media Upload Service -- wraps image_picker for incident photo/video evidence.
class MediaUploadService {
  static final MediaUploadService _instance = MediaUploadService._internal();

  factory MediaUploadService() {
    return _instance;
  }

  MediaUploadService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Max images a single report may attach.
  static const int maxImages = 5;

  /// Build a [MediaFile] from a picked file, reading its real size from disk.
  Future<MediaFile?> _toMediaFile(XFile? picked, MediaType type) async {
    if (picked == null) return null;
    try {
      final file = File(picked.path);
      final size = await file.length();
      return MediaFile(
        path: picked.path,
        fileName: picked.name,
        type: type,
        fileSizeBytes: size,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading picked file ${picked.path}: $e');
      }
      return null;
    }
  }

  /// Pick a single image from the gallery or camera.
  Future<MediaFile?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        // Downscale on device: keeps uploads small on poor campus connectivity.
        maxWidth: 1920,
        imageQuality: 85,
      );
      return _toMediaFile(picked, MediaType.image);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error picking image: $e');
      }
      return null;
    }
  }

  /// Pick a single video from the gallery or camera.
  Future<MediaFile?> pickVideo({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picked = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 2),
      );
      return _toMediaFile(picked, MediaType.video);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error picking video: $e');
      }
      return null;
    }
  }

  /// Pick multiple images from the gallery (capped at [maxImages]).
  Future<List<MediaFile>> pickMultipleImages() async {
    try {
      final picked = await _picker.pickMultiImage(
        maxWidth: 1920,
        imageQuality: 85,
      );

      final files = <MediaFile>[];
      for (final x in picked.take(maxImages)) {
        final media = await _toMediaFile(x, MediaType.image);
        if (media != null) files.add(media);
      }
      return files;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error picking multiple images: $e');
      }
      return [];
    }
  }

  /// Validate media file
  String? validateMediaFile(MediaFile file) {
    // Check file size
    if (!file.isValidSize()) {
      return 'File size exceeds 10MB limit. Current: ${file.getReadableSize()}';
    }

    // Check file exists
    if (!File(file.path).existsSync()) {
      return 'File not found: ${file.path}';
    }

    return null; // Valid
  }

  /// Delete local media file
  Future<bool> deleteLocalFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting file: $e');
      }
      return false;
    }
  }
}
