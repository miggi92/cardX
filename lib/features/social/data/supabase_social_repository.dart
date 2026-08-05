import 'package:cardx/features/social/models/social_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocialException implements Exception {
  const SocialException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SupabaseSocialRepository {
  SupabaseSocialRepository(this._client);

  final SupabaseClient _client;

  Future<SocialProfile> getMyProfile() async {
    final response = await _client.rpc('get_my_social_profile') as List;
    if (response.isEmpty) {
      throw const SocialException('Dein Profil konnte nicht geladen werden.');
    }

    final row = response.single as Map<String, dynamic>;
    return SocialProfile(
      username: row['username'] as String?,
      inviteToken: row['friend_invite_token'] as String,
    );
  }

  Future<String> setUsername(String username) async {
    try {
      return await _client.rpc(
            'set_my_username',
            params: {'p_username': username},
          )
          as String;
    } on PostgrestException catch (error) {
      if (error.message.contains('USERNAME_TAKEN')) {
        throw const SocialException('Dieser Username ist bereits vergeben.');
      }
      if (error.message.contains('USERNAME_INVALID')) {
        throw const SocialException(
          'Nutze 3 bis 20 Kleinbuchstaben, Zahlen oder Unterstriche.',
        );
      }
      rethrow;
    }
  }

  Future<String> rotateInviteToken() async {
    return await _client.rpc('rotate_my_friend_invite_token') as String;
  }

  Future<String> acceptInvite(String token) async {
    try {
      return await _client.rpc(
            'accept_friend_invite',
            params: {'p_token': token},
          )
          as String;
    } on PostgrestException catch (error) {
      if (error.message.contains('INVITE_INVALID')) {
        throw const SocialException(
          'Dieser Einladungslink ist nicht mehr gültig.',
        );
      }
      if (error.message.contains('INVITE_OWN')) {
        throw const SocialException(
          'Du kannst dich nicht selbst als Freund hinzufügen.',
        );
      }
      rethrow;
    }
  }

  Future<List<FriendProfile>> listFriends() async {
    final response = await _client.rpc('list_my_friends') as List;
    return response.map((rawRow) {
      final row = rawRow as Map<String, dynamic>;
      return FriendProfile(
        userId: row['user_id'] as String,
        username: row['username'] as String?,
        friendsSince: DateTime.parse(row['friends_since'] as String),
      );
    }).toList();
  }
}