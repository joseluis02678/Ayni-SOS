import 'package:flutter/material.dart';
import 'package:core/core.dart';

/// Marker color by priority (1 = highest urgency).
Color priorityColor(int priority) {
  return switch (priority) {
    1 => const Color(0xFFC0392B),
    2 => const Color(0xFFE67E22),
    3 => const Color(0xFFF1C40F),
    4 => const Color(0xFF27AE60),
    _ => const Color(0xFF2E86AB),
  };
}

String priorityLabel(int priority) {
  return switch (priority) {
    1 => 'Crítica',
    2 => 'Alta',
    3 => 'Media',
    4 => 'Baja',
    _ => 'Informativa',
  };
}

class PriorityMarkerMeta {
  const PriorityMarkerMeta({
    required this.reportId,
    required this.latitude,
    required this.longitude,
    required this.priority,
    required this.status,
  });

  final String reportId;
  final double latitude;
  final double longitude;
  final int priority;
  final ReportStatus status;

  Color get color => priorityColor(priority);
}
