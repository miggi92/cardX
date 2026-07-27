import 'package:cardx/core/providers/storage_image_provider.dart';
import 'package:cardx/core/repositories/supabase_admin_repository.dart';
import 'package:cardx/features/admin/models/admin_access_request.dart';
import 'package:cardx/features/admin/models/admin_role_assignment.dart';
import 'package:cardx/features/admin/models/admin_sport.dart';
import 'package:cardx/features/admin/models/admin_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminRepoProvider = Provider<SupabaseAdminRepository>((ref) {
  return SupabaseAdminRepository(
    imageResolver: ref.watch(storageImageResolverProvider),
  );
});

final adminScopeProvider = FutureProvider<AdminScope>((ref) async {
  return ref.watch(adminRepoProvider).getMyAdminScope();
});

final hasAdminAccessProvider = Provider<bool>((ref) {
  return ref
      .watch(adminScopeProvider)
      .maybeWhen(data: (scope) => scope.canManagePlayers, orElse: () => false);
});

final adminPlayersByClubProvider =
    FutureProvider.family<List<AdminPlayer>, String>((ref, clubId) async {
      if (clubId.isEmpty) {
        return const [];
      }
      return ref.watch(adminRepoProvider).getPlayersForClub(clubId: clubId);
    });

final allClubsProvider = FutureProvider<List<Map<String, String>>>((ref) async {
  return ref.watch(adminRepoProvider).getAllClubs();
});

final myAdminAccessRequestsProvider = FutureProvider<List<AdminAccessRequest>>((
  ref,
) async {
  return ref.watch(adminRepoProvider).getMyAdminAccessRequests();
});

final pendingAdminAccessRequestsProvider =
    FutureProvider<List<AdminAccessRequest>>((ref) async {
      return ref.watch(adminRepoProvider).getPendingAdminAccessRequests();
    });

final clubAdminRoleAssignmentsProvider =
    FutureProvider<List<ClubAdminRoleAssignment>>((ref) async {
      return ref.watch(adminRepoProvider).listClubAdminRoles();
    });

final sportsProvider = FutureProvider<List<SportOption>>((ref) async {
  return ref.watch(adminRepoProvider).listSports();
});

final clubSportsProvider =
    FutureProvider.family<List<SportOption>, String>((ref, clubId) async {
      if (clubId.trim().isEmpty) {
        return const [];
      }
      return ref.watch(adminRepoProvider).listClubSports(clubId: clubId);
    });

final positionsBySportProvider =
    FutureProvider.family<List<PositionOption>, String>((ref, sportId) async {
      if (sportId.trim().isEmpty) {
        return const [];
      }
      return ref.watch(adminRepoProvider).listPositions(sportId: sportId);
    });

final leaguesBySportProvider =
    FutureProvider.family<List<LeagueOption>, String>((ref, sportId) async {
      if (sportId.trim().isEmpty) {
        return const [];
      }
      return ref.watch(adminRepoProvider).listLeagues(sportId: sportId);
    });

typedef ClubLeagueFilter = ({String clubId, String sportId, String seasonId});

final clubLeaguesProvider =
    FutureProvider.family<List<LeagueOption>, ClubLeagueFilter>((
      ref,
      filter,
    ) async {
      if (filter.clubId.trim().isEmpty || filter.sportId.trim().isEmpty) {
        return const [];
      }

      return ref
          .watch(adminRepoProvider)
          .listClubLeagues(
            clubId: filter.clubId,
            sportId: filter.sportId,
            seasonId: filter.seasonId,
          );
    });

final seasonsProvider = FutureProvider<List<SeasonOption>>((ref) async {
  return ref.watch(adminRepoProvider).listSeasons();
});

final pendingSportRequestsProvider = FutureProvider<List<SportRequest>>((
  ref,
) async {
  return ref.watch(adminRepoProvider).getPendingSportRequests();
});
