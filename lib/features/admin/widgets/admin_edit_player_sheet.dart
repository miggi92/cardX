import 'dart:typed_data';

import 'package:cardx/core/providers/admin_provider.dart';
import 'package:cardx/features/admin/models/admin_sport.dart';
import 'package:cardx/features/admin/models/admin_scope.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminEditPlayerSheet extends ConsumerStatefulWidget {
  const AdminEditPlayerSheet({
    super.key,
    required this.scope,
    required this.player,
  });

  final AdminScope scope;
  final AdminPlayer player;

  @override
  ConsumerState<AdminEditPlayerSheet> createState() =>
      _AdminEditPlayerSheetState();
}

class _AdminEditPlayerSheetState extends ConsumerState<AdminEditPlayerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _goalsController = TextEditingController();
  final _gamesController = TextEditingController();

  late String _selectedSport;
  String? _selectedPosition;
  String? _selectedSeason;
  late String _selectedClubId;
  Uint8List? _selectedBytes;
  String? _selectedImageName;
  bool _isLoading = true;
  bool _isSaving = false;

  List<SportOption> _sports = const [];
  List<SeasonOption> _seasons = const [];
  Map<String, List<PositionOption>> _positionsBySport = const {};

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.player.name;
    _goalsController.text = widget.player.goals.toString();
    _gamesController.text = widget.player.games.toString();
    _selectedSport = widget.player.sport;
    _selectedPosition = widget.player.position;
    _selectedSeason = widget.player.season;
    _selectedClubId = widget.player.clubId;
    _loadOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalsController.dispose();
    _gamesController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final repo = ref.read(adminRepoProvider);
      final sports = await repo.listSports();
      final seasons = await repo.listSeasons();
      final positionEntries = await Future.wait(
        sports.map(
          (sport) async =>
              MapEntry(sport.id, await repo.listPositions(sportId: sport.id)),
        ),
      );

      if (!mounted) {
        return;
      }

      final positionsBySport = <String, List<PositionOption>>{
        for (final entry in positionEntries) entry.key: entry.value,
      };

      String selectedSport = _selectedSport;
      if (selectedSport.isEmpty ||
          !sports.any((sport) => sport.id == selectedSport)) {
        selectedSport = sports.isNotEmpty ? sports.first.id : '';
      }

      String? selectedPosition = _selectedPosition;
      if (selectedSport.isNotEmpty) {
        final selectedPositions = positionsBySport[selectedSport] ?? const [];
        if (!selectedPositions.any(
              (position) => position.id == selectedPosition,
            ) &&
            selectedPositions.isNotEmpty) {
          selectedPosition = selectedPositions.first.id;
        }
      }

      String? selectedSeason = _selectedSeason;
      if (!seasons.any((season) => season.id == selectedSeason) &&
          seasons.isNotEmpty) {
        selectedSeason = seasons.first.id;
      }

      setState(() {
        _sports = sports;
        _seasons = seasons;
        _positionsBySport = positionsBySport;
        _selectedSport = selectedSport;
        _selectedPosition = selectedPosition;
        _selectedSeason = selectedSeason;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
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
      _selectedBytes = file.bytes;
      _selectedImageName = file.name;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedSport.isEmpty ||
        _selectedPosition == null ||
        _selectedSeason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte Sport, Position und Saison auswaehlen.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(adminRepoProvider)
          .updatePlayer(
            playerId: widget.player.id,
            name: _nameController.text.trim(),
            position: _selectedPosition ?? widget.player.position,
            clubId: _selectedClubId,
            sport: _selectedSport,
            season: _selectedSeason ?? widget.player.season,
            goals: _parseNonNegative(_goalsController.text),
            games: _parseNonNegative(_gamesController.text),
            imageBytes: _selectedBytes,
            imageExtension: _extensionFromFileName(_selectedImageName),
          );

      if (!mounted) {
        return;
      }

      ref.invalidate(adminPlayersByClubProvider(widget.player.clubId));
      if (_selectedClubId != widget.player.clubId) {
        ref.invalidate(adminPlayersByClubProvider(_selectedClubId));
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Spieler aktualisiert.')));
      Navigator.of(context).pop(true);
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
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editableClubs = widget.scope.clubs
        .where((club) => club.canEditPlayers || widget.scope.isGlobalAdmin)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            )
          : Form(
              key: _formKey,
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
                      controller: _nameController,
                      validator: _requiredValidator,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue:
                          _sports.any((sport) => sport.id == _selectedSport)
                          ? _selectedSport
                          : (_sports.isNotEmpty ? _sports.first.id : null),
                      decoration: const InputDecoration(labelText: 'Sport'),
                      items: _sports
                          .map(
                            (sport) => DropdownMenuItem<String>(
                              value: sport.id,
                              child: Text(sport.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedSport = value;
                          final positionsForSport =
                              _positionsBySport[value] ?? const [];
                          _selectedPosition =
                              positionsForSport.any(
                                (position) => position.id == _selectedPosition,
                              )
                              ? _selectedPosition
                              : (positionsForSport.isEmpty
                                    ? null
                                    : positionsForSport.first.id);
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: () {
                        final String currentSport = _selectedSport;
                        if (currentSport.isEmpty) {
                          return null;
                        }
                        final List<PositionOption> currentPositions =
                            _positionsBySport[currentSport] ?? const [];
                        return currentPositions.any(
                              (position) => position.id == _selectedPosition,
                            )
                            ? _selectedPosition
                            : (currentPositions.isNotEmpty
                                  ? currentPositions.first.id
                                  : null);
                      }(),
                      decoration: const InputDecoration(labelText: 'Position'),
                      validator: (value) =>
                          value == null ? 'Pflichtfeld' : null,
                      items:
                          (_selectedSport.isEmpty
                                  ? const <PositionOption>[]
                                  : _positionsBySport[_selectedSport] ??
                                        const <PositionOption>[])
                              .map(
                                (position) => DropdownMenuItem<String>(
                                  value: position.id,
                                  child: Text(position.displayName),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPosition = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue:
                          editableClubs.any(
                            (club) => club.clubId == _selectedClubId,
                          )
                          ? _selectedClubId
                          : (editableClubs.isNotEmpty
                                ? editableClubs.first.clubId
                                : null),
                      decoration: const InputDecoration(labelText: 'Verein'),
                      items: editableClubs
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
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue:
                          _seasons.any((season) => season.id == _selectedSeason)
                          ? _selectedSeason
                          : (_seasons.isNotEmpty ? _seasons.first.id : null),
                      decoration: const InputDecoration(labelText: 'Saison'),
                      validator: (value) =>
                          value == null ? 'Pflichtfeld' : null,
                      items: _seasons
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
                      onChanged: (value) {
                        setState(() {
                          _selectedSeason = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _goalsController,
                      validator: _nonNegativeIntValidator,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tore'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _gamesController,
                      validator: _nonNegativeIntValidator,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Spiele'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Neues Bild'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedImageName ?? 'Kein neues Bild',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Aenderungen speichern'),
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

  String? _extensionFromFileName(String? fileName) {
    if (fileName == null || !fileName.contains('.')) {
      return null;
    }
    return fileName.split('.').last;
  }
}
