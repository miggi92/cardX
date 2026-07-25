import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_provider_type.dart';

abstract class AuthRepository {
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<void> signInWithProvider(AuthProviderType provider);

  Future<void> signOut();

  Future<void> deleteAccount();
}
