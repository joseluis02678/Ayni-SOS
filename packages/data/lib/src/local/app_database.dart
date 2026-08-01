import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Cross-platform local persistence (SharedPreferences JSON).
/// Works on Android, iOS, Windows, and Web (no dart:io).
class AppDatabase {
  AppDatabase();

  SharedPreferences? _prefs;

  Future<SharedPreferences> _sp() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  String _key(String collection) => 'ayni_db_$collection';

  Future<List<Map<String, dynamic>>> _readAll(String collection) async {
    final prefs = await _sp();
    final raw = prefs.getString(_key(collection));
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> _writeAll(String collection, List<Map<String, dynamic>> rows) async {
    final prefs = await _sp();
    await prefs.setString(_key(collection), jsonEncode(rows));
  }

  Future<void> upsertReport(Map<String, dynamic> row) async {
    final rows = await _readAll('reports');
    final idx = rows.indexWhere((r) => r['id'] == row['id']);
    if (idx >= 0) {
      rows[idx] = row;
    } else {
      rows.add(row);
    }
    await _writeAll('reports', rows);
  }

  Future<Map<String, dynamic>?> getReport(String id) async {
    final rows = await _readAll('reports');
    try {
      return rows.firstWhere((r) => r['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> allReports() => _readAll('reports');

  Future<List<Map<String, dynamic>>> pendingReports() async {
    final rows = await allReports();
    return rows
        .where((r) =>
            r['status'] == 'pending_sync' ||
            r['status'] == 'queued' ||
            r['status'] == 'analyzing')
        .toList();
  }

  Future<void> enqueueOutbox(Map<String, dynamic> item) async {
    final rows = await _readAll('sync_outbox');
    rows.add(item);
    await _writeAll('sync_outbox', rows);
  }

  Future<List<Map<String, dynamic>>> outboxPending() async {
    final rows = await _readAll('sync_outbox');
    return rows.where((r) => r['status'] == 'pending').toList();
  }

  Future<void> markOutboxDone(String id) async {
    final rows = await _readAll('sync_outbox');
    for (final r in rows) {
      if (r['id'] == id) r['status'] = 'done';
    }
    await _writeAll('sync_outbox', rows);
  }

  Future<void> saveSession(Map<String, dynamic> session) async {
    await _writeAll('session', [session]);
  }

  Future<Map<String, dynamic>?> getSession() async {
    final rows = await _readAll('session');
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> clearSession() async {
    await _writeAll('session', []);
  }

  Future<void> cacheIncidents(List<Map<String, dynamic>> incidents) async {
    await _writeAll('incidents_cache', incidents);
  }

  Future<List<Map<String, dynamic>>> cachedIncidents() => _readAll('incidents_cache');
}
