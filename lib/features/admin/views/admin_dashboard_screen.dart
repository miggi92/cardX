import 'dart:typed_data';

import 'package:cardx/core/providers/admin_provider.dart';
import 'package:cardx/core/providers/storage_image_provider.dart';
import 'package:cardx/features/admin/models/admin_access_request.dart';
import 'package:cardx/features/admin/models/admin_role_assignment.dart';
import 'package:cardx/features/admin/models/admin_sport.dart';
import 'package:cardx/features/admin/models/admin_scope.dart';
import 'package:cardx/features/admin/application/admin_dashboard_actions.dart';
import 'package:cardx/features/admin/widgets/admin_action_dialogs.dart';
import 'package:cardx/features/admin/widgets/admin_edit_player_sheet.dart';
import 'package:cardx/features/admin/widgets/admin_dashboard_sections.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
  final _actions = const AdminDashboardActions();
  final _createFormKey = GlobalKey<FormState>();
  final _sportRequestFormKey = GlobalKey<FormState>();
  final _userSearchController = TextEditingController();
  final _nameController = TextEditingController();
  final _goalsController = TextEditingController(text: '0');
  final _gamesController = TextEditingController(text: '0');
  final _sportRequestIdController = TextEditingController();
  final _sportRequestNameController = TextEditingController();
  final _sportRequestMessageController = TextEditingController();

  String? _selectedSport;
  String? _selectedPosition;
  String? _selectedLeague;
  String? _selectedSeason;
  String? _selectedClubId;
  String? _selectedRoleUserId;
  String? _selectedRoleUserEmail;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isSaving = false;
  bool _isSubmittingSportRequest = false;
  bool _isUserSearching = false;
  bool _filterPendingBySelectedClub = true;
  bool _roleCanCreatePlayers = true;
  bool _roleCanEditPlayers = true;
  _AdminSection _selectedSection = _AdminSection.players;
  List<AdminUserOption> _userSearchResults = const [];

  @override
  void dispose() {
    _userSearchController.dispose();
    _nameController.dispose();
    _goalsController.dispose();
    _gamesController.dispose();
    _sportRequestIdController.dispose();
    _sportRequestNameController.dispose();
    _sportRequestMessageController.dispose();
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
    final sportsAsync = ref.watch(sportsProvider);
    final seasonsAsync = ref.watch(seasonsProvider);
    final currentUser = Supabase.instance.client.auth.currentUser;

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

    sportsAsync.whenData((sports) {
      if (_selectedSport == null && sports.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _selectedSport = sports.first.id;
          });
        });
      }
    });

    seasonsAsync.whenData((seasons) {
      if (_selectedSeason == null && seasons.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _selectedSeason = seasons.first.id;
          });
        });
      }
    });

    final availableSections = <_AdminSection>[
      _AdminSection.players,
      _AdminSection.requests,
      if (scope.isGlobalAdmin) _AdminSection.roles,
    ];

    if (!availableSections.contains(_selectedSection)) {
      _selectedSection = availableSections.first;
    }

    return Column(
      children: [
        if (kDebugMode)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug: Session & Rechte',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text('email: ${currentUser?.email ?? '-'}'),
                    Text('userId: ${currentUser?.id ?? '-'}'),
                    Text('isGlobalAdmin: ${scope.isGlobalAdmin}'),
                    Text('clubsInScope: ${scope.clubs.length}'),
                    Text('selectedClubId: ${_selectedClubId ?? '-'}'),
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final section in availableSections)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_sectionLabel(section)),
                      selected: _selectedSection == section,
                      onSelected: (selected) {
                        if (!selected) {
                          return;
                        }
                        setState(() {
                          _selectedSection = section;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshAdminData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: _buildSectionContent(
                context: context,
                scope: scope,
                manageableClubs: manageableClubs,
                selectedPermission: selectedPermission,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _refreshAdminData() async {
    await _actions.refreshAdminData(
      ref: ref,
      selectedSport: _selectedSport,
      selectedClubId: _selectedClubId,
    );
  }

  String _sectionLabel(_AdminSection section) {
    switch (section) {
      case _AdminSection.players:
        return 'Spielerverwaltung';
      case _AdminSection.requests:
        return 'Anfragen';
      case _AdminSection.roles:
        return 'Rollen';
    }
  }

  List<Widget> _buildSectionContent({
    required BuildContext context,
    required AdminScope scope,
    required List<AdminClubPermission> manageableClubs,
    required AdminClubPermission? selectedPermission,
  }) {
    final selectedClubId = _selectedClubId;
    switch (_selectedSection) {
      case _AdminSection.players:
        return [
          AdminScopeCard(scope: scope),
          const SizedBox(height: 12),
          AdminClubSelectorCard(
            clubs: manageableClubs,
            selectedClubId: selectedClubId,
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedClubId = value;
              });
            },
            imageResolver: ref.read(storageImageResolverProvider),
          ),
          const SizedBox(height: 12),
          AdminCreatePlayerCard(
            formKey: _createFormKey,
            nameController: _nameController,
            goalsController: _goalsController,
            gamesController: _gamesController,
            sportsAsync: ref.watch(sportsProvider),
            positionsAsync: _selectedSport == null
                ? const AsyncValue.data([])
                : ref.watch(positionsBySportProvider(_selectedSport!)),
            leaguesAsync: _selectedSport == null
                ? const AsyncValue.data([])
                : ref.watch(leaguesBySportProvider(_selectedSport!)),
            seasonsAsync: ref.watch(seasonsProvider),
            selectedSport: _selectedSport,
            selectedPosition: _selectedPosition,
            selectedLeague: _selectedLeague,
            selectedSeason: _selectedSeason,
            selectedImageName: _selectedImageName,
            canCreate:
                scope.isGlobalAdmin ||
                (selectedPermission?.canCreatePlayers ?? false),
            isSaving: _isSaving,
            onSportChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedSport = value;
                _selectedPosition = null;
                _selectedLeague = null;
              });
            },
            onPositionChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedPosition = value;
              });
            },
            onLeagueChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedLeague = value;
              });
            },
            onSeasonChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedSeason = value;
              });
            },
            onPickImage: _pickImage,
            onCreatePlayer: _createPlayer,
          ),
          const SizedBox(height: 16),
          AdminPlayersSection(
            playersAsync: ref.watch(
              adminPlayersByClubProvider(selectedClubId ?? ''),
            ),
            canEdit:
                scope.isGlobalAdmin || (selectedPermission?.canEditPlayers ?? false),
            onEditPlayer: (player) => _editPlayer(scope, player),
          ),
        ];
      case _AdminSection.requests:
        return [
          AdminScopeCard(scope: scope),
          const SizedBox(height: 12),
          AdminPendingRequestsSection(
            scope: scope,
            selectedClubId: selectedClubId,
            filterPendingBySelectedClub: _filterPendingBySelectedClub,
            onFilterChanged: (value) {
              setState(() {
                _filterPendingBySelectedClub = value;
              });
            },
            requestsAsync: ref.watch(pendingAdminAccessRequestsProvider),
            onReviewRequest: (request, approve) => _reviewRequest(
              scope: scope,
              request: request,
              approve: approve,
            ),
          ),
          const SizedBox(height: 12),
          AdminSportRequestSection(
            scope: scope,
            formKey: _sportRequestFormKey,
            sportIdController: _sportRequestIdController,
            displayNameController: _sportRequestNameController,
            messageController: _sportRequestMessageController,
            isSubmitting: _isSubmittingSportRequest,
            onSubmit: _submitSportRequest,
          ),
          if (scope.isGlobalAdmin) ...[
            const SizedBox(height: 12),
            AdminPendingSportRequestsSection(
              pendingAsync: ref.watch(pendingSportRequestsProvider),
              onReviewRequest: (request, approve) => _reviewSportRequest(
                request: request,
                approve: approve,
              ),
            ),
          ],
        ];
      case _AdminSection.roles:
        return [
          AdminScopeCard(scope: scope),
          const SizedBox(height: 12),
          AdminClubSelectorCard(
            clubs: manageableClubs,
            selectedClubId: selectedClubId,
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedClubId = value;
              });
            },
            imageResolver: ref.read(storageImageResolverProvider),
          ),
          const SizedBox(height: 12),
          AdminRoleManagementSection(
            selectedClubId: selectedClubId,
            assignmentsAsync: ref.watch(clubAdminRoleAssignmentsProvider),
            userSearchController: _userSearchController,
            isUserSearching: _isUserSearching,
            userSearchResults: _userSearchResults,
            selectedRoleUserId: _selectedRoleUserId,
            selectedRoleUserEmail: _selectedRoleUserEmail,
            roleCanCreatePlayers: _roleCanCreatePlayers,
            roleCanEditPlayers: _roleCanEditPlayers,
            onSearchUsers: _searchUsersForRole,
            onSelectUser: (user) {
              setState(() {
                _selectedRoleUserId = user.userId;
                _selectedRoleUserEmail = user.email;
              });
            },
            onCreatePlayersChanged: (value) {
              setState(() {
                _roleCanCreatePlayers = value;
              });
            },
            onEditPlayersChanged: (value) {
              setState(() {
                _roleCanEditPlayers = value;
              });
            },
            onAssignRole: _assignClubAdminRole,
            onRemoveRole: _removeClubAdminRole,
          ),
        ];
    }
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
    final selectedSport = _selectedSport;
    final selectedPosition = _selectedPosition;
    final selectedLeague = _selectedLeague;
    final selectedSeason = _selectedSeason;
    if (clubId == null ||
        selectedSport == null ||
        selectedPosition == null ||
        selectedLeague == null ||
        selectedSeason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bitte Verein, Sport, Position, Liga und Saison auswaehlen.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _actions.createPlayer(
        ref: ref,
        name: _nameController.text.trim(),
        position: selectedPosition,
        clubId: clubId,
        sport: selectedSport,
        league: selectedLeague,
        season: selectedSeason,
        goals: _parseNonNegative(_goalsController.text),
        games: _parseNonNegative(_gamesController.text),
        imageBytes: _selectedImageBytes,
        imageExtension: _extensionFromFileName(_selectedImageName),
      );

      if (!mounted) {
        return;
      }

      _nameController.clear();
      _goalsController.text = '0';
      _gamesController.text = '0';
      setState(() {
        _selectedPosition = null;
        _selectedLeague = null;
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

  Future<void> _submitSportRequest() async {
    if (!(_sportRequestFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmittingSportRequest = true;
    });

    try {
      final rawId = _sportRequestIdController.text.trim();
      await _actions.submitSportRequest(
        ref: ref,
        sportId: rawId,
        displayName: _sportRequestNameController.text.trim(),
        message: _sportRequestMessageController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      _sportRequestIdController.clear();
      _sportRequestNameController.clear();
      _sportRequestMessageController.clear();

      ref.invalidate(pendingSportRequestsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sportart-Anfrage gesendet.')),
      );
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sportart-Anfrage fehlgeschlagen: ${error.message}'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sportart-Anfrage fehlgeschlagen: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingSportRequest = false;
        });
      }
    }
  }

  Future<void> _reviewSportRequest({
    required SportRequest request,
    required bool approve,
  }) async {
    try {
      await _actions.reviewSportRequest(
        context: context,
        ref: ref,
        request: request,
        approve: approve,
      );

      if (!mounted) {
        return;
      }

      ref.invalidate(pendingSportRequestsProvider);
      ref.invalidate(sportsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? 'Sportart-Anfrage genehmigt.'
                : 'Sportart-Anfrage abgelehnt.',
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
    }
  }

  Future<void> _searchUsersForRole() async {
    setState(() {
      _isUserSearching = true;
    });

    try {
      final users = await _actions.searchUsersForRole(
        ref: ref,
        query: _userSearchController.text.trim(),
      );

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

    try {
      await ref
          .read(adminRepoProvider)
          .upsertClubAdminRole(
            userId: userId,
            clubId: clubId,
            canCreatePlayers: _roleCanCreatePlayers,
            canEditPlayers: _roleCanEditPlayers,
          );

      if (mounted) {
        ref.invalidate(clubAdminRoleAssignmentsProvider);
        ref.invalidate(adminScopeProvider);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Rolle gespeichert.')));
      }
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
    }
  }

  Future<void> _removeClubAdminRole(ClubAdminRoleAssignment assignment) async {
    final shouldRemove = await showRemoveClubAdminRoleDialog(context, assignment);

    if (shouldRemove != true || !mounted) {
      return;
    }

    try {
      await _actions.removeClubAdminRole(
        ref: ref,
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
    try {
      await _actions.reviewAdminAccessRequest(
        context: context,
        ref: ref,
        scope: scope,
        request: request,
        approve: approve,
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
    }
  }

  Future<void> _editPlayer(AdminScope scope, AdminPlayer player) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AdminEditPlayerSheet(scope: scope, player: player);
      },
    );
  }

  String? _extensionFromFileName(String? fileName) {
    if (fileName == null || !fileName.contains('.')) {
      return null;
    }
    return fileName.split('.').last;
  }
}

enum _AdminSection { players, requests, roles }
