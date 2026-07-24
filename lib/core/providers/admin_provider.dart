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

final positionsBySportProvider =
    FutureProvider.family<List<PositionOption>, String>((ref, sportId) async {
      if (sportId.trim().isEmpty) {
        return const [];
      }
      return ref.watch(adminRepoProvider).listPositions(sportId: sportId);
    });

final pendingSportRequestsProvider = FutureProvider<List<SportRequest>>((
  ref,
) async {
  return ref.watch(adminRepoProvider).getPendingSportRequests();
});
