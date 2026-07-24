import 'dart:typed_data';

import 'package:cardx/core/providers/admin_provider.dart';
import 'package:cardx/features/admin/models/admin_access_request.dart';
import 'package:cardx/features/admin/models/admin_role_assignment.dart';
import 'package:cardx/features/admin/models/admin_scope.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _createFormKey = GlobalKey<FormState>();
  final _userSearchController = TextEditingController();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _leagueController = TextEditingController();
  final _seasonController = TextEditingController(text: _defaultSeason());
  final _goalsController = TextEditingController(text: '0');
  final _gamesController = TextEditingController(text: '0');

  String _selectedSport = 'soccer';
  String? _selectedClubId;
  String? _selectedRoleUserId;
  String? _selectedRoleUserEmail;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isSaving = false;
  bool _isRoleSaving = false;
  bool _isUserSearching = false;
  bool _roleCanCreatePlayers = true;
  bool _roleCanEditPlayers = true;
  List<AdminUserOption> _userSearchResults = const [];

  static String _defaultSeason() {
    final now = DateTime.now();
    final startYear = now.month >= 7 ? now.year : now.year - 1;
    final endShort = ((startYear + 1) % 100).toString().padLeft(2, '0');
    return '$startYear/$endShort';
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    _nameController.dispose();
    _positionController.dispose();
    _leagueController.dispose();
    _seasonController.dispose();
    _goalsController.dispose();
    _gamesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminScopeAsync = ref.watch(adminScopeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: adminScopeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Adminrechte konnten nicht geladen werden: $error'),
          ),
        ),
        data: (scope) => _buildBody(context, scope),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AdminScope scope) {
    if (!scope.canManagePlayers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Du hast keine Admin-Berechtigung, um Spieler zu erstellen oder zu bearbeiten.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final manageableClubs = scope.clubs
        .where(
          (club) =>
              club.canCreatePlayers ||
              club.canEditPlayers ||
              scope.isGlobalAdmin,
        )
        .toList();

    if (manageableClubs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Es sind keine Vereine mit Bearbeitungsrechten hinterlegt.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    _selectedClubId ??= manageableClubs.first.clubId;
    final selectedPermission = scope.permissionForClub(_selectedClubId ?? '');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminScopeProvider);
        ref.invalidate(pendingAdminAccessRequestsProvider);
        ref.invalidate(clubAdminRoleAssignmentsProvider);
        if (_selectedClubId != null) {
          ref.invalidate(adminPlayersByClubProvider(_selectedClubId!));
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildScopeCard(scope),
          const SizedBox(height: 12),
          _buildPendingRequestsSection(context, scope),
          if (scope.isGlobalAdmin) ...[
            const SizedBox(height: 12),
            _buildRoleManagementSection(context),
          ],
          const SizedBox(height: 12),
          _buildClubSelector(manageableClubs),
          const SizedBox(height: 12),
          _buildCreateCard(context, scope, selectedPermission),
          const SizedBox(height: 16),
          _buildPlayersSection(context, scope, selectedPermission),
        ],
      ),
    );
  }

  Widget _buildScopeCard(AdminScope scope) {
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

  Widget _buildClubSelector(List<AdminClubPermission> clubs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          initialValue: _selectedClubId,
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
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _selectedClubId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPendingRequestsSection(BuildContext context, AdminScope scope) {
    final requestsAsync = ref.watch(pendingAdminAccessRequestsProvider);

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
              'Vereinsadmins koennen nur Anfragen fuer bestehende Vereine genehmigen. '
              'Anfragen fuer noch nicht angelegte Vereine kann nur der Super-Admin genehmigen und dabei den Verein erstellen.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Text('Anfragen konnten nicht geladen werden: $error'),
              data: (requests) {
                if (requests.isEmpty) {
                  return const Text('Keine offenen Anfragen.');
                }

                return Column(
                  children: requests.map((request) {
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
                            Text(
                              'Anfragender User: ${request.requesterUserId}',
                            ),
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
                                      ? () => _reviewRequest(
                                          scope: scope,
                                          request: request,
                                          approve: true,
                                        )
                                      : null,
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Genehmigen'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _reviewRequest(
                                    scope: scope,
                                    request: request,
                                    approve: false,
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

  Widget _buildRoleManagementSection(BuildContext context) {
    final selectedClubId = _selectedClubId;
    final assignmentsAsync = ref.watch(clubAdminRoleAssignmentsProvider);

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
              'Vereinsadmins suchen und fuer den ausgewaehlten Verein zuweisen oder entfernen.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userSearchController,
              decoration: const InputDecoration(
                labelText: 'User per E-Mail suchen',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _isUserSearching ? null : _searchUsersForRole,
                  icon: _isUserSearching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_search_outlined),
                  label: const Text('User suchen'),
                ),
                const SizedBox(width: 8),
                if (_selectedRoleUserEmail != null)
                  Expanded(
                    child: Text(
                      'Ausgewaehlt: $_selectedRoleUserEmail',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            if (_userSearchResults.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  itemCount: _userSearchResults.length,
                  itemBuilder: (context, index) {
                    final user = _userSearchResults[index];
                    final isSelected = _selectedRoleUserId == user.userId;
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
                      onTap: () {
                        setState(() {
                          _selectedRoleUserId = user.userId;
                          _selectedRoleUserEmail = user.email;
                        });
                      },
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
                  selected: _roleCanCreatePlayers,
                  onSelected: (value) {
                    setState(() {
                      _roleCanCreatePlayers = value;
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Darf bearbeiten'),
                  selected: _roleCanEditPlayers,
                  onSelected: (value) {
                    setState(() {
                      _roleCanEditPlayers = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isRoleSaving ? null : _assignClubAdminRole,
                icon: _isRoleSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.admin_panel_settings_outlined),
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
                          .where(
                            (assignment) => assignment.clubId == selectedClubId,
                          )
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
                            onPressed: () => _removeClubAdminRole(assignment),
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

  Widget _buildCreateCard(
    BuildContext context,
    AdminScope scope,
    AdminClubPermission? selectedPermission,
  ) {
    final canCreate =
        scope.isGlobalAdmin || (selectedPermission?.canCreatePlayers ?? false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _createFormKey,
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
                    _nameController,
                    'Name',
                    validator: _requiredValidator,
                  ),
                  _buildSmallField(
                    _positionController,
                    'Position',
                    validator: _requiredValidator,
                  ),
                  _buildSmallField(
                    _leagueController,
                    'Liga',
                    validator: _requiredValidator,
                  ),
                  _buildSmallField(
                    _seasonController,
                    'Saison',
                    hintText: '2026/27',
                    validator: _requiredValidator,
                  ),
                  _buildSmallField(
                    _goalsController,
                    'Tore',
                    keyboardType: TextInputType.number,
                    validator: _nonNegativeIntValidator,
                  ),
                  _buildSmallField(
                    _gamesController,
                    'Spiele',
                    keyboardType: TextInputType.number,
                    validator: _nonNegativeIntValidator,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedSport,
                decoration: const InputDecoration(
                  labelText: 'Sport',
                  prefixIcon: Icon(Icons.sports),
                ),
                items: const [
                  DropdownMenuItem(value: 'soccer', child: Text('Soccer')),
                  DropdownMenuItem(value: 'handball', child: Text('Handball')),
                ],
                onChanged: canCreate
                    ? (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedSport = value;
                        });
                      }
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: canCreate ? _pickImage : null,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Bild waehlen'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedImageName ?? 'Kein Bild ausgewaehlt',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: canCreate && !_isSaving ? _createPlayer : null,
                  icon: _isSaving
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

  Widget _buildPlayersSection(
    BuildContext context,
    AdminScope scope,
    AdminClubPermission? selectedPermission,
  ) {
    final clubId = _selectedClubId;
    if (clubId == null) {
      return const SizedBox.shrink();
    }

    final canEdit =
        scope.isGlobalAdmin || (selectedPermission?.canEditPlayers ?? false);
    final playersAsync = ref.watch(adminPlayersByClubProvider(clubId));

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
                            onPressed: canEdit
                                ? () => _editPlayer(scope, player)
                                : null,
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

  Widget _buildSmallField(
    TextEditingController controller,
    String label, {
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

  String? _nonNegativeIntValidator(String? value) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null || parsed < 0) {
      return 'Bitte eine Zahl >= 0 eingeben';
    }
    return null;
  }

  int _parseNonNegative(String value) {
    final parsed = int.tryParse(value.trim()) ?? 0;
    if (parsed < 0) {
      return 0;
    }
    return parsed;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    if (file.bytes == null || file.bytes!.isEmpty) {
      return;
    }

    setState(() {
      _selectedImageBytes = file.bytes;
      _selectedImageName = file.name;
    });
  }

  Future<void> _createPlayer() async {
    if (!(_createFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final clubId = _selectedClubId;
    if (clubId == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(adminRepoProvider);
      await repo.createPlayer(
        name: _nameController.text.trim(),
        position: _positionController.text.trim(),
        clubId: clubId,
        sport: _selectedSport,
        league: _leagueController.text.trim(),
        season: _seasonController.text.trim(),
        goals: _parseNonNegative(_goalsController.text),
        games: _parseNonNegative(_gamesController.text),
        imageBytes: _selectedImageBytes,
        imageExtension: _extensionFromFileName(_selectedImageName),
      );

      if (!mounted) {
        return;
      }

      _nameController.clear();
      _positionController.clear();
      _leagueController.clear();
      _seasonController.text = _defaultSeason();
      _goalsController.text = '0';
      _gamesController.text = '0';
      setState(() {
        _selectedImageBytes = null;
        _selectedImageName = null;
      });

      ref.invalidate(adminPlayersByClubProvider(clubId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Spieler erfolgreich angelegt.')),
      );
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speichern fehlgeschlagen: ${error.message}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speichern fehlgeschlagen: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _searchUsersForRole() async {
    setState(() {
      _isUserSearching = true;
    });

    try {
      final users = await ref
          .read(adminRepoProvider)
          .searchUsersForAdmin(_userSearchController.text.trim());

      if (!mounted) {
        return;
      }

      setState(() {
        _userSearchResults = users;
      });
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User-Suche fehlgeschlagen: ${error.message}'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User-Suche fehlgeschlagen: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUserSearching = false;
        });
      }
    }
  }

  Future<void> _assignClubAdminRole() async {
    final clubId = _selectedClubId;
    final userId = _selectedRoleUserId;

    if (clubId == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte Verein und User fuer die Rolle auswaehlen.'),
        ),
      );
      return;
    }

    setState(() {
      _isRoleSaving = true;
    });

    try {
      await ref
          .read(adminRepoProvider)
          .upsertClubAdminRole(
            userId: userId,
            clubId: clubId,
            canCreatePlayers: _roleCanCreatePlayers,
            canEditPlayers: _roleCanEditPlayers,
          );

      if (!mounted) {
        return;
      }

      ref.invalidate(clubAdminRoleAssignmentsProvider);
      ref.invalidate(adminScopeProvider);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rolle gespeichert.')));
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rolle konnte nicht gespeichert werden: ${error.message}',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rolle konnte nicht gespeichert werden: $error'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRoleSaving = false;
        });
      }
    }
  }

  Future<void> _removeClubAdminRole(ClubAdminRoleAssignment assignment) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rolle entziehen?'),
        content: Text(
          'Soll ${assignment.email ?? assignment.userId} als Vereinsadmin fuer ${assignment.clubName} entfernt werden?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Entziehen'),
          ),
        ],
      ),
    );

    if (shouldRemove != true || !mounted) {
      return;
    }

    try {
      await ref
          .read(adminRepoProvider)
          .removeClubAdminRole(
            userId: assignment.userId,
            clubId: assignment.clubId,
          );

      if (!mounted) {
        return;
      }

      ref.invalidate(clubAdminRoleAssignmentsProvider);
      ref.invalidate(adminScopeProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rolle entzogen.')));
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Entziehen fehlgeschlagen: ${error.message}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Entziehen fehlgeschlagen: $error')),
        );
      }
    }
  }

  Future<void> _reviewRequest({
    required AdminScope scope,
    required AdminAccessRequest request,
    required bool approve,
  }) async {
    final noteController = TextEditingController();
    var createClubIfMissing = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(approve ? 'Anfrage genehmigen' : 'Anfrage ablehnen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verein: ${request.clubName ?? request.requestedClubName}',
                  ),
                  const SizedBox(height: 8),
                  if (request.isForMissingClub)
                    Text(
                      scope.isGlobalAdmin
                          ? 'Dieser Verein existiert noch nicht. Du kannst ihn beim Genehmigen direkt anlegen.'
                          : 'Dieser Verein existiert noch nicht. Das darf nur ein Super-Admin genehmigen.',
                      style: TextStyle(
                        color: scope.isGlobalAdmin
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (approve &&
                      request.isForMissingClub &&
                      scope.isGlobalAdmin) ...[
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: createClubIfMissing,
                      onChanged: (value) {
                        setDialogState(() {
                          createClubIfMissing = value ?? false;
                        });
                      },
                      title: const Text(
                        'Verein bei Genehmigung automatisch anlegen',
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notiz (optional)',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Abbrechen'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(approve ? 'Genehmigen' : 'Ablehnen'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) {
      noteController.dispose();
      return;
    }

    try {
      await ref
          .read(adminRepoProvider)
          .reviewAdminAccessRequest(
            requestId: request.id,
            approve: approve,
            decisionNote: noteController.text.trim(),
            createClubIfMissing: createClubIfMissing,
          );

      if (!mounted) {
        return;
      }

      ref.invalidate(pendingAdminAccessRequestsProvider);
      ref.invalidate(allClubsProvider);
      ref.invalidate(adminScopeProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve ? 'Anfrage wurde genehmigt.' : 'Anfrage wurde abgelehnt.',
          ),
        ),
      );
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aktion fehlgeschlagen: ${error.message}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aktion fehlgeschlagen: $error')),
        );
      }
    } finally {
      noteController.dispose();
    }
  }

  Future<void> _editPlayer(AdminScope scope, AdminPlayer player) async {
    final nameController = TextEditingController(text: player.name);
    final positionController = TextEditingController(text: player.position);
    final leagueController = TextEditingController(text: player.league);
    final seasonController = TextEditingController(text: player.season);
    final goalsController = TextEditingController(
      text: player.goals.toString(),
    );
    final gamesController = TextEditingController(
      text: player.games.toString(),
    );
    var selectedSport = player.sport;
    var selectedClubId = player.clubId;
    Uint8List? selectedBytes;
    String? selectedImageName;

    Future<void> pickEditImage(StateSetter setModalState) async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: true,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      );

      if (result == null ||
          result.files.isEmpty ||
          result.files.first.bytes == null) {
        return;
      }

      setModalState(() {
        selectedBytes = result.files.first.bytes;
        selectedImageName = result.files.first.name;
      });
    }

    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spieler bearbeiten',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        validator: _requiredValidator,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: positionController,
                        validator: _requiredValidator,
                        decoration: const InputDecoration(
                          labelText: 'Position',
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedSport,
                        decoration: const InputDecoration(labelText: 'Sport'),
                        items: const [
                          DropdownMenuItem(
                            value: 'soccer',
                            child: Text('Soccer'),
                          ),
                          DropdownMenuItem(
                            value: 'handball',
                            child: Text('Handball'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setModalState(() {
                            selectedSport = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedClubId,
                        decoration: const InputDecoration(labelText: 'Verein'),
                        items: scope.clubs
                            .where(
                              (club) =>
                                  club.canEditPlayers || scope.isGlobalAdmin,
                            )
                            .map(
                              (club) => DropdownMenuItem<String>(
                                value: club.clubId,
                                child: Text(club.clubName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setModalState(() {
                            selectedClubId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: leagueController,
                        validator: _requiredValidator,
                        decoration: const InputDecoration(labelText: 'Liga'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: seasonController,
                        validator: _requiredValidator,
                        decoration: const InputDecoration(labelText: 'Saison'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: goalsController,
                        validator: _nonNegativeIntValidator,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Tore'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: gamesController,
                        validator: _nonNegativeIntValidator,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Spiele'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => pickEditImage(setModalState),
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('Neues Bild'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedImageName ?? 'Kein neues Bild',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            Navigator.of(context).pop(true);
                          },
                          child: const Text('Aenderungen speichern'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (saved != true || !mounted) {
      nameController.dispose();
      positionController.dispose();
      leagueController.dispose();
      seasonController.dispose();
      goalsController.dispose();
      gamesController.dispose();
      return;
    }

    try {
      await ref
          .read(adminRepoProvider)
          .updatePlayer(
            playerId: player.id,
            name: nameController.text.trim(),
            position: positionController.text.trim(),
            clubId: selectedClubId,
            sport: selectedSport,
            league: leagueController.text.trim(),
            season: seasonController.text.trim(),
            goals: _parseNonNegative(goalsController.text),
            games: _parseNonNegative(gamesController.text),
            imageBytes: selectedBytes,
            imageExtension: _extensionFromFileName(selectedImageName),
          );

      if (!mounted) {
        return;
      }

      ref.invalidate(adminPlayersByClubProvider(_selectedClubId!));
      if (selectedClubId != _selectedClubId) {
        ref.invalidate(adminPlayersByClubProvider(selectedClubId));
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Spieler aktualisiert.')));
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update fehlgeschlagen: ${error.message}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update fehlgeschlagen: $error')),
        );
      }
    } finally {
      nameController.dispose();
      positionController.dispose();
      leagueController.dispose();
      seasonController.dispose();
      goalsController.dispose();
      gamesController.dispose();
    }
  }

  String? _extensionFromFileName(String? fileName) {
    if (fileName == null || !fileName.contains('.')) {
      return null;
    }
    return fileName.split('.').last;
  }
}
