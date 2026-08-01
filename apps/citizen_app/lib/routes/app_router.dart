import 'package:flutter/material.dart';
import 'package:citizen_app/presentation/auth/login_screen.dart';
import 'package:citizen_app/presentation/auth/register_screen.dart';
import 'package:citizen_app/presentation/history/history_screen.dart';
import 'package:citizen_app/presentation/home/home_screen.dart';
import 'package:citizen_app/presentation/report/new_report_screen.dart';
import 'package:citizen_app/presentation/report/report_status_screen.dart';

class AppRouter {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const newReport = '/report/new';
  static const reportStatus = '/report/status';
  static const history = '/history';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case newReport:
        return MaterialPageRoute(builder: (_) => const NewReportScreen());
      case reportStatus:
        final id = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ReportStatusScreen(reportId: id ?? ''),
        );
      case history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Ruta no encontrada')),
          ),
        );
    }
  }
}
