import 'package:cardx/core/repositories/local_storage_image_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists resolved storage image metadata', () async {
    final preferences = await SharedPreferences.getInstance();
    final cache = LocalStorageImageCache(preferences);
    final image = CachedStorageImage(
      path: 'club-1.webp',
      url: 'https://example.com/club-1.webp',
      refreshAfter: DateTime.utc(2026, 8, 6),
      mimeType: 'image/webp',
    );

    await cache.set('public/club-logos/club-1', image);

    final restored = cache.get('public/club-logos/club-1');
    expect(restored?.path, image.path);
    expect(restored?.url, image.url);
    expect(restored?.refreshAfter, image.refreshAfter);
    expect(restored?.mimeType, image.mimeType);

    await cache.remove('public/club-logos/club-1');
    expect(cache.get('public/club-logos/club-1'), isNull);
  });

  test('ignores malformed cache entries', () async {
    SharedPreferences.setMockInitialValues({
      'storage_image_cache.v1.public/club-logos/club-1': '{invalid json',
    });
    final preferences = await SharedPreferences.getInstance();
    final cache = LocalStorageImageCache(preferences);

    expect(cache.get('public/club-logos/club-1'), isNull);
  });
}
