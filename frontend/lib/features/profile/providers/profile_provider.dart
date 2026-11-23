import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_model.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

final myProfileProvider = FutureProvider<ProfileModel>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getMyProfile();
});