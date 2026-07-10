import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/supabase_shop_repository.dart';
import '../../features/shop/models/pack_model.dart';

final shopRepoProvider = Provider((ref) => SupabaseShopRepository());

// Lädt die Packs asynchron aus Supabase
final availablePacksProvider = FutureProvider<List<PackModel>>((ref) async {
  final repo = ref.watch(shopRepoProvider);
  return repo.getAvailablePacks();
});
