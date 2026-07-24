import 'package:cardx/core/providers/storage_image_provider.dart';
import 'package:cardx/core/repositories/supabase_admin_repository.dart';
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
