import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rescuer_app/injection/injection.dart';
import 'package:rescuer_app/routes/app_router.dart';
import 'package:ui_kit/ui_kit.dart';

class RescuerLoginScreen extends StatefulWidget {
  const RescuerLoginScreen({super.key});

  @override
  State<RescuerLoginScreen> createState() => _RescuerLoginScreenState();
}

class _RescuerLoginScreenState extends State<RescuerLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await getIt<LoginUser>()(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (session.user.role != UserRole.rescuer &&
          session.user.role != UserRole.admin) {
        setState(() => _error = 'Esta app es solo para rescatistas');
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRouter.dashboard);
    } catch (_) {
      setState(() => _error = 'Credenciales inválidas');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text('Ayni SOS', style: Theme.of(context).textTheme.headlineLarge),
              Text('Panel de rescatista',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 32),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Correo'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AyniColors.critical)),
              ],
              const SizedBox(height: 24),
              AyniPrimaryButton(
                label: 'Entrar',
                isLoading: _loading,
                onPressed: _login,
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRouter.register),
                child: const Text('Registrar rescatista'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
