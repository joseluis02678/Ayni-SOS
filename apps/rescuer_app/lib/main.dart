import 'package:flutter/material.dart';
import 'package:rescuer_app/injection/injection.dart';
import 'package:rescuer_app/routes/app_router.dart';
import 'package:ui_kit/ui_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies(
    apiBaseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8000',
    ),
  );
  runApp(const RescuerApp());
}

class RescuerApp extends StatelessWidget {
  const RescuerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ayni SOS Rescatista',
      debugShowCheckedModeBanner: false,
      theme: buildAyniTheme(),
      initialRoute: AppRouter.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
