import 'dart:typed_data';

import 'package:cardx/features/admin/models/admin_access_request.dart';
import 'package:cardx/features/admin/models/admin_role_assignment.dart';
import 'package:cardx/features/admin/models/admin_sport.dart';
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

  Future<List<Map<String, String>>> getAllClubs() async {
    final response = await _supabase
        .from('clubs')
        .select('id, name')
        .order('name');

    return response
        .map(
          (row) => {'id': '${row['id']}', 'name': row['name'] as String? ?? ''},
        )
        .toList();
  }

  Future<String> submitAdminAccessRequest({
    String? clubId,
    String? requestedClubName,
    String? message,
  }) async {
    final response = await _supabase.rpc(
      'submit_admin_access_request',
      params: {
        'p_club_id': clubId,
        'p_requested_club_name': requestedClubName,
        'p_message': message,
      },
    );

    return '$response';
  }

  Future<List<AdminAccessRequest>> getMyAdminAccessRequests() async {
    final response = await _supabase.rpc('get_my_admin_access_requests');
    return _mapRequests((response as List).cast<Map<String, dynamic>>());
  }

  Future<List<AdminAccessRequest>> getPendingAdminAccessRequests() async {
    final response = await _supabase.rpc('get_pending_admin_access_requests');
    return _mapRequests((response as List).cast<Map<String, dynamic>>());
  }

  Future<List<SportOption>> listSports() async {
    final response = await _supabase.rpc('list_sports');
    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => SportOption(
            id: row['id'] as String? ?? '',
            displayName:
                row['display_name'] as String? ?? row['id'] as String? ?? '',
          ),
        )
        .where((sport) => sport.id.isNotEmpty)
        .toList();
  }

  Future<List<PositionOption>> listPositions({required String sportId}) async {
    final normalized = sportId.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const [];
    }

    final response = await _supabase.rpc(
      'list_positions',
      params: {'p_sport': normalized},
    );

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => PositionOption(
            id: row['id'] as String? ?? '',
            displayName:
                row['display_name'] as String? ?? row['id'] as String? ?? '',
          ),
        )
        .where((position) => position.id.isNotEmpty)
        .toList();
  }

  Future<List<SeasonOption>> listSeasons() async {
    final response = await _supabase.rpc('list_seasons');

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => SeasonOption(
            id: row['id'] as String? ?? '',
            displayName:
                row['display_name'] as String? ?? row['id'] as String? ?? '',
            isActive: row['is_active'] == true,
          ),
        )
        .where((season) => season.id.isNotEmpty)
        .toList();
  }

  Future<List<LeagueOption>> listLeagues({required String sportId}) async {
    final normalized = sportId.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const [];
    }

    final response = await _supabase.rpc(
      'list_leagues',
      params: {'p_sport': normalized},
    );

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => LeagueOption(
            id: row['id'] as String? ?? '',
            displayName:
                row['display_name'] as String? ?? row['id'] as String? ?? '',
          ),
        )
        .where((league) => league.id.isNotEmpty)
        .toList();
  }

  Future<String> submitSportRequest({
    required String sportId,
    required String displayName,
    String? message,
  }) async {
    final response = await _supabase.rpc(
      'submit_sport_request',
      params: {
        'p_requested_sport_id': sportId,
        'p_requested_display_name': displayName,
        'p_message': message,
      },
    );

    return '$response';
  }

  Future<List<SportRequest>> getPendingSportRequests() async {
    final response = await _supabase.rpc('get_pending_sport_requests');
    return _mapSportRequests((response as List).cast<Map<String, dynamic>>());
  }

  Future<void> reviewSportRequest({
    required String requestId,
    required bool approve,
    String? decisionNote,
  }) async {
    await _supabase.rpc(
      'review_sport_request',
      params: {
        'p_request_id': requestId,
        'p_approve': approve,
        'p_decision_note': decisionNote,
      },
    );
  }

  Future<void> reviewAdminAccessRequest({
    required String requestId,
    required bool approve,
    String? decisionNote,
    bool createClubIfMissing = false,
  }) async {
    await _supabase.rpc(
      'review_admin_access_request',
      params: {
        'p_request_id': requestId,
        'p_approve': approve,
        'p_decision_note': decisionNote,
        'p_create_club_if_missing': createClubIfMissing,
      },
    );
  }

  Future<List<AdminUserOption>> searchUsersForAdmin(
    String query, {
    int limit = 20,
  }) async {
    final response = await _supabase.rpc(
      'list_users_for_admin',
      params: {'p_search': query, 'p_limit': limit},
    );

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => AdminUserOption(
            userId: '${row['user_id']}',
            email: row['email'] as String? ?? '(ohne E-Mail)',
          ),
        )
        .toList();
  }

  Future<List<ClubAdminRoleAssignment>> listClubAdminRoles() async {
    final response = await _supabase.rpc('list_club_admin_roles');

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => ClubAdminRoleAssignment(
            userId: '${row['user_id']}',
            email: row['email'] as String?,
            clubId: '${row['club_id']}',
            clubName: row['club_name'] as String? ?? '',
            canCreatePlayers: row['can_create_players'] == true,
            canEditPlayers: row['can_edit_players'] == true,
          ),
        )
        .toList();
  }

  Future<void> upsertClubAdminRole({
    required String userId,
    required String clubId,
    required bool canCreatePlayers,
    required bool canEditPlayers,
  }) async {
    await _supabase.rpc(
      'upsert_club_admin_role',
      params: {
        'p_user_id': userId,
        'p_club_id': clubId,
        'p_can_create_players': canCreatePlayers,
        'p_can_edit_players': canEditPlayers,
      },
    );
  }

  Future<void> removeClubAdminRole({
    required String userId,
    required String clubId,
  }) async {
    await _supabase.rpc(
      'remove_club_admin_role',
      params: {'p_user_id': userId, 'p_club_id': clubId},
    );
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

  List<AdminAccessRequest> _mapRequests(List<Map<String, dynamic>> rows) {
    return rows.map((row) {
      final createdAt =
          DateTime.tryParse('${row['created_at']}') ?? DateTime.now();
      final reviewedAtRaw = row['reviewed_at'];

      return AdminAccessRequest(
        id: '${row['id']}',
        requesterUserId: '${row['requester_user_id']}',
        clubId: row['club_id'] == null ? null : '${row['club_id']}',
        requestedClubName: row['requested_club_name'] as String? ?? '',
        message: row['message'] as String?,
        status: AdminAccessRequest.parseStatus('${row['status']}'),
        reviewedBy: row['reviewed_by'] == null ? null : '${row['reviewed_by']}',
        reviewedAt: reviewedAtRaw == null
            ? null
            : DateTime.tryParse('$reviewedAtRaw'),
        decisionNote: row['decision_note'] as String?,
        createdAt: createdAt,
        clubName: row['club_name'] as String?,
      );
    }).toList();
  }

  List<SportRequest> _mapSportRequests(List<Map<String, dynamic>> rows) {
    return rows.map((row) {
      return SportRequest(
        id: '${row['id']}',
        requesterUserId: '${row['requester_user_id']}',
        requestedSportId: row['requested_sport_id'] as String? ?? '',
        requestedDisplayName: row['requested_display_name'] as String? ?? '',
        message: row['message'] as String?,
        status: SportRequest.parseStatus('${row['status']}'),
        createdAt: DateTime.tryParse('${row['created_at']}') ?? DateTime.now(),
      );
    }).toList();
  }
}
