import 'dart:typed_data';

import 'package:cardx/core/providers/storage_image_provider.dart';
import 'package:cardx/features/admin/models/admin_scope.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAdminRepository {
  SupabaseAdminRepository({
    required SupabaseStorageImageResolver imageResolver,
    SupabaseClient? supabase,
  }) : _supabase = supabase ?? Supabase.instance.client,
       _imageResolver = imageResolver;

  final SupabaseClient _supabase;
  final SupabaseStorageImageResolver _imageResolver;

  Future<AdminScope> getMyAdminScope() async {
    final response = await _supabase.rpc('get_my_admin_scope');
    final rows = (response as List).cast<Map<String, dynamic>>();

    if (rows.isEmpty) {
      final isGlobalAdminRaw = await _supabase.rpc('is_global_admin');
      final isGlobalAdmin = isGlobalAdminRaw == true;
      return AdminScope(isGlobalAdmin: isGlobalAdmin, clubs: const []);
    }

    final clubs = <AdminClubPermission>[];
    var isGlobalAdmin = false;

    for (final row in rows) {
      isGlobalAdmin = isGlobalAdmin || (row['is_global_admin'] == true);
      final clubId = row['club_id'];
      final clubName = row['club_name'] as String?;
      if (clubId == null || clubName == null) {
        continue;
      }

      clubs.add(
        AdminClubPermission(
          clubId: '$clubId',
          clubName: clubName,
          canCreatePlayers: row['can_create_players'] == true,
          canEditPlayers: row['can_edit_players'] == true,
        ),
      );
    }

    return AdminScope(isGlobalAdmin: isGlobalAdmin, clubs: clubs);
  }

  Future<List<AdminPlayer>> getPlayersForClub({required String clubId}) async {
    final response = await _supabase
        .from('player_pool')
        .select(
          'id, name, position, sport, league, season, club_id, clubs(id, name), player_stats(goals, games)',
        )
        .eq('club_id', clubId)
        .order('name');

    final players = <AdminPlayer>[];

    for (final row in response) {
      final club = row['clubs'] as Map<String, dynamic>?;
      final stats = _readStats(row['player_stats']);
      final playerId = '${row['id']}';
      final imageUrl = await _imageResolver.resolveImageUrl(
        bucketName: 'player-images',
        objectId: playerId,
        isPublic: false,
      );

      players.add(
        AdminPlayer(
          id: playerId,
          name: row['name'] as String? ?? '',
          position: row['position'] as String? ?? '',
          clubId: '${row['club_id']}',
          clubName: club?['name'] as String? ?? '',
          sport: row['sport']?.toString() ?? '',
          league: row['league'] as String? ?? '',
          season: row['season'] as String? ?? '',
          goals: stats.$1,
          games: stats.$2,
          imageUrl: imageUrl,
        ),
      );
    }

    return players;
  }

  Future<String> createPlayer({
    required String name,
    required String position,
    required String clubId,
    required String sport,
    required String league,
    required String season,
    required int goals,
    required int games,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    final playerId = await _supabase.rpc(
      'create_player_with_stats',
      params: {
        'p_name': name,
        'p_position': position,
        'p_club_id': clubId,
        'p_sport': sport,
        'p_league': league,
        'p_season': season,
        'p_goals': goals,
        'p_games': games,
      },
    );

    final createdId = '$playerId';

    if (imageBytes != null && imageBytes.isNotEmpty) {
      await _uploadPlayerImage(
        playerId: createdId,
        imageBytes: imageBytes,
        imageExtension: imageExtension,
      );
    }

    return createdId;
  }

  Future<void> updatePlayer({
    required String playerId,
    required String name,
    required String position,
    required String clubId,
    required String sport,
    required String league,
    required String season,
    required int goals,
    required int games,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    await _supabase.rpc(
      'update_player_with_stats',
      params: {
        'p_player_id': playerId,
        'p_name': name,
        'p_position': position,
        'p_club_id': clubId,
        'p_sport': sport,
        'p_league': league,
        'p_season': season,
        'p_goals': goals,
        'p_games': games,
      },
    );

    if (imageBytes != null && imageBytes.isNotEmpty) {
      await _uploadPlayerImage(
        playerId: playerId,
        imageBytes: imageBytes,
        imageExtension: imageExtension,
      );
    }
  }

  Future<void> _uploadPlayerImage({
    required String playerId,
    required Uint8List imageBytes,
    String? imageExtension,
  }) async {
    final bucket = _supabase.storage.from('player-images');
    final extension = _normalizeExtension(imageExtension);

    await _deleteExistingPlayerImages(bucket: bucket, playerId: playerId);

    final objectPath = '$playerId.$extension';
    await bucket.uploadBinary(
      objectPath,
      imageBytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: _contentTypeForExtension(extension),
      ),
    );
  }

  Future<void> _deleteExistingPlayerImages({
    required StorageFileApi bucket,
    required String playerId,
  }) async {
    final existing = await bucket.list(
      searchOptions: SearchOptions(limit: 20, search: playerId),
    );

    final matches = existing
        .where((file) {
          final lower = file.name.toLowerCase();
          final prefix = playerId.toLowerCase();
          return lower == prefix || lower.startsWith('$prefix.');
        })
        .map((file) => file.name)
        .toList();

    if (matches.isNotEmpty) {
      await bucket.remove(matches);
    }
  }

  String _normalizeExtension(String? extension) {
    final value = (extension ?? '').toLowerCase().replaceAll('.', '');
    const allowed = {'png', 'jpg', 'jpeg', 'webp'};
    if (allowed.contains(value)) {
      return value;
    }
    return 'jpg';
  }

  String _contentTypeForExtension(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };
  }

  (int, int) _readStats(dynamic rawStats) {
    if (rawStats is List && rawStats.isNotEmpty && rawStats.first is Map) {
      final first = rawStats.first as Map;
      final goals = (first['goals'] as num?)?.toInt() ?? 0;
      final games = (first['games'] as num?)?.toInt() ?? 0;
      return (goals, games);
    }

    if (rawStats is Map<String, dynamic>) {
      final goals = (rawStats['goals'] as num?)?.toInt() ?? 0;
      final games = (rawStats['games'] as num?)?.toInt() ?? 0;
      return (goals, games);
    }

    return (0, 0);
  }
}
