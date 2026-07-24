import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthProviderType { google, apple, github, microsoft }

extension AuthProviderTypeX on AuthProviderType {
  String get label {
    switch (this) {
      case AuthProviderType.google:
        return 'Continue with Google';
      case AuthProviderType.apple:
        return 'Continue with Apple';
      case AuthProviderType.github:
        return 'Continue with GitHub';
      case AuthProviderType.microsoft:
        return 'Continue with Microsoft';
    }
  }

  IconData get icon {
    switch (this) {
      case AuthProviderType.google:
        return Icons.g_mobiledata;
      case AuthProviderType.apple:
        return Icons.apple;
      case AuthProviderType.github:
        return Icons.code;
      case AuthProviderType.microsoft:
        return Icons.window;
    }
  }

  OAuthProvider get oauthProvider {
    switch (this) {
      case AuthProviderType.google:
        return OAuthProvider.google;
      case AuthProviderType.apple:
        return OAuthProvider.apple;
      case AuthProviderType.github:
        return OAuthProvider.github;
      case AuthProviderType.microsoft:
        return OAuthProvider.azure;
    }
  }
}

const supportedSocialAuthProviders = <AuthProviderType>[
  AuthProviderType.google,
];
