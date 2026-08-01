import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rescuer_app/injection/injection.dart';
import 'package:rescuer_app/routes/app_router.dart';
import 'package:ui_kit/ui_kit.dart';

class RescuerRegisterScreen extends StatefulWidget {
  const RescuerRegisterScreen({super.key});

  @override
  State<RescuerRegisterScreen> createState() => _RescuerRegisterScreenState();
}

class _RescuerRegisterScreenState extends State<RescuerRegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      await getIt<RegisterUser>()(
        email: _email.text.trim(),
        password: _password.text,
        fullName: _name.text.trim(),
        role: UserRole.rescuer,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRouter.dashboard);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo registrar')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro rescatista')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 24),
          AyniPrimaryButton(
            label: 'Registrar',
            isLoading: _loading,
            onPressed: _register,
          ),
        ],
      ),
    );
  }
}
