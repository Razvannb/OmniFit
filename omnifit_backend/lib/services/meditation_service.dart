import 'package:omnifit_backend/models/meditation.dart';
import 'package:omnifit_backend/repositories/meditation_repository.dart';

class MeditationService {
  final MeditationRepository _meditationRepository = MeditationRepository();

  Future<void> saveMeditation(MeditationLog log) async {
    await _meditationRepository.saveMeditation(log);
  }

  Future<List<MeditationLog>> getMeditation(String userId) async {
    final parsedUserId = int.tryParse(userId) ?? 1;
    return await _meditationRepository.getMeditationByUserId(parsedUserId);
  }

  Future<void> saveMeditationGoal(int userId, int minutesGoal) async {
    await _meditationRepository.saveMeditationGoal(userId, minutesGoal);
  }

  Future<int> getMeditationGoal(String userId) async {
    final parsedUserId = int.tryParse(userId) ?? 1;
    return await _meditationRepository.getMeditationGoal(parsedUserId);
  }
}
