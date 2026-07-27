import 'package:cardx/core/providers/storage_image_provider.dart';
import 'package:cardx/features/admin/models/admin_access_request.dart';
import 'package:cardx/features/admin/models/admin_role_assignment.dart';
import 'package:cardx/features/admin/models/admin_scope.dart';
import 'package:cardx/features/admin/models/admin_sport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminScopeCard extends StatelessWidget {
  const AdminScopeCard({super.key, required this.scope});

  final AdminScope scope;

  @override
  Widget build(BuildContext context) {
    final roleLabel = scope.isGlobalAdmin ? 'Global Admin' : 'Vereinsadmin';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.admin_panel_settings_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$roleLabel - ${scope.clubs.length} Verein(e) im Zugriff',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminClubSelectorCard extends StatelessWidget {
  const AdminClubSelectorCard({
    super.key,
    required this.clubs,
    required this.selectedClubId,
    required this.onChanged,
    required this.imageResolver,
  });

  final List<AdminClubPermission> clubs;
  final String? selectedClubId;
  final ValueChanged<String?> onChanged;
  final SupabaseStorageImageResolver imageResolver;

  @override
  Widget build(BuildContext context) {
    AdminClubPermission? selectedClub;
    if (selectedClubId != null) {
      for (final club in clubs) {
        if (club.clubId == selectedClubId) {
          selectedClub = club;
          break;
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: clubs.any((club) => club.clubId == selectedClubId)
                  ? selectedClubId
                  : (clubs.isNotEmpty ? clubs.first.clubId : null),
              decoration: const InputDecoration(
                labelText: 'Verein',
                prefixIcon: Icon(Icons.shield_outlined),
              ),
              items: clubs
                  .map(
                    (club) => DropdownMenuItem<String>(
                      value: club.clubId,
                      child: Text(club.clubName),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
            if (selectedClub case final clubForPreview?) ...[
              const SizedBox(height: 10),
              FutureBuilder<String>(
                future: imageResolver.resolveImageUrl(
                  bucketName: 'club-logos',
                  objectId: clubForPreview.clubId,
                  isPublic: true,
                ),
                builder: (context, snapshot) {
                  final logoUrl = snapshot.data ?? '';
                  return Row(
                    children: [
                      if (logoUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.transparent,
                            backgroundImage: NetworkImage(logoUrl),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          clubForPreview.clubName,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AdminPendingRequestsSection extends StatelessWidget {
  const AdminPendingRequestsSection({
    super.key,
    required this.scope,
    required this.selectedClubId,
    required this.filterPendingBySelectedClub,
    required this.onFilterChanged,
    required this.requestsAsync,
    required this.onReviewRequest,
  });

  final AdminScope scope;
  final String? selectedClubId;
  final bool filterPendingBySelectedClub;
  final ValueChanged<bool> onFilterChanged;
  final AsyncValue<List<AdminAccessRequest>> requestsAsync;
  final Future<void> Function(AdminAccessRequest request, bool approve)
      onReviewRequest;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin-Anfragen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Vereinsadmins können nur Anfragen für bestehende Vereine genehmigen. '
              'Anfragen für noch nicht angelegte Vereine kann nur der Super-Admin genehmigen und dabei den Verein erstellen.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            FilterChip(
              label: const Text('Nur aktueller Verein'),
              selected: filterPendingBySelectedClub,
              onSelected: onFilterChanged,
            ),
            const SizedBox(height: 12),
            requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Text('Anfragen konnten nicht geladen werden: $error'),
              data: (requests) {
                final filtered = filterPendingBySelectedClub &&
                        selectedClubId != null
                    ? requests
                        .where((request) => request.clubId == selectedClubId)
                        .toList()
                    : requests;

                if (filtered.isEmpty) {
                  return const Text('Keine offenen Anfragen.');
                }

                return Column(
                  children: filtered.map((request) {
                    final canApproveMissingClub =
                        !request.isForMissingClub || scope.isGlobalAdmin;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.clubName ?? request.requestedClubName,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text('Anfragender User: ${request.requesterUserId}'),
                            if (request.message != null &&
                                request.message!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Nachricht: ${request.message!}'),
                            ],
                            if (request.isForMissingClub) ...[
                              const SizedBox(height: 6),
                              const Text(
                                'Verein existiert noch nicht. Nur Super-Admin kann mit Vereinsanlage genehmigen.',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.icon(
                                  onPressed: canApproveMissingClub
                                      ? () => onReviewRequest(request, true)
                                      : null,
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Genehmigen'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => onReviewRequest(
                                    request,
                                    false,
                                  ),
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text('Ablehnen'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AdminSportRequestSection extends StatelessWidget {
  const AdminSportRequestSection({
    super.key,
    required this.scope,
    required this.formKey,
    required this.sportIdController,
    required this.displayNameController,
    required this.messageController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final AdminScope scope;
  final GlobalKey<FormState> formKey;
  final TextEditingController sportIdController;
  final TextEditingController displayNameController;
  final TextEditingController messageController;
  final bool isSubmitting;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final canRequestSport =
        scope.isGlobalAdmin ||
        scope.clubs.any((club) => club.canCreatePlayers || club.canEditPlayers);

    if (!canRequestSport) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Neue Sportart beantragen',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Falls eine Sportart fehlt, kann sie hier beantragt werden. Ein Super-Admin kann sie dann genehmigen.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: sportIdController,
                validator: _requiredValidator,
                decoration: const InputDecoration(
                  labelText: 'Sport-ID (z. B. ice_hockey)',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: displayNameController,
                validator: _requiredValidator,
                decoration: const InputDecoration(
                  labelText: 'Anzeigename (z. B. Ice Hockey)',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: messageController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Begruendung (optional)',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isSubmitting ? null : onSubmit,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.addchart_outlined),
                  label: const Text('Sportart beantragen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pflichtfeld';
    }
    return null;
  }
}

class AdminPendingSportRequestsSection extends StatelessWidget {
  const AdminPendingSportRequestsSection({
    super.key,
    required this.pendingAsync,
    required this.onReviewRequest,
  });

  final AsyncValue<List<SportRequest>> pendingAsync;
  final Future<void> Function(SportRequest request, bool approve)
      onReviewRequest;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offene Sportart-Anfragen (Super-Admin)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            pendingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                'Sportart-Anfragen konnten nicht geladen werden: $error',
              ),
              data: (requests) {
                if (requests.isEmpty) {
                  return const Text('Keine offenen Sportart-Anfragen.');
                }

                return Column(
                  children: requests
                      .map(
                        (request) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${request.requestedDisplayName} (${request.requestedSportId})',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Anfragender User: ${request.requesterUserId}',
                                ),
                                if (request.message != null &&
                                    request.message!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('Nachricht: ${request.message}'),
                                ],
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    FilledButton.icon(
                                      onPressed: () => onReviewRequest(
                                        request,
                                        true,
                                      ),
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                      ),
                                      label: const Text('Genehmigen'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => onReviewRequest(
                                        request,
                                        false,
                                      ),
                                      icon: const Icon(Icons.cancel_outlined),
                                      label: const Text('Ablehnen'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AdminRoleManagementSection extends StatelessWidget {
  const AdminRoleManagementSection({
    super.key,
    required this.selectedClubId,
    required this.assignmentsAsync,
    required this.userSearchController,
    required this.isUserSearching,
    required this.userSearchResults,
    required this.selectedRoleUserId,
    required this.selectedRoleUserEmail,
    required this.roleCanCreatePlayers,
    required this.roleCanEditPlayers,
    required this.onSearchUsers,
    required this.onSelectUser,
    required this.onCreatePlayersChanged,
    required this.onEditPlayersChanged,
    required this.onAssignRole,
    required this.onRemoveRole,
  });

  final String? selectedClubId;
  final AsyncValue<List<ClubAdminRoleAssignment>> assignmentsAsync;
  final TextEditingController userSearchController;
  final bool isUserSearching;
  final List<AdminUserOption> userSearchResults;
  final String? selectedRoleUserId;
  final String? selectedRoleUserEmail;
  final bool roleCanCreatePlayers;
  final bool roleCanEditPlayers;
  final Future<void> Function() onSearchUsers;
  final ValueChanged<AdminUserOption> onSelectUser;
  final ValueChanged<bool> onCreatePlayersChanged;
  final ValueChanged<bool> onEditPlayersChanged;
  final Future<void> Function() onAssignRole;
  final Future<void> Function(ClubAdminRoleAssignment assignment) onRemoveRole;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rollenverwaltung (Super-Admin)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Vereinsadmins suchen und für den ausgewählten Verein zuweisen oder entfernen.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: userSearchController,
              decoration: const InputDecoration(
                labelText: 'User per E-Mail suchen',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: isUserSearching ? null : onSearchUsers,
                  icon: isUserSearching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_search_outlined),
                  label: const Text('User suchen'),
                ),
                const SizedBox(width: 8),
                if (selectedRoleUserEmail != null)
                  Expanded(
                    child: Text(
                      'Ausgewählt: $selectedRoleUserEmail',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            if (userSearchResults.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  itemCount: userSearchResults.length,
                  itemBuilder: (context, index) {
                    final user = userSearchResults[index];
                    final isSelected = selectedRoleUserId == user.userId;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.person_outline,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(user.email),
                      subtitle: Text(user.userId),
                      onTap: () => onSelectUser(user),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Darf erstellen'),
                  selected: roleCanCreatePlayers,
                  onSelected: onCreatePlayersChanged,
                ),
                FilterChip(
                  label: const Text('Darf bearbeiten'),
                  selected: roleCanEditPlayers,
                  onSelected: onEditPlayersChanged,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAssignRole,
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('Vereinsadmin zuweisen/aktualisieren'),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Bestehende Zuweisungen',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            assignmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Text('Rollen konnten nicht geladen werden: $error'),
              data: (assignments) {
                final scoped = selectedClubId == null
                    ? assignments
                    : assignments
                        .where((assignment) => assignment.clubId == selectedClubId)
                        .toList();

                if (scoped.isEmpty) {
                  return const Text(
                    'Keine Rollen fuer den aktuell ausgewaehlten Verein vorhanden.',
                  );
                }

                return Column(
                  children: scoped
                      .map(
                        (assignment) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(assignment.email ?? assignment.userId),
                          subtitle: Text(
                            '${assignment.clubName}\ncreate=${assignment.canCreatePlayers} edit=${assignment.canEditPlayers}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            onPressed: () => onRemoveRole(assignment),
                            icon: const Icon(Icons.remove_circle_outline),
                            tooltip: 'Rolle entziehen',
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AdminCreatePlayerCard extends StatelessWidget {
  const AdminCreatePlayerCard({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.sportsAsync,
    required this.positionsAsync,
    required this.leaguesAsync,
    required this.seasonsAsync,
    required this.selectedSport,
    required this.selectedPosition,
    required this.selectedLeague,
    required this.selectedSeason,
    required this.selectedImageName,
    required this.canCreate,
    required this.isSaving,
    required this.onSportChanged,
    required this.onPositionChanged,
    required this.onLeagueChanged,
    required this.onSeasonChanged,
    required this.onPickImage,
    required this.onCreatePlayer,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final AsyncValue<List<SportOption>> sportsAsync;
  final AsyncValue<List<PositionOption>> positionsAsync;
  final AsyncValue<List<LeagueOption>> leaguesAsync;
  final AsyncValue<List<SeasonOption>> seasonsAsync;
  final String? selectedSport;
  final String? selectedPosition;
  final String? selectedLeague;
  final String? selectedSeason;
  final String? selectedImageName;
  final bool canCreate;
  final bool isSaving;
  final ValueChanged<String?> onSportChanged;
  final ValueChanged<String?> onPositionChanged;
  final ValueChanged<String?> onLeagueChanged;
  final ValueChanged<String?> onSeasonChanged;
  final VoidCallback onPickImage;
  final Future<void> Function() onCreatePlayer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spieler anlegen',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildSmallField(
                    controller: nameController,
                    label: 'Name',
                    validator: _requiredValidator,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              sportsAsync.when(
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (error, _) =>
                    Text('Sportarten konnten nicht geladen werden: $error'),
                data: (sports) {
                  final isSelectedValid = sports.any(
                    (sport) => sport.id == selectedSport,
                  );

                  return DropdownButtonFormField<String>(
                    initialValue: isSelectedValid ? selectedSport : null,
                    decoration: const InputDecoration(
                      labelText: 'Sport',
                      prefixIcon: Icon(Icons.sports),
                    ),
                    items: sports
                        .map(
                          (sport) => DropdownMenuItem<String>(
                            value: sport.id,
                            child: Text(sport.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: onSportChanged,
                  );
                },
              ),
              const SizedBox(height: 12),
              if (selectedSport != null)
                leaguesAsync.when(
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (error, _) =>
                      Text('Ligen konnten nicht geladen werden: $error'),
                  data: (leagues) {
                    final isSelectedValid = leagues.any(
                      (league) => league.id == selectedLeague,
                    );

                    return DropdownButtonFormField<String>(
                      initialValue: isSelectedValid ? selectedLeague : null,
                      decoration: const InputDecoration(
                        labelText: 'Liga',
                        prefixIcon: Icon(Icons.emoji_events_outlined),
                      ),
                      items: leagues
                          .map(
                            (league) => DropdownMenuItem<String>(
                              value: league.id,
                              child: Text(league.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: onLeagueChanged,
                    );
                  },
                )
              else
                const Text(
                  'Bitte zuerst eine Sportart auswählen.',
                  style: TextStyle(color: Colors.orange),
                ),
              const SizedBox(height: 12),
              if (selectedSport != null)
                positionsAsync.when(
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (error, _) => Text(
                    'Positionen konnten nicht geladen werden: $error',
                  ),
                  data: (positions) {
                    final isSelectedValid = positions.any(
                      (position) => position.id == selectedPosition,
                    );

                    return DropdownButtonFormField<String>(
                      initialValue: isSelectedValid ? selectedPosition : null,
                      decoration: const InputDecoration(
                        labelText: 'Position',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                      items: positions
                          .map(
                            (position) => DropdownMenuItem<String>(
                              value: position.id,
                              child: Text(position.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: onPositionChanged,
                    );
                  },
                )
              else
                const Text(
                  'Bitte zuerst eine Sportart auswählen.',
                  style: TextStyle(color: Colors.orange),
                ),
              const SizedBox(height: 12),
              seasonsAsync.when(
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (error, _) =>
                    Text('Saisons konnten nicht geladen werden: $error'),
                data: (seasons) {
                  final isSelectedValid = seasons.any(
                    (season) => season.id == selectedSeason,
                  );

                  return DropdownButtonFormField<String>(
                    initialValue: isSelectedValid ? selectedSeason : null,
                    decoration: const InputDecoration(
                      labelText: 'Saison',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    items: seasons
                        .map(
                          (season) => DropdownMenuItem<String>(
                            value: season.id,
                            child: Text(
                              season.isActive
                                  ? '${season.displayName} (Aktiv)'
                                  : season.displayName,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: onSeasonChanged,
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: canCreate ? onPickImage : null,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Bild wählen'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedImageName ?? 'Kein Bild ausgewählt',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: canCreate && !isSaving ? onCreatePlayer : null,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_circle_outline),
                  label: const Text('Spieler speichern'),
                ),
              ),
              if (!canCreate) ...[
                const SizedBox(height: 10),
                const Text(
                  'Fuer diesen Verein hast du keine Rechte zum Erstellen von Spielern.',
                  style: TextStyle(color: Colors.orange),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      width: 260,
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, hintText: hintText),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pflichtfeld';
    }
    return null;
  }

}

class AdminPlayersSection extends StatelessWidget {
  const AdminPlayersSection({
    super.key,
    required this.playersAsync,
    required this.canEdit,
    required this.onEditPlayer,
  });

  final AsyncValue<List<AdminPlayer>> playersAsync;
  final bool canEdit;
  final Future<void> Function(AdminPlayer player) onEditPlayer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spieler in diesem Verein',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            playersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Text('Spieler konnten nicht geladen werden: $error'),
              data: (players) {
                if (players.isEmpty) {
                  return const Text('Noch keine Spieler vorhanden.');
                }

                return Column(
                  children: players
                      .map(
                        (player) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage: player.imageUrl.isNotEmpty
                                ? NetworkImage(player.imageUrl)
                                : null,
                            child: player.imageUrl.isEmpty
                                ? const Icon(Icons.person_outline)
                                : null,
                          ),
                          title: Text(player.name),
                          subtitle: Text(
                            '${player.position} | ${player.sport} | ${player.league} | ${player.season}\nTore: ${player.goals} | Spiele: ${player.games}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            onPressed: canEdit ? () => onEditPlayer(player) : null,
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Spieler bearbeiten',
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            if (!canEdit) ...[
              const SizedBox(height: 10),
              const Text(
                'Du kannst Spieler dieses Vereins anzeigen, aber nicht bearbeiten.',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }
}