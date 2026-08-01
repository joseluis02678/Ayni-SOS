import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:geo_service/geo_service.dart';
import 'package:rescuer_app/injection/injection.dart';
import 'package:ui_kit/ui_kit.dart';

class IncidentDetailScreen extends StatefulWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  EmergencyReport? _report;
  List<Map<String, dynamic>> _assignees = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = getIt<ApiClient>();
    try {
      final res = await api.dio.get('/api/v1/incidents/${widget.incidentId}');
      final repo = ReportRepositoryImpl(getIt<AppDatabase>());
      final report =
          await repo.upsertFromServer(res.data as Map<String, dynamic>);
      final asg =
          await api.dio.get('/api/v1/incidents/${widget.incidentId}/assignees');
      if (mounted) {
        setState(() {
          _report = report;
          _assignees = (asg.data as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {
      final local = await getIt<ReportRepository>().getById(widget.incidentId);
      if (mounted) setState(() => _report = local);
    }
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      await getIt<ApiClient>()
          .dio
          .post('/api/v1/incidents/${widget.incidentId}/accept');
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incidente aceptado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updateStatus(ReportStatus status) async {
    setState(() => _busy = true);
    try {
      await getIt<ApiClient>().dio.patch(
        '/api/v1/incidents/${widget.incidentId}/status',
        data: {'status': status.apiValue},
      );
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del incidente')),
      body: r == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    AyniStatusChip(label: r.status.labelEs),
                    const SizedBox(width: 8),
                    AyniStatusChip(
                      label: priorityLabel(r.priority),
                      color: priorityColor(r.priority),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(r.summary ?? 'Sin resumen',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Ubicación: ${r.location.latitude.toStringAsFixed(5)}, '
                  '${r.location.longitude.toStringAsFixed(5)}',
                ),
                Text('Tipo: ${r.disasterType?.apiValue ?? '—'}'),
                Text('Evidencia: ${r.evidenceType.name}'),
                const SizedBox(height: 24),
                Text('Análisis IA (recomendación)',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (r.analysis != null) ...[
                  Text('Riesgo: ${r.analysis!.riskLevel.name}'),
                  Text('Confianza: ${r.analysis!.confidence.toStringAsFixed(2)}'),
                  Text('Personas estimadas: ${r.analysis!.estimatedPeople}'),
                  Text(
                    'Recursos sugeridos: ${r.analysis!.suggestedResources.join(', ')}',
                  ),
                  if (r.analysis!.transcription != null)
                    Text('Transcripción: ${r.analysis!.transcription}'),
                  if (r.analysis!.visualAnalysis != null) ...[
                    Text(
                      'Agua: ${r.analysis!.visualAnalysis!.waterLevel}, '
                      'Lodo: ${r.analysis!.visualAnalysis!.mudPresent}, '
                      'Derrumbe: ${r.analysis!.visualAnalysis!.landslideVisible}',
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'La IA no toma decisiones finales.',
                    style: TextStyle(
                      color: AyniColors.warning,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ] else
                  const Text('Sin análisis IA disponible'),
                const SizedBox(height: 24),
                Text(
                  'Rescatistas asignados: ${_assignees.length}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ..._assignees.map(
                  (a) => ListTile(
                    dense: true,
                    title: Text(a['rescuer_name'] as String? ?? a['rescuer_id'] as String),
                    subtitle: Text(a['status'] as String? ?? ''),
                  ),
                ),
                const SizedBox(height: 24),
                AyniPrimaryButton(
                  label: 'Aceptar atender',
                  icon: Icons.handshake,
                  isLoading: _busy,
                  onPressed: _accept,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _updateStatus(ReportStatus.inProgress),
                  child: const Text('Marcar en progreso'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _updateStatus(ReportStatus.resolved),
                  child: const Text('Marcar rescate finalizado'),
                ),
              ],
            ),
    );
  }
}
