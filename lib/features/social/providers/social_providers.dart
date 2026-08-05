import 'package:cardx/features/social/data/supabase_social_repository.dart';
import 'package:cardx/features/social/models/social_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final socialRepositoryProvider = Provider<SupabaseSocialRepository>((ref) {
  return SupabaseSocialRepository(Supabase.instance.client);
});

final socialProfileProvider = FutureProvider<SocialProfile>((ref) {
  return ref.watch(socialRepositoryProvider).getMyProfile();
});

final friendsProvider = FutureProvider<List<FriendProfile>>((ref) {
  return ref.watch(socialRepositoryProvider).listFriends();
});