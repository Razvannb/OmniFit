import 'package:omnifit_backend/models/hydration.dart';
import 'package:omnifit_backend/repositories/hydration_repository.dart';

class HydrationService {
  final HydrationRepository _hydrationRepository = HydrationRepository();

  Future<void> saveHydration(HydrationLog log) async {
    await _hydrationRepository.saveHydration(log);
  }

  Future<List<HydrationLog>> getHydration(String userId) async {
    final parsedUserId = int.tryParse(userId) ?? 1;
    return await _hydrationRepository.getHydrationByUserId(parsedUserId);
  }

  Future<void> saveHydrationGoal(int userId, int waterGoal) async {
    await _hydrationRepository.saveHydrationGoal(userId, waterGoal);
  }

  Future<int> getHydrationGoal(String userId) async {
    final parsedUserId = int.tryParse(userId) ?? 1;
    return await _hydrationRepository.getHydrationGoal(parsedUserId);
  }
}
