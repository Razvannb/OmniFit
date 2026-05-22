import 'package:omnifit_backend/models/goal.dart';
import 'package:omnifit_backend/repositories/goals_repository.dart';

class GoalsService {
  final GoalsRepository _goalsRepository = GoalsRepository();

  Future<void> saveGoal(Goal goal) async {
    await _goalsRepository.saveGoal(goal);
  }

  Future<List<Goal>> getGoals(int userId) async {
    return await _goalsRepository.getGoalsByUserId(userId);
  }
}
