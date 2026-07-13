import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/cards/models/card_model.dart';
import '../../features/cards/models/card_rarity.dart';
import '../../features/cards/models/player_stats.dart';
import '../../features/shop/models/pack_model.dart';
import 'package:flutter/material.dart';

class SupabaseShopRepository {
  final _supabase = Supabase.instance.client;
  final Map<String, String> _resolvedImageUrlCache = {};

  static const _fallbackExtensions = ['png', 'jpg', 'jpeg', 'webp', 'svg'];

  Future<List<PackModel>> getAvailablePacks() async {
    final response = await _supabase.from('packs').select();
    final clubPacks = response
        .where((json) => json['type'] == PackType.club.name)
        .toList();

    final clubNames = clubPacks
        .map((json) => json['filter_value'] as String?)
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    final Map<String, String> clubLogoByName = {};
    if (clubNames.isNotEmpty) {
      final clubsResponse = await _supabase
          .from('clubs')
          .select('id, name')
          .inFilter('name', clubNames);

      for (final club in clubsResponse) {
        final clubName = club['name'] as String?;
        final clubId = club['id'];
        if (clubName != null && clubId != null) {
          clubLogoByName[clubName] = await _resolvePublicImageUrl(
            bucketName: 'club-logos',
            objectId: '$clubId',
          );
        }
      }
    }

    return response.map((json) {
      final List<dynamic> colorsList = json['gradient_colors'];
      final List<Color> colors = colorsList.map((hex) {
        final hexColor = hex.replaceAll('#', '');
        return Color(int.parse('FF$hexColor', radix: 16));
      }).toList();

      final type = PackType.values.byName(json['type'] as String);
      final filterValue = json['filter_value'] as String;

      return PackModel(
        id: json['id'],
        name: json['name'],
        price: json['price'],
        type: type,
        filterValue: filterValue,
        logoUrl: type == PackType.club ? clubLogoByName[filterValue] : null,
        gradientColors: colors,
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getFilteredPlayerPool(
    PackType type,
    String filterValue,
  ) async {
    if (type == PackType.club) {
      return await _supabase
          .from('player_pool')
          .select('*, clubs!inner(*)')
          .eq('clubs.name', filterValue);
    }

    final String column = type == PackType.sport ? 'sport' : 'league';
    return await _supabase
        .from('player_pool')
        .select('*, clubs(*)')
        .eq(column, filterValue);
  }

  Future<List<Map<String, dynamic>>> getAllPlayers() async {
    return await _supabase.from('player_pool').select('*, clubs(*)');
  }

  Future<List<CardModel>> generateRandomCardsFromFilteredPool(
    PackType type,
    String filterValue, {
    int count = 10,
  }) async {
    final filteredPool = await getFilteredPlayerPool(type, filterValue);
    return await _generateRandomCardsFromPool(filteredPool, count: count);
  }

  Future<List<CardModel>> generateRandomCardsFromAllPlayers({
    int count = 10,
  }) async {
    final allPlayers = await getAllPlayers();
    return await _generateRandomCardsFromPool(allPlayers, count: count);
  }

  Future<List<CardModel>> _generateRandomCardsFromPool(
    List<Map<String, dynamic>> playerPool, {
    required int count,
  }) async {
    final availablePlayers = playerPool
        .where((player) => player['clubs'] != null)
        .toList();

    if (availablePlayers.isEmpty) {
      return [];
    }

    final clubLogoById = <String, String>{};
    final playerImageById = <String, String>{};

    for (final player in availablePlayers) {
      final club = player['clubs'] as Map<String, dynamic>;
      final clubId = '${club['id']}';
      final playerId = '${player['id']}';

      if (!clubLogoById.containsKey(clubId)) {
        clubLogoById[clubId] = await _resolvePublicImageUrl(
          bucketName: 'club-logos',
          objectId: clubId,
        );
      }

      if (!playerImageById.containsKey(playerId)) {
        playerImageById[playerId] = await _resolvePublicImageUrl(
          bucketName: 'player-images',
          objectId: playerId,
        );
      }
    }

    final random = Random();
    final pulledCards = <CardModel>[];

    for (int i = 0; i < count; i++) {
      final player = availablePlayers[random.nextInt(availablePlayers.length)];
      final club = player['clubs'] as Map<String, dynamic>;
      final rarity = _rollRarity(random);

      pulledCards.add(
        CardModel(
          id: '${player['id']}_${rarity.name}',
          playerName: player['name'] as String,
          position: player['position'] as String,
          teamName: club['name'] as String,
          teamLogoUrl: clubLogoById['${club['id']}']!,
          playerImageUrl: playerImageById['${player['id']}']!,
          rarity: rarity,
          stats: PlayerStats(
            goals: (player['goals'] as num).toInt(),
            games: (player['games'] as num).toInt(),
          ),
          sport: (player['sport'] as String?) ?? '',
        ),
      );
    }

    return pulledCards;
  }

  Future<String> _resolvePublicImageUrl({
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
          var url = storage.getPublicUrl(preferred.name);
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
          var url = storage.getPublicUrl(path);
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

    final fallbackUrl = storage.getPublicUrl('$objectId.png');
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

  CardRarity _rollRarity(Random random) {
    final roll = random.nextDouble();

    if (roll < 0.05) {
      return CardRarity.legendary;
    }
    if (roll < 0.20) {
      return CardRarity.epic;
    }
    if (roll < 0.50) {
      return CardRarity.rare;
    }

    return CardRarity.common;
  }
}
