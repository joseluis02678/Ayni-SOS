import 'package:citizen_app/injection/injection.dart';
import 'package:citizen_app/routes/app_router.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:geo_service/geo_service.dart';
import 'package:ui_kit/ui_kit.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<EmergencyReport> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await getIt<ReportRepository>().getHistory();
    if (mounted) setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: _items.isEmpty
          ? const AyniEmptyState(
              message: 'Aún no tienes solicitudes',
              icon: Icons.inbox_outlined,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final r = _items[i];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(r.summary ?? 'Solicitud ${r.id.substring(0, 8)}'),
                      subtitle: Text(
                        '${r.status.labelEs} · ${priorityLabel(r.priority)}',
                      ),
                      trailing: Icon(
                        Icons.circle,
                        size: 14,
                        color: priorityColor(r.priority),
                      ),
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRouter.reportStatus,
                        arguments: r.id,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
