import 'package:flutter/material.dart';
import 'package:rescuer_app/presentation/auth/login_screen.dart';
import 'package:rescuer_app/presentation/auth/register_screen.dart';
import 'package:rescuer_app/presentation/dashboard/dashboard_screen.dart';
import 'package:rescuer_app/presentation/history/history_screen.dart';
import 'package:rescuer_app/presentation/incident_detail/incident_detail_screen.dart';

class AppRouter {
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const incidentDetail = '/incident';
  static const history = '/history';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const RescuerLoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RescuerRegisterScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case incidentDetail:
        final id = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => IncidentDetailScreen(incidentId: id),
        );
      case history:
        return MaterialPageRoute(builder: (_) => const RescuerHistoryScreen());
      default:
        return MaterialPageRoute(builder: (_) => const RescuerLoginScreen());
    }
  }
}
