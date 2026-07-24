import 'package:cardx/core/theme/app_theme.dart';
import 'package:cardx/core/providers/admin_provider.dart';
import 'package:cardx/features/auth/application/auth_controller.dart';
import 'package:cardx/features/admin/models/admin_access_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _newClubSentinel = '__new_club__';

  final _requestFormKey = GlobalKey<FormState>();
  final _requestMessageController = TextEditingController();
  final _newClubNameController = TextEditingController();

  String? _selectedClubId;
  bool _isSubmittingRequest = false;

  @override
  void dispose() {
    _requestMessageController.dispose();
    _newClubNameController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
    } on AuthFlowException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _deleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konto loeschen?'),
        content: const Text(
          'Diese Aktion kann nicht rueckgaengig gemacht werden. '
          'Deine Sammlung und dein Profil werden dauerhaft geloescht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Konto loeschen'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
    } on AuthFlowException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _submitAdminRequest() async {
    if (!(_requestFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmittingRequest = true;
    });

    try {
      final repo = ref.read(adminRepoProvider);
      final selected = _selectedClubId;
      final isNewClubRequest = selected == _newClubSentinel || selected == null;

      await repo.submitAdminAccessRequest(
        clubId: isNewClubRequest ? null : selected,
        requestedClubName: isNewClubRequest
            ? _newClubNameController.text.trim()
            : null,
        message: _requestMessageController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      _requestMessageController.clear();
      _newClubNameController.clear();
      setState(() {
        _selectedClubId = _newClubSentinel;
      });

      ref.invalidate(myAdminAccessRequestsProvider);
      ref.invalidate(pendingAdminAccessRequestsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anfrage erfolgreich abgeschickt.')),
      );
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anfrage fehlgeschlagen: ${error.message}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anfrage fehlgeschlagen: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingRequest = false;
        });
      }
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pflichtfeld';
    }
    return null;
  }

  String _statusLabel(AdminRequestStatus status) {
    return switch (status) {
      AdminRequestStatus.pending => 'Ausstehend',
      AdminRequestStatus.approved => 'Genehmigt',
      AdminRequestStatus.rejected => 'Abgelehnt',
    };
  }

  Color _statusColor(BuildContext context, AdminRequestStatus status) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      AdminRequestStatus.pending => scheme.tertiary,
      AdminRequestStatus.approved => Colors.green,
      AdminRequestStatus.rejected => scheme.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;
    final authState = ref.watch(authControllerProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final clubsAsync = ref.watch(allClubsProvider);
    final myRequestsAsync = ref.watch(myAdminAccessRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: brand.heroGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: brand.surfaceShadow,
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mein Account',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? 'Keine E-Mail verknuepft',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sicherheit', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: authState.isAnyLoading ? null : _signOut,
                        icon: const Icon(Icons.logout_outlined),
                        label: const Text('Abmelden'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _requestFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vereinsadmin beantragen',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Du kannst Adminrechte fuer einen bestehenden Verein oder fuer einen neuen Verein beantragen.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      clubsAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, _) => Text(
                          'Vereine konnten nicht geladen werden: $error',
                        ),
                        data: (clubs) {
                          final selectedValue =
                              _selectedClubId ?? _newClubSentinel;

                          return DropdownButtonFormField<String>(
                            initialValue: selectedValue,
                            decoration: const InputDecoration(
                              labelText: 'Verein',
                              prefixIcon: Icon(Icons.shield_outlined),
                            ),
                            items: [
                              ...clubs.map(
                                (club) => DropdownMenuItem<String>(
                                  value: club['id']!,
                                  child: Text(club['name']!),
                                ),
                              ),
                              const DropdownMenuItem<String>(
                                value: _newClubSentinel,
                                child: Text('Verein ist noch nicht angelegt'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _selectedClubId = value;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      if ((_selectedClubId ?? _newClubSentinel) ==
                          _newClubSentinel)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            controller: _newClubNameController,
                            validator: _required,
                            decoration: const InputDecoration(
                              labelText: 'Neuer Vereinsname',
                              prefixIcon: Icon(Icons.business_outlined),
                            ),
                          ),
                        ),
                      TextFormField(
                        controller: _requestMessageController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Begruendung (optional)',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSubmittingRequest
                              ? null
                              : _submitAdminRequest,
                          icon: _isSubmittingRequest
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_outlined),
                          label: const Text('Anfrage senden'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Meine Anfragen', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    myRequestsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, _) =>
                          Text('Anfragen konnten nicht geladen werden: $error'),
                      data: (requests) {
                        if (requests.isEmpty) {
                          return const Text(
                            'Du hast noch keine Anfragen gestellt.',
                          );
                        }

                        return Column(
                          children: requests
                              .map(
                                (request) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    request.clubName ??
                                        request.requestedClubName,
                                  ),
                                  subtitle: Text(
                                    [
                                      if (request.message != null &&
                                          request.message!.isNotEmpty)
                                        request.message!,
                                      if (request.decisionNote != null &&
                                          request.decisionNote!.isNotEmpty)
                                        'Notiz: ${request.decisionNote}',
                                    ].join('\n'),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(
                                        context,
                                        request.status,
                                      ).withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _statusLabel(request.status),
                                      style: TextStyle(
                                        color: _statusColor(
                                          context,
                                          request.status,
                                        ),
                                        fontWeight: FontWeight.w700,
                                      ),
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
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gefaehrlicher Bereich',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Das Loeschen entfernt dein Benutzerkonto inklusive Profil und Karten dauerhaft.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: authState.isAccountDeletionLoading
                            ? null
                            : _deleteAccount,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        ),
                        icon: authState.isAccountDeletionLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_forever_outlined),
                        label: Text(
                          authState.isAccountDeletionLoading
                              ? 'Konto wird gelöscht...'
                              : 'Konto löschen',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
