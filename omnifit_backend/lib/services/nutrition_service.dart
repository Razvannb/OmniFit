import 'package:omnifit_backend/models/nutrition.dart';
import 'package:omnifit_backend/repositories/nutrition_repository.dart';

class NutritionService {
  final NutritionRepository _nutritionRepository = NutritionRepository();

  Future<void> saveNutrition(NutritionLog log) async {
    await _nutritionRepository.saveNutrition(log);
  }

  Future<List<NutritionLog>> getNutrition(String userId) async {
    final parsedUserId = int.tryParse(userId) ?? 1;
    return await _nutritionRepository.getNutritionByUserId(parsedUserId);
  }

  Future<void> saveNutritionGoal(int userId, int calorieGoal) async {
    await _nutritionRepository.saveNutritionGoal(userId, calorieGoal);
  }

  Future<int> getNutritionGoal(String userId) async {
    final parsedUserId = int.tryParse(userId) ?? 1;
    return await _nutritionRepository.getNutritionGoal(parsedUserId);
  }
}
