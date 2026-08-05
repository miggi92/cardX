import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CachedStorageImage {
  const CachedStorageImage({
    required this.path,
    required this.url,
    required this.refreshAfter,
    this.mimeType,
  });

  final String path;
  final String url;
  final DateTime refreshAfter;
  final String? mimeType;

  factory CachedStorageImage.fromJson(Map<String, dynamic> json) {
    return CachedStorageImage(
      path: json['path'] as String,
      url: json['url'] as String,
      refreshAfter: DateTime.parse(json['refreshAfter'] as String),
      mimeType: json['mimeType'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'path': path,
    'url': url,
    'refreshAfter': refreshAfter.toIso8601String(),
    'mimeType': mimeType,
  };
}

class LocalStorageImageCache {
  LocalStorageImageCache(this._preferences);

  static const _keyPrefix = 'storage_image_cache.v1';

  final SharedPreferences _preferences;

  CachedStorageImage? get(String cacheKey) {
    final key = _key(cacheKey);
    final encoded = _preferences.getString(key);
    if (encoded == null) {
      return null;
    }

    try {
      return CachedStorageImage.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
    } catch (_) {
      _preferences.remove(key);
      return null;
    }
  }

  Future<void> set(String cacheKey, CachedStorageImage image) async {
    await _preferences.setString(_key(cacheKey), jsonEncode(image.toJson()));
  }

  Future<void> remove(String cacheKey) async {
    await _preferences.remove(_key(cacheKey));
  }

  String _key(String cacheKey) => '$_keyPrefix.$cacheKey';
}
