import 'dart:typed_data';

import 'package:cardx/core/providers/admin_provider.dart';
import 'package:cardx/features/admin/models/admin_access_request.dart';
import 'package:cardx/features/admin/models/admin_role_assignment.dart';
import 'package:cardx/features/admin/models/admin_scope.dart';
import 'package:cardx/features/admin/models/admin_sport.dart';
import 'package:cardx/features/admin/widgets/admin_action_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminDashboardActions {
  const AdminDashboardActions();

  Future<String> createPlayer({
    required WidgetRef ref,
    required String name,
    required String position,
    required String clubId,
    required String sport,
    required String season,
    Uint8List? imageBytes,
    String? imageExtension,
  }) {
    return ref
        .read(adminRepoProvider)
        .createPlayer(
          name: name,
          position: position,
          clubId: clubId,
          sport: sport,
          season: season,
          goals: 0,
          games: 0,
          imageBytes: imageBytes,
          imageExtension: imageExtension,
        );
  }

  Future<void> submitSportRequest({
    required WidgetRef ref,
    required String sportId,
    required String displayName,
    String? message,
  }) {
    return ref
        .read(adminRepoProvider)
        .submitSportRequest(
          sportId: sportId,
          displayName: displayName,
          message: message,
        );
  }

  Future<List<AdminUserOption>> searchUsersForRole({
    required WidgetRef ref,
    required String query,
  }) {
    return ref.read(adminRepoProvider).searchUsersForAdmin(query);
  }

  Future<void> assignClubAdminRole({
    required WidgetRef ref,
    required String userId,
    required String clubId,
    required bool canCreatePlayers,
    required bool canEditPlayers,
  }) {
    return ref
        .read(adminRepoProvider)
        .upsertClubAdminRole(
          userId: userId,
          clubId: clubId,
          canCreatePlayers: canCreatePlayers,
          canEditPlayers: canEditPlayers,
        );
  }

  Future<void> removeClubAdminRole({
    required WidgetRef ref,
    required String userId,
    required String clubId,
  }) {
    return ref
        .read(adminRepoProvider)
        .removeClubAdminRole(userId: userId, clubId: clubId);
  }

  Future<void> reviewSportRequest({
    required BuildContext context,
    required WidgetRef ref,
    required SportRequest request,
    required bool approve,
  }) async {
    final dialogResult = await showSportRequestReviewDialog(
      context,
      request,
      approve,
    );

    if (dialogResult == null) {
      return;
    }

    await ref
        .read(adminRepoProvider)
        .reviewSportRequest(
          requestId: request.id,
          approve: approve,
          decisionNote: dialogResult.decisionNote,
        );
  }

  Future<void> reviewAdminAccessRequest({
    required BuildContext context,
    required WidgetRef ref,
    required AdminScope scope,
    required AdminAccessRequest request,
    required bool approve,
  }) async {
    final dialogResult = await showAdminAccessRequestReviewDialog(
      context,
      scope,
      request,
      approve,
    );

    if (dialogResult == null) {
      return;
    }

    await ref
        .read(adminRepoProvider)
        .reviewAdminAccessRequest(
          requestId: request.id,
          approve: approve,
          decisionNote: dialogResult.decisionNote,
          createClubIfMissing: dialogResult.createClubIfMissing,
        );
  }

  Future<void> refreshAdminData({
    required WidgetRef ref,
    required String? selectedSeason,
    required String? selectedSport,
    required String? selectedClubId,
  }) async {
    ref.invalidate(adminScopeProvider);
    ref.invalidate(pendingAdminAccessRequestsProvider);
    ref.invalidate(pendingSportRequestsProvider);
    ref.invalidate(clubAdminRoleAssignmentsProvider);
    ref.invalidate(sportsProvider);
    if (selectedClubId != null) {
      ref.invalidate(clubSportsProvider(selectedClubId));
    }
    ref.invalidate(seasonsProvider);
    if (selectedSport != null) {
      ref.invalidate(positionsBySportProvider(selectedSport));
      ref.invalidate(leaguesBySportProvider(selectedSport));
      if (selectedClubId != null) {
        ref.invalidate(
          clubLeaguesProvider((
            clubId: selectedClubId,
            sportId: selectedSport,
            seasonId: selectedSeason ?? '',
          )),
        );
      }
    }
    if (selectedClubId != null) {
      ref.invalidate(adminPlayersByClubProvider(selectedClubId));
    }
  }
}
