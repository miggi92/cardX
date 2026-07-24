import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_auth_repository.dart';
import '../domain/auth_provider_type.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(Supabase.instance.client);
});

final authControllerProvider =
    NotifierProvider<AuthController, AuthControllerState>(AuthController.new);

class AuthControllerState {
  const AuthControllerState({
    this.isPasswordAuthLoading = false,
    this.loadingProvider,
    this.isAccountDeletionLoading = false,
  });

  final bool isPasswordAuthLoading;
  final AuthProviderType? loadingProvider;
  final bool isAccountDeletionLoading;

  bool get isAnyLoading =>
      isPasswordAuthLoading ||
      loadingProvider != null ||
      isAccountDeletionLoading;

  AuthControllerState copyWith({
    bool? isPasswordAuthLoading,
    AuthProviderType? loadingProvider,
    bool? isAccountDeletionLoading,
    bool clearProvider = false,
  }) {
    return AuthControllerState(
      isPasswordAuthLoading:
          isPasswordAuthLoading ?? this.isPasswordAuthLoading,
      loadingProvider: clearProvider
          ? null
          : (loadingProvider ?? this.loadingProvider),
      isAccountDeletionLoading:
          isAccountDeletionLoading ?? this.isAccountDeletionLoading,
    );
  }
}

class AuthFlowException implements Exception {
  const AuthFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthController extends Notifier<AuthControllerState> {
  late final AuthRepository _authRepository;

  @override
  AuthControllerState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    return const AuthControllerState();
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isPasswordAuthLoading: true);
    try {
      await _authRepository.signInWithEmail(email: email, password: password);
    } on AuthException catch (error) {
      throw AuthFlowException(error.message);
    } catch (_) {
      throw const AuthFlowException('Login failed. Please try again.');
    } finally {
      state = state.copyWith(isPasswordAuthLoading: false);
    }
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isPasswordAuthLoading: true);
    try {
      return await _authRepository.signUpWithEmail(
        email: email,
        password: password,
      );
    } on AuthException catch (error) {
      throw AuthFlowException(error.message);
    } catch (_) {
      throw const AuthFlowException('Registration failed. Please try again.');
    } finally {
      state = state.copyWith(isPasswordAuthLoading: false);
    }
  }

  Future<void> signInWithProvider(AuthProviderType provider) async {
    state = state.copyWith(loadingProvider: provider);
    try {
      await _authRepository.signInWithProvider(provider);
    } on AuthException catch (error) {
      throw AuthFlowException(error.message);
    } catch (_) {
      throw AuthFlowException('${provider.label} failed. Please try again.');
    } finally {
      state = state.copyWith(clearProvider: true);
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
    } on AuthException catch (error) {
      throw AuthFlowException(error.message);
    } catch (_) {
      throw const AuthFlowException('Sign-out failed. Please try again.');
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isAccountDeletionLoading: true);
    try {
      await _authRepository.deleteAccount();
    } on AuthException catch (error) {
      throw AuthFlowException(error.message);
    } on PostgrestException catch (error) {
      throw AuthFlowException(error.message);
    } catch (_) {
      throw const AuthFlowException(
        'Account deletion failed. Please try again.',
      );
    } finally {
      state = state.copyWith(isAccountDeletionLoading: false);
    }
  }
}
