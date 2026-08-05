import 'package:cardx/core/providers/storage_image_provider.dart';
import 'package:cardx/core/repositories/local_storage_image_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('reuses a persisted public URL after resolver restart', () async {
    final now = DateTime.utc(2026, 8, 5, 12);
    final preferences = await SharedPreferences.getInstance();
    final cache = LocalStorageImageCache(preferences);
    await cache.set(
      'public/club-logos/club-1',
      CachedStorageImage(
        path: 'club-1.webp',
        url: 'https://example.com/club-1.webp',
        refreshAfter: now.add(const Duration(days: 1)),
        mimeType: 'image/webp',
      ),
    );
    final client = SupabaseClient(
      'https://example.com',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

    final firstResolver = SupabaseStorageImageResolver(
      supabase: client,
      preferences: preferences,
      now: () => now,
    );
    final secondResolver = SupabaseStorageImageResolver(
      supabase: client,
      preferences: preferences,
      now: () => now,
    );

    expect(
      await firstResolver.resolveImageUrl(
        bucketName: 'club-logos',
        objectId: 'club-1',
        isPublic: true,
      ),
      'https://example.com/club-1.webp',
    );
    expect(
      await secondResolver.resolveImageUrl(
        bucketName: 'club-logos',
        objectId: 'club-1',
        isPublic: true,
      ),
      'https://example.com/club-1.webp',
    );

    await secondResolver.invalidateImage(
      bucketName: 'club-logos',
      objectId: 'club-1',
      isPublic: true,
    );
    expect(cache.get('public/club-logos/club-1'), isNull);
  });
}
