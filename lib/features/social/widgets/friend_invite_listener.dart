import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cardx/features/social/data/supabase_social_repository.dart';
import 'package:cardx/features/social/providers/social_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendInviteListener extends ConsumerStatefulWidget {
  const FriendInviteListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<FriendInviteListener> createState() =>
      _FriendInviteListenerState();
}

class _FriendInviteListenerState extends ConsumerState<FriendInviteListener> {
  static final _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  String? _pendingToken;
  String? _lastHandledToken;
  bool _isHandling = false;

  @override
  void initState() {
    super.initState();
    _linkSubscription = _appLinks.uriLinkStream.listen(_receiveLink);
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (_) => _tryHandleInvite(),
    );
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _receiveLink(uri);
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _receiveLink(Uri uri) {
    if (uri.scheme != 'cardx' ||
        uri.host != 'friend' ||
        uri.pathSegments.length != 1) {
      return;
    }

    final token = uri.pathSegments.single;
    if (!_uuidPattern.hasMatch(token) || token == _lastHandledToken) {
      return;
    }

    _pendingToken = token;
    _tryHandleInvite();
  }

  void _tryHandleInvite() {
    final token = _pendingToken;
    if (token == null ||
        _isHandling ||
        Supabase.instance.client.auth.currentUser == null) {
      return;
    }

    _isHandling = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _confirmInvite(token);
      }
    });
  }

  Future<void> _confirmInvite(String token) async {
    final shouldAccept = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Freund hinzufügen?'),
        content: const Text(
          'Möchtest du die Freundeseinladung in CardX annehmen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Hinzufügen'),
          ),
        ],
      ),
    );

    _pendingToken = null;
    _lastHandledToken = token;

    if (shouldAccept == true && mounted) {
      try {
        final username = await ref
            .read(socialRepositoryProvider)
            .acceptInvite(token);
        ref.invalidate(friendsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$username wurde als Freund hinzugefügt.')),
          );
        }
      } catch (error) {
        if (mounted) {
          final message = error is SocialException
              ? error.message
              : 'Einladung konnte nicht angenommen werden.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      }
    }

    _isHandling = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}