import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final storageImageResolverProvider = Provider(
  (ref) => SupabaseStorageImageResolver(),
);

class SupabaseStorageImageResolver {
  SupabaseStorageImageResolver({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  final Map<String, String> _resolvedImageUrlCache = {};

  static const _fallbackExtensions = ['png', 'jpg', 'jpeg', 'webp', 'svg'];

  Future<String> resolveImageUrl({
    required String bucketName,
    required String objectId,
    required bool isPublic,
    int signedUrlLifetimeSeconds = 60 * 60 * 24,
  }) async {
    final cacheKey = '$bucketName/$objectId/$isPublic';
    final cachedUrl = _resolvedImageUrlCache[cacheKey];
    if (cachedUrl != null) {
      return cachedUrl;
    }

    final storage = _supabase.storage.from(bucketName);

    try {
      final files = await storage.list(
        searchOptions: SearchOptions(limit: 50, search: objectId),
      );

      final matchingFiles = files
          .where((file) => _matchesObjectId(file.name, objectId))
          .toList();

      if (matchingFiles.isNotEmpty) {
        final preferred = _pickBestImageCandidate(matchingFiles);
        if (preferred != null) {
          final resolvedUrl = await _buildUrl(
            storage: storage,
            path: preferred.name,
            isPublic: isPublic,
            mimeType: _mimeTypeOf(preferred),
            signedUrlLifetimeSeconds: signedUrlLifetimeSeconds,
          );
          if (resolvedUrl.isNotEmpty) {
            _resolvedImageUrlCache[cacheKey] = resolvedUrl;
          }
          return resolvedUrl;
        }
      }
    } catch (_) {
      // Fall back to extension probing below.
    }

    for (final extension in _fallbackExtensions) {
      final path = '$objectId.$extension';
      try {
        if (await storage.exists(path)) {
          final resolvedUrl = await _buildUrl(
            storage: storage,
            path: path,
            isPublic: isPublic,
            mimeType: extension == 'svg' ? 'image/svg+xml' : null,
            signedUrlLifetimeSeconds: signedUrlLifetimeSeconds,
          );
          if (resolvedUrl.isNotEmpty) {
            _resolvedImageUrlCache[cacheKey] = resolvedUrl;
          }
          return resolvedUrl;
        }
      } catch (_) {
        // Fall through to next extension.
      }
    }

    // Cache misses as empty strings to avoid repeated expensive lookups.
    _resolvedImageUrlCache[cacheKey] = '';
    return '';
  }

  Future<String> _buildUrl({
    required StorageFileApi storage,
    required String path,
    required bool isPublic,
    required int signedUrlLifetimeSeconds,
    String? mimeType,
  }) async {
    try {
      var url = isPublic
          ? storage.getPublicUrl(path)
          : await storage.createSignedUrl(path, signedUrlLifetimeSeconds);

      if (_isSvgMime(mimeType)) {
        url = _tagWithSvgMime(url);
      }

      return url;
    } on StorageException catch (error) {
      if (error.statusCode == '404' || error.error == 'not_found') {
        return '';
      }
      rethrow;
    }
  }

  bool _matchesObjectId(String fileName, String objectId) {
    final normalizedFileName = fileName.toLowerCase();
    final normalizedObjectId = objectId.toLowerCase();
    return normalizedFileName == normalizedObjectId ||
        normalizedFileName.startsWith('$normalizedObjectId.');
  }

  FileObject? _pickBestImageCandidate(List<FileObject> candidates) {
    for (final file in candidates) {
      final mimeType = _mimeTypeOf(file);
      if (_isSupportedImageMime(mimeType)) {
        return file;
      }
    }

    for (final file in candidates) {
      final lowerName = file.name.toLowerCase();
      if (_fallbackExtensions.any((ext) => lowerName.endsWith('.$ext'))) {
        return file;
      }
    }

    return null;
  }

  String? _mimeTypeOf(FileObject file) {
    final mime = file.metadata?['mimetype'];
    return mime is String ? mime.toLowerCase() : null;
  }

  bool _isSupportedImageMime(String? mimeType) {
    return mimeType != null && mimeType.startsWith('image/');
  }

  bool _isSvgMime(String? mimeType) {
    return mimeType == 'image/svg+xml';
  }

  String _tagWithSvgMime(String url) {
    final uri = Uri.parse(url);
    return uri.replace(fragment: 'mime=image/svg+xml').toString();
  }
}
