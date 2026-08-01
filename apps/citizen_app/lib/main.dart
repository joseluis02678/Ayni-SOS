import 'package:flutter/material.dart';
import 'package:citizen_app/injection/injection.dart';
import 'package:citizen_app/routes/app_router.dart';
import 'package:ui_kit/ui_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies(
    apiBaseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8000',
    ),
  );
  runApp(const CitizenApp());
}

class CitizenApp extends StatelessWidget {
  const CitizenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ayni SOS',
      debugShowCheckedModeBanner: false,
      theme: buildAyniTheme(),
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
