import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:rescuer_app/injection/injection.dart';
import 'package:rescuer_app/routes/app_router.dart';
import 'package:ui_kit/ui_kit.dart';

class RescuerHistoryScreen extends StatefulWidget {
  const RescuerHistoryScreen({super.key});

  @override
  State<RescuerHistoryScreen> createState() => _RescuerHistoryScreenState();
}

class _RescuerHistoryScreenState extends State<RescuerHistoryScreen> {
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await getIt<ApiClient>().dio.get('/api/v1/assignments/mine');
      if (mounted) {
        setState(() => _items = (res.data as List).cast<Map<String, dynamic>>());
      }
    } catch (_) {
      if (mounted) setState(() => _items = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de rescates')),
      body: _items.isEmpty
          ? const AyniEmptyState(message: 'Sin asignaciones aún')
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final a = _items[i];
                return ListTile(
                  title: Text('Reporte ${a['report_id']}'),
                  subtitle: Text('${a['status']} · ${a['accepted_at']}'),
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRouter.incidentDetail,
                    arguments: a['report_id'] as String,
                  ),
                );
              },
            ),
    );
  }
}
