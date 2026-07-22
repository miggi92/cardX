import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_provider_type.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> signInWithEmail({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<AuthResponse> signUpWithEmail({required String email, required String password}) {
    return _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signInWithProvider(AuthProviderType provider) {
    return _client.auth.signInWithOAuth(provider.oauthProvider);
  }
}
