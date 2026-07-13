import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/cards/models/card_model.dart';
import '../../features/cards/models/card_rarity.dart';
import '../../features/cards/models/player_stats.dart';

class SupabaseCollectionRepository {
  final _supabase = Supabase.instance.client;
  final Map<String, String> _resolvedImageUrlCache = {};

  static const _fallbackExtensions = ['png', 'jpg', 'jpeg', 'webp', 'svg'];

  Future<List<CardModel>> getCards() async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from('user_cards')
        .select('*, player_pool(*, clubs(*))')
        .eq('user_id', userId);

    final cards = <CardModel>[];
    for (final json in response) {
      final player = json['player_pool'];
      final club = player['clubs'];

      final logoUrl = await _resolveImageUrl(
        bucketName: 'club-logos',
        objectId: '${club['id']}',
      );
      final playerImageUrl = await _resolveImageUrl(
        bucketName: 'player-logo',
        objectId: '${player['id']}',
      );

      final logicalCardId = '${player['id']}_${json['rarity']}';

      cards.add(
        CardModel(
          id: logicalCardId,
          playerName: player['name'],
          position: player['position'],
          teamName: club['name'],
          teamLogoUrl: logoUrl,
          playerImageUrl: playerImageUrl,
          rarity: CardRarity.values.byName(json['rarity']),
          stats: PlayerStats(goals: player['goals'], games: player['games']),
          sport: (player['sport'] as String?) ?? '',
        ),
      );
    }

    return cards;
  }

  Future<void> addCards(List<CardModel> cards) async {
    final userId = _supabase.auth.currentUser!.id;

    final insertData = cards
        .map(
          (card) => {
            'user_id': userId,
            'player_id': card.id.split('_')[0],
            'rarity': card.rarity.name,
          },
        )
        .toList();

    await _supabase.from('user_cards').insert(insertData);
  }

  Future<void> removeCard(String cardId) async {
    final userId = _supabase.auth.currentUser!.id;

    final targetPlayerId = cardId.split('_')[0];
    final targetRarity = cardId.split('_')[1];

    final response = await _supabase
        .from('user_cards')
        .select('id')
        .eq('user_id', userId)
        .eq('player_id', targetPlayerId)
        .eq('rarity', targetRarity)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      await _supabase.from('user_cards').delete().eq('id', response['id']);
    }
  }

  Future<void> syncCollection(List<CardModel> uniqueCards) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('user_cards').delete().eq('user_id', userId);
    if (uniqueCards.isNotEmpty) {
      await addCards(uniqueCards);
    }
  }

  Future<String> _resolveImageUrl({
    required String bucketName,
    required String objectId,
  }) async {
    final cacheKey = '$bucketName/$objectId';
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
          final mimeType = _mimeTypeOf(preferred);
          var url = bucketName == 'club-logos'
              ? storage.getPublicUrl(preferred.name)
              : await storage.createSignedUrl(preferred.name, 60 * 60 * 24);
          if (_isSvgMime(mimeType)) {
            url = _tagWithSvgMime(url);
          }
          _resolvedImageUrlCache[cacheKey] = url;
          return url;
        }
      }
    } catch (_) {
      // Fall back to extension probing below.
    }

    for (final extension in _fallbackExtensions) {
      final path = '$objectId.$extension';
      try {
        if (await storage.exists(path)) {
          var url = bucketName == 'club-logos'
              ? storage.getPublicUrl(path)
              : await storage.createSignedUrl(path, 60 * 60 * 24);
          if (extension == 'svg') {
            url = _tagWithSvgMime(url);
          }
          _resolvedImageUrlCache[cacheKey] = url;
          return url;
        }
      } catch (_) {
        // Fall through to next extension and keep a png fallback below.
      }
    }

    final fallbackUrl = bucketName == 'club-logos'
        ? storage.getPublicUrl('$objectId.png')
        : await storage.createSignedUrl('$objectId.png', 60 * 60 * 24);
    _resolvedImageUrlCache[cacheKey] = fallbackUrl;
    return fallbackUrl;
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
