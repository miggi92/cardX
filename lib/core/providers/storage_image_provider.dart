import 'package:cardx/core/repositories/local_storage_image_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final storageImageResolverProvider = Provider(
  (ref) => SupabaseStorageImageResolver(),
);

class SupabaseStorageImageResolver {
  SupabaseStorageImageResolver({
    SupabaseClient? supabase,
    SharedPreferences? preferences,
    DateTime Function()? now,
  }) : _supabase = supabase ?? Supabase.instance.client,
       _persistentCache = preferences == null
           ? SharedPreferences.getInstance().then(LocalStorageImageCache.new)
           : Future.value(LocalStorageImageCache(preferences)),
       _now = now ?? DateTime.now;

  final SupabaseClient _supabase;
  final Future<LocalStorageImageCache> _persistentCache;
  final DateTime Function() _now;
  final Map<String, CachedStorageImage> _resolvedImageCache = {};
  final Map<String, Future<String>> _inFlightResolutions = {};

  static const _fallbackExtensions = ['png', 'jpg', 'jpeg', 'webp', 'svg'];
  static const _publicCacheLifetime = Duration(days: 7);
  static const _missingImageCacheLifetime = Duration(hours: 1);
  static const _signedUrlRefreshMargin = Duration(minutes: 5);

  Future<String> resolveImageUrl({
    required String bucketName,
    required String objectId,
    required bool isPublic,
    int signedUrlLifetimeSeconds = 60 * 60 * 24,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    final cacheKey = _cacheKey(
      bucketName: bucketName,
      objectId: objectId,
      isPublic: isPublic,
      userId: userId,
    );
    final cachedImage = _resolvedImageCache[cacheKey];
    if (cachedImage != null && cachedImage.refreshAfter.isAfter(_now())) {
      return cachedImage.url;
    }

    final inFlightResolution = _inFlightResolutions[cacheKey];
    if (inFlightResolution != null) {
      return inFlightResolution;
    }

    final persistentCacheKey = isPublic || userId != null ? cacheKey : null;
    final resolution = _resolveImageUrl(
      cacheKey: cacheKey,
      persistentCacheKey: persistentCacheKey,
      bucketName: bucketName,
      objectId: objectId,
      isPublic: isPublic,
      signedUrlLifetimeSeconds: signedUrlLifetimeSeconds,
    );
    _inFlightResolutions[cacheKey] = resolution;

    try {
      return await resolution;
    } finally {
      if (identical(_inFlightResolutions[cacheKey], resolution)) {
        _inFlightResolutions.remove(cacheKey);
      }
    }
  }

  Future<void> invalidateImage({
    required String bucketName,
    required String objectId,
    required bool isPublic,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    final cacheKey = _cacheKey(
      bucketName: bucketName,
      objectId: objectId,
      isPublic: isPublic,
      userId: userId,
    );
    final inFlightResolution = _inFlightResolutions[cacheKey];
    if (inFlightResolution != null) {
      try {
        await inFlightResolution;
      } catch (_) {
        // The stale entry still needs to be removed after a failed lookup.
      }
    }

    _resolvedImageCache.remove(cacheKey);
    if (isPublic || userId != null) {
      try {
        await (await _persistentCache).remove(cacheKey);
      } catch (_) {
        // Image uploads should succeed if browser storage is unavailable.
      }
    }
  }

  Future<String> _resolveImageUrl({
    required String cacheKey,
    required String? persistentCacheKey,
    required String bucketName,
    required String objectId,
    required bool isPublic,
    required int signedUrlLifetimeSeconds,
  }) async {
    final storage = _supabase.storage.from(bucketName);
    final persistedImage = persistentCacheKey == null
        ? null
        : await _readPersistentCache(persistentCacheKey);

    if (persistedImage != null) {
      _resolvedImageCache[cacheKey] = persistedImage;
      if (persistedImage.refreshAfter.isAfter(_now())) {
        return persistedImage.url;
      }

      if (!isPublic && persistedImage.path.isNotEmpty) {
        try {
          final refreshedUrl = await _buildUrl(
            storage: storage,
            path: persistedImage.path,
            isPublic: false,
            mimeType: persistedImage.mimeType,
            signedUrlLifetimeSeconds: signedUrlLifetimeSeconds,
          );
          if (refreshedUrl.isNotEmpty) {
            await _cacheResolvedImage(
              cacheKey: cacheKey,
              persistentCacheKey: persistentCacheKey,
              path: persistedImage.path,
              url: refreshedUrl,
              mimeType: persistedImage.mimeType,
              isPublic: false,
              signedUrlLifetimeSeconds: signedUrlLifetimeSeconds,
            );
            return refreshedUrl;
          }
        } catch (_) {
          // The object may have been replaced with a different extension.
        }
      }
    }

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
            await _cacheResolvedImage(
              cacheKey: cacheKey,
              persistentCacheKey: persistentCacheKey,
              path: preferred.name,
              url: resolvedUrl,
              mimeType: _mimeTypeOf(preferred),
              isPublic: isPublic,
              signedUrlLifetimeSeconds: signedUrlLifetimeSeconds,
            );
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
            await _cacheResolvedImage(
              cacheKey: cacheKey,
              persistentCacheKey: persistentCacheKey,
              path: path,
              url: resolvedUrl,
              mimeType: extension == 'svg' ? 'image/svg+xml' : null,
              isPublic: isPublic,
              signedUrlLifetimeSeconds: signedUrlLifetimeSeconds,
            );
          }
          return resolvedUrl;
        }
      } catch (_) {
        // Fall through to next extension.
      }
    }

    await _cacheResolvedImage(
      cacheKey: cacheKey,
      persistentCacheKey: persistentCacheKey,
      path: '',
      url: '',
      isPublic: isPublic,
      signedUrlLifetimeSeconds: signedUrlLifetimeSeconds,
    );
    return '';
  }

  Future<CachedStorageImage?> _readPersistentCache(String cacheKey) async {
    try {
      return (await _persistentCache).get(cacheKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheResolvedImage({
    required String cacheKey,
    required String? persistentCacheKey,
    required String path,
    required String url,
    required bool isPublic,
    required int signedUrlLifetimeSeconds,
    String? mimeType,
  }) async {
    final image = CachedStorageImage(
      path: path,
      url: url,
      mimeType: mimeType,
      refreshAfter: _refreshAfter(
        url: url,
        isPublic: isPublic,
        signedUrlLifetimeSeconds: signedUrlLifetimeSeconds,
      ),
    );
    _resolvedImageCache[cacheKey] = image;

    if (persistentCacheKey == null) {
      return;
    }

    try {
      await (await _persistentCache).set(persistentCacheKey, image);
    } catch (_) {
      // Image loading should still work if browser storage is unavailable.
    }
  }

  DateTime _refreshAfter({
    required String url,
    required bool isPublic,
    required int signedUrlLifetimeSeconds,
  }) {
    if (url.isEmpty) {
      return _now().add(_missingImageCacheLifetime);
    }
    if (isPublic) {
      return _now().add(_publicCacheLifetime);
    }

    final lifetime = Duration(seconds: signedUrlLifetimeSeconds);
    final refreshLifetime = lifetime > _signedUrlRefreshMargin
        ? lifetime - _signedUrlRefreshMargin
        : lifetime;
    return _now().add(refreshLifetime);
  }

  String _cacheKey({
    required String bucketName,
    required String objectId,
    required bool isPublic,
    required String? userId,
  }) {
    final scope = isPublic ? 'public' : userId ?? 'anonymous';
    return '$scope/$bucketName/$objectId';
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
