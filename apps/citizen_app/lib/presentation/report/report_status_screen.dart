import 'package:citizen_app/injection/injection.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:geo_service/geo_service.dart';
import 'package:ui_kit/ui_kit.dart';

class ReportStatusScreen extends StatefulWidget {
  const ReportStatusScreen({super.key, required this.reportId});

  final String reportId;

  @override
  State<ReportStatusScreen> createState() => _ReportStatusScreenState();
}

class _ReportStatusScreenState extends State<ReportStatusScreen> {
  EmergencyReport? _report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final report = await getIt<ReportRepository>().getById(widget.reportId);
    if (mounted) setState(() => _report = report);
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    return Scaffold(
      appBar: AppBar(title: const Text('Estado de solicitud')),
      body: r == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                AyniStatusChip(label: r.status.labelEs),
                const SizedBox(height: 16),
                Text('Prioridad: ${priorityLabel(r.priority)}',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  r.summary ?? 'Sin resumen',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                if (r.analysis != null) ...[
                  Text('Análisis IA (recomendación)',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Riesgo: ${r.analysis!.riskLevel.name}'),
                  Text('Personas estimadas: ${r.analysis!.estimatedPeople}'),
                  Text(
                    'Recursos: ${r.analysis!.suggestedResources.join(', ')}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r.analysis!.aiDisclaimer,
                    style: const TextStyle(
                      color: AyniColors.warning,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Ubicación: ${r.location.latitude.toStringAsFixed(5)}, '
                  '${r.location.longitude.toStringAsFixed(5)}',
                ),
                const SizedBox(height: 8),
                Text('Canal: ${r.syncChannel?.name ?? 'pendiente'}'),
                const SizedBox(height: 24),
                AyniPrimaryButton(
                  label: 'Actualizar',
                  onPressed: () async {
                    await getIt<SyncRepository>().pullRemote();
                    await _load();
                  },
                ),
              ],
            ),
    );
  }
}
