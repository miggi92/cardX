import 'package:cardx/features/admin/models/admin_sport.dart';
import 'package:cardx/features/admin/models/admin_team.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminTeamsSection extends StatelessWidget {
  const AdminTeamsSection({
    super.key,
    required this.teamsAsync,
    required this.canEdit,
    required this.onAdd,
    required this.onEdit,
    required this.onSync,
  });

  final AsyncValue<List<AdminTeam>> teamsAsync;
  final bool canEdit;
  final VoidCallback onAdd;
  final ValueChanged<AdminTeam> onEdit;
  final Future<void> Function(AdminTeam team) onSync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Mannschaften',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            FilledButton.icon(
              onPressed: canEdit ? onAdd : null,
              icon: const Icon(Icons.add),
              label: const Text('Anlegen'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        teamsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Text('Mannschaften konnten nicht geladen werden: $error'),
          data: (teams) {
            if (teams.isEmpty) {
              return const Text(
                'Für diesen Verein gibt es noch keine Mannschaft.',
              );
            }

            return Column(
              children: teams
                  .map(
                    (team) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.groups_outlined),
                        title: Text(team.name),
                        subtitle: Text(
                          [
                            team.sportId,
                            team.seasonId,
                            team.ageGroup,
                            _genderLabel(team.gender),
                            team.leagueId,
                          ].where((value) => value.isNotEmpty).join(' · '),
                        ),
                        trailing: Wrap(
                          spacing: 2,
                          children: [
                            if (team.syncEnabled)
                              IconButton(
                                onPressed: canEdit ? () => onSync(team) : null,
                                icon: const Icon(Icons.sync),
                                tooltip: 'Online-Daten abgleichen',
                              ),
                            IconButton(
                              onPressed: canEdit ? () => onEdit(team) : null,
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Mannschaft bearbeiten',
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
    );
  }

  static String _genderLabel(String gender) {
    return switch (gender) {
      'male' => 'männlich',
      'female' => 'weiblich',
      'mixed' => 'gemischt',
      _ => gender,
    };
  }
}

class AdminTeamEditorDialog extends StatefulWidget {
  const AdminTeamEditorDialog({
    super.key,
    required this.sports,
    required this.seasons,
    required this.loadLeagues,
    required this.onSave,
    this.team,
  });

  final List<SportOption> sports;
  final List<SeasonOption> seasons;
  final Future<List<LeagueOption>> Function(String sportId, String seasonId)
  loadLeagues;
  final Future<void> Function({
    required String sportId,
    required String seasonId,
    required String name,
    required String leagueId,
    required String ageGroup,
    required String gender,
    required String externalTeamId,
    required bool syncEnabled,
  })
  onSave;
  final AdminTeam? team;

  @override
  State<AdminTeamEditorDialog> createState() => _AdminTeamEditorDialogState();
}

class _AdminTeamEditorDialogState extends State<AdminTeamEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageGroupController;
  late final TextEditingController _externalIdController;
  late String _sportId;
  late String _seasonId;
  late String _gender;
  String? _leagueId;
  List<LeagueOption> _leagues = const [];
  bool _syncEnabled = false;
  bool _isLoadingLeagues = true;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final team = widget.team;
    _nameController = TextEditingController(text: team?.name ?? '');
    _ageGroupController = TextEditingController(
      text: team?.ageGroup ?? 'adults',
    );
    _externalIdController = TextEditingController(
      text: team?.externalTeamId ?? '',
    );
    _sportId = team?.sportId ?? widget.sports.first.id;
    _seasonId = team?.seasonId ?? widget.seasons.first.id;
    _gender = team?.gender ?? 'mixed';
    _leagueId = team?.leagueId;
    _syncEnabled = team?.syncEnabled ?? false;
    _loadLeagues();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageGroupController.dispose();
    _externalIdController.dispose();
    super.dispose();
  }

  Future<void> _loadLeagues() async {
    setState(() {
      _isLoadingLeagues = true;
    });
    final leagues = await widget.loadLeagues(_sportId, _seasonId);
    if (!mounted) {
      return;
    }
    setState(() {
      _leagues = leagues;
      if (!_leagues.any((league) => league.id == _leagueId)) {
        _leagueId = _leagues.firstOrNull?.id;
      }
      _isLoadingLeagues = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _leagueId == null) {
      return;
    }
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(
        sportId: _sportId,
        seasonId: _seasonId,
        name: _nameController.text,
        leagueId: _leagueId!,
        ageGroup: _ageGroupController.text,
        gender: _gender,
        externalTeamId: _externalIdController.text,
        syncEnabled: _syncEnabled,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saveError = 'Speichern fehlgeschlagen: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.team == null ? 'Mannschaft anlegen' : 'Mannschaft bearbeiten',
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _sportId,
                  decoration: const InputDecoration(labelText: 'Sportart'),
                  items: widget.sports
                      .map(
                        (sport) => DropdownMenuItem(
                          value: sport.id,
                          child: Text(sport.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _sportId = value;
                    _leagueId = null;
                    _loadLeagues();
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _seasonId,
                  decoration: const InputDecoration(labelText: 'Saison'),
                  items: widget.seasons
                      .map(
                        (season) => DropdownMenuItem(
                          value: season.id,
                          child: Text(season.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _seasonId = value;
                    _leagueId = null;
                    _loadLeagues();
                  },
                ),
                const SizedBox(height: 12),
                if (_isLoadingLeagues)
                  const LinearProgressIndicator()
                else
                  DropdownButtonFormField<String>(
                    initialValue: _leagueId,
                    decoration: const InputDecoration(labelText: 'Liga'),
                    items: _leagues
                        .map(
                          (league) => DropdownMenuItem(
                            value: league.id,
                            child: Text(league.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _leagueId = value;
                    }),
                    validator: (value) => value == null ? 'Pflichtfeld' : null,
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageGroupController,
                  decoration: const InputDecoration(
                    labelText: 'Altersklasse',
                    hintText: 'z. B. Erwachsene oder A-Jugend',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'male', label: Text('M')),
                    ButtonSegment(value: 'female', label: Text('W')),
                    ButtonSegment(value: 'mixed', label: Text('Mixed')),
                  ],
                  selected: {_gender},
                  onSelectionChanged: (values) => setState(() {
                    _gender = values.first;
                  }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _externalIdController,
                  decoration: const InputDecoration(
                    labelText: 'Handball-Checks Team-ID (optional)',
                    hintText: 'handball4all.baden-wuerttemberg.1325831',
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Online-Abgleich aktivieren'),
                  value: _syncEnabled,
                  onChanged: (value) => setState(() {
                    _syncEnabled = value;
                  }),
                ),
                if (_saveError != null)
                  Text(
                    _saveError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _isSaving || _isLoadingLeagues ? null : _save,
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Speichern'),
        ),
      ],
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Pflichtfeld' : null;
  }
}
