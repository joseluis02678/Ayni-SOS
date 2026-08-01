import 'dart:async';

import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geo_service/geo_service.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:rescuer_app/injection/injection.dart';
import 'package:rescuer_app/presentation/dashboard/incident_cubit.dart';
import 'package:rescuer_app/presentation/dashboard/ws_client.dart';
import 'package:rescuer_app/routes/app_router.dart';
import 'package:ui_kit/ui_kit.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final IncidentCubit _cubit;
  late final RescuerWsClient _ws;
  StreamSubscription? _sub;
  MapLibreMapController? _map;
  bool _panelOpen = true;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<IncidentCubit>();
    _ws = getIt<RescuerWsClient>();
    _cubit.load();
    _ws.connect();
    _sub = _ws.events.listen((event) {
      final type = event['event'] as String?;
      if (type == 'incident.created' || type == 'incident.updated') {
        final data = event['data'] as Map<String, dynamic>?;
        if (data != null) _cubit.upsertFromEvent(data);
      }
    });
    _heartbeatLocation();
  }

  Future<void> _heartbeatLocation() async {
    try {
      final loc = await getIt<LocationService>().currentPosition();
      await getIt<ApiClient>().dio.patch('/api/v1/locations/rescuer', data: {
        'latitude': loc.latitude,
        'longitude': loc.longitude,
      });
    } catch (_) {}
  }

  Future<void> _syncMarkers(List<EmergencyReport> incidents) async {
    final controller = _map;
    if (controller == null) return;
    await controller.clearSymbols();
    for (final r in incidents) {
      await controller.addSymbol(
        SymbolOptions(
          geometry: LatLng(r.location.latitude, r.location.longitude),
          iconImage: 'marker-15',
          iconSize: 1.4,
          textField: 'P${r.priority}',
          textOffset: const Offset(0, 1.2),
          textColor: '#FFFFFF',
          iconColor: _hex(priorityColor(r.priority)),
        ),
      );
    }
  }

  String _hex(Color c) {
    final r = ((c.r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final g = ((c.g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final b = ((c.b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ws.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapConfig = getIt<OfflineMapConfig>();
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard rescatista'),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.history),
            ),
            IconButton(
              icon: Icon(_panelOpen ? Icons.view_sidebar : Icons.list),
              onPressed: () => setState(() => _panelOpen = !_panelOpen),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _cubit.load(),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await getIt<AuthRepository>().logout();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushReplacementNamed(AppRouter.login);
                }
              },
            ),
          ],
        ),
        body: BlocConsumer<IncidentCubit, IncidentState>(
          listener: (context, state) {
            _syncMarkers(state.filtered);
          },
          builder: (context, state) {
            return Row(
              children: [
                Expanded(
                  flex: 7,
                  child: MapLibreMap(
                    styleString: mapConfig.styleUrl,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        mapConfig.initialLatitude,
                        mapConfig.initialLongitude,
                      ),
                      zoom: mapConfig.initialZoom,
                    ),
                    onMapCreated: (c) {
                      _map = c;
                      _syncMarkers(state.filtered);
                    },
                    myLocationEnabled: true,
                    compassEnabled: true,
                  ),
                ),
                if (_panelOpen)
                  Expanded(
                    flex: 3,
                    child: _IncidentPanel(
                      state: state,
                      onFilter: _cubit.applyFilter,
                      onSelect: (id) {
                        _cubit.select(id);
                        Navigator.of(context).pushNamed(
                          AppRouter.incidentDetail,
                          arguments: id,
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IncidentPanel extends StatelessWidget {
  const _IncidentPanel({
    required this.state,
    required this.onFilter,
    required this.onSelect,
  });

  final IncidentState state;
  final void Function(IncidentFilter) onFilter;
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AyniColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Incidentes (${state.filtered.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: state.filter.status == null,
                  onSelected: (_) =>
                      onFilter(state.filter.copyWith(clearStatus: true)),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Recibidos'),
                  selected: state.filter.status == ReportStatus.received,
                  onSelected: (_) => onFilter(
                    state.filter.copyWith(status: ReportStatus.received),
                  ),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Alta prioridad'),
                  selected: state.filter.priorityMin == 2,
                  onSelected: (_) => onFilter(
                    IncidentFilter(
                      status: state.filter.status,
                      priorityMin: state.filter.priorityMin == 2 ? null : 2,
                      disasterType: state.filter.disasterType,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (state.loading) const LinearProgressIndicator(),
          Expanded(
            child: state.filtered.isEmpty
                ? const AyniEmptyState(message: 'Sin incidentes')
                : ListView.builder(
                    itemCount: state.filtered.length,
                    itemBuilder: (context, i) {
                      final r = state.filtered[i];
                      final id = r.serverId ?? r.id;
                      return ListTile(
                        selected: state.selectedId == id,
                        leading: CircleAvatar(
                          backgroundColor: priorityColor(r.priority),
                          radius: 8,
                        ),
                        title: Text(
                          r.summary ?? 'Incidente',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${r.status.labelEs} · P${r.priority} · '
                          '${r.assigneeCount} rescatistas',
                        ),
                        onTap: () => onSelect(id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
