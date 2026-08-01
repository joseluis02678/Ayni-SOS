import 'package:flutter/material.dart';
import 'package:citizen_app/injection/injection.dart';
import 'package:citizen_app/routes/app_router.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayni SOS'),
        actions: [
          IconButton(
            tooltip: 'Historial',
            onPressed: () => Navigator.of(context).pushNamed(AppRouter.history),
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Salir',
            onPressed: () async {
              await getIt<AuthRepository>().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(AppRouter.login);
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.sos, size: 96, color: AyniColors.primary),
              const SizedBox(height: 24),
              Text(
                '¿Necesitas ayuda?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Envía una evidencia (audio o foto) con tu ubicación. '
                'La IA analizará el reporte en tu dispositivo.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              AyniPrimaryButton(
                label: 'Pedir ayuda',
                icon: Icons.emergency,
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRouter.newReport),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRouter.history),
                child: const Text('Ver mis solicitudes'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
