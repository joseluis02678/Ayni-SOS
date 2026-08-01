import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IncidentFilter {
  const IncidentFilter({
    this.status,
    this.priorityMin,
    this.disasterType,
  });

  final ReportStatus? status;
  final int? priorityMin;
  final DisasterType? disasterType;

  IncidentFilter copyWith({
    ReportStatus? status,
    int? priorityMin,
    DisasterType? disasterType,
    bool clearStatus = false,
  }) {
    return IncidentFilter(
      status: clearStatus ? null : (status ?? this.status),
      priorityMin: priorityMin ?? this.priorityMin,
      disasterType: disasterType ?? this.disasterType,
    );
  }
}

class IncidentState {
  const IncidentState({
    this.incidents = const [],
    this.filter = const IncidentFilter(),
    this.loading = false,
    this.error,
    this.selectedId,
  });

  final List<EmergencyReport> incidents;
  final IncidentFilter filter;
  final bool loading;
  final String? error;
  final String? selectedId;

  List<EmergencyReport> get filtered {
    return incidents.where((r) {
      if (filter.status != null && r.status != filter.status) return false;
      if (filter.priorityMin != null && r.priority > filter.priorityMin!) {
        return false;
      }
      if (filter.disasterType != null && r.disasterType != filter.disasterType) {
        return false;
      }
      return true;
    }).toList();
  }

  IncidentState copyWith({
    List<EmergencyReport>? incidents,
    IncidentFilter? filter,
    bool? loading,
    String? error,
    String? selectedId,
  }) {
    return IncidentState(
      incidents: incidents ?? this.incidents,
      filter: filter ?? this.filter,
      loading: loading ?? this.loading,
      error: error,
      selectedId: selectedId ?? this.selectedId,
    );
  }
}

class IncidentCubit extends Cubit<IncidentState> {
  IncidentCubit(this._api, this._sync, this._db) : super(const IncidentState());

  final ApiClient _api;
  final SyncRepository _sync;
  final AppDatabase _db;

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _sync.pullRemote();
      final res = await _api.dio.get('/api/v1/incidents');
      final list = (res.data as List).cast<Map<String, dynamic>>();
      await _db.cacheIncidents(list);
      final reports = <EmergencyReport>[];
      final repo = ReportRepositoryImpl(_db);
      for (final j in list) {
        reports.add(await repo.upsertFromServer(j));
      }
      reports.sort((a, b) => a.priority.compareTo(b.priority));
      emit(state.copyWith(incidents: reports, loading: false));
    } catch (e) {
      // Offline fallback from cache
      final cached = await _db.cachedIncidents();
      final repo = ReportRepositoryImpl(_db);
      final reports = <EmergencyReport>[];
      for (final j in cached) {
        reports.add(await repo.upsertFromServer(j));
      }
      emit(state.copyWith(
        incidents: reports,
        loading: false,
        error: reports.isEmpty ? e.toString() : null,
      ));
    }
  }

  void applyFilter(IncidentFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  void select(String? id) {
    emit(state.copyWith(selectedId: id));
  }

  void upsertFromEvent(Map<String, dynamic> data) async {
    final repo = ReportRepositoryImpl(_db);
    final report = await repo.upsertFromServer(data);
    final next = [...state.incidents.where((r) => r.serverId != report.serverId)];
    next.add(report);
    next.sort((a, b) => a.priority.compareTo(b.priority));
    emit(state.copyWith(incidents: next));
  }
}
