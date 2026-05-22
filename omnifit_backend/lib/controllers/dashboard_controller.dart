import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:omnifit_backend/services/dashboard_service.dart';

class DashboardController {
  final DashboardService _dashboardService = DashboardService();

  Future<Response> getDashboard(Request req) async {
    try {
      // Securely extract verified userId from decoded token context!
      final userId = req.context['userId'] as int;
      final recommendation = await _dashboardService.getDashboardRecommendation(userId);

      return Response.ok(
        json.encode({'recommendation': recommendation}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Error at Dashboard: $e");
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
