import 'package:cardx/features/social/data/supabase_social_repository.dart';
import 'package:cardx/features/social/models/social_models.dart';
import 'package:cardx/features/social/providers/social_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class FriendsProfileSection extends ConsumerStatefulWidget {
  const FriendsProfileSection({super.key});

  @override
  ConsumerState<FriendsProfileSection> createState() =>
      _FriendsProfileSectionState();
}

class _FriendsProfileSectionState
    extends ConsumerState<FriendsProfileSection> {
  bool _isUpdatingLink = false;

  void _showError(Object error) {
    final message = error is SocialException
        ? error.message
        : 'Aktion fehlgeschlagen: $error';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _editUsername(String? currentUsername) async {
    final controller = TextEditingController(text: currentUsername);
    final formKey = GlobalKey<FormState>();

    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          currentUsername == null ? 'Username festlegen' : 'Username ändern',
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            maxLength: 20,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixText: '@',
              prefixIcon: Icon(Icons.alternate_email),
            ),
            validator: (value) {
              final normalized = value?.trim().toLowerCase() ?? '';
              if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(normalized)) {
                return '3-20 Kleinbuchstaben, Zahlen oder Unterstriche';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(controller.text);
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(controller.text);
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (username == null || !mounted) {
      return;
    }

    try {
      await ref.read(socialRepositoryProvider).setUsername(username);
      ref.invalidate(socialProfileProvider);
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
    }
  }

  Future<void> _shareInvite(SocialProfile profile) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        subject: 'CardX Freundeseinladung',
        text:
            'Füge @${profile.username} bei CardX als Freund hinzu:\n${profile.inviteLink}',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _rotateInviteLink() async {
    final shouldRotate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Einladungslink erneuern?'),
        content: const Text(
          'Der bisherige Link funktioniert danach nicht mehr.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Erneuern'),
          ),
        ],
      ),
    );

    if (shouldRotate != true || !mounted) {
      return;
    }

    setState(() => _isUpdatingLink = true);
    try {
      await ref.read(socialRepositoryProvider).rotateInviteToken();
      ref.invalidate(socialProfileProvider);
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingLink = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(socialProfileProvider);
    final friendsAsync = ref.watch(friendsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Freunde', style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 14),
            profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Profil konnte nicht geladen werden.'),
              data: (profile) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.alternate_email),
                    title: Text(profile.username ?? 'Kein Username'),
                    trailing: IconButton(
                      tooltip: 'Username bearbeiten',
                      onPressed: () => _editUsername(profile.username),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: profile.username == null
                              ? null
                              : () => _shareInvite(profile),
                          icon: const Icon(Icons.ios_share_outlined),
                          label: const Text('Einladungslink teilen'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        tooltip: 'Einladungslink erneuern',
                        onPressed: _isUpdatingLink ? null : _rotateInviteLink,
                        icon: _isUpdatingLink
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 28),
            Text('Meine Freunde', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            friendsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => const Text(
                'Freunde konnten nicht geladen werden.',
              ),
              data: (friends) {
                if (friends.isEmpty) {
                  return const Text('Noch keine Freunde hinzugefügt.');
                }
                return Column(
                  children: friends
                      .map(
                        (friend) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(friend.username ?? 'Spieler'),
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