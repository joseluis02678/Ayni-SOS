import 'dart:convert';

import 'package:core/core.dart';

class AnalysisValidationException implements Exception {
  AnalysisValidationException(this.message);
  final String message;
  @override
  String toString() => 'AnalysisValidationException: $message';
}

/// Validates and parses model output into [EmergencyAnalysis].
EmergencyAnalysis parseAndValidateAnalysis(
  String raw, {
  required EvidenceType evidenceType,
}) {
  var text = raw.trim();
  // Strip accidental markdown fences
  if (text.startsWith('```')) {
    text = text.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
    text = text.replaceFirst(RegExp(r'\s*```$'), '');
  }

  late final Map<String, dynamic> json;
  try {
    json = jsonDecode(text) as Map<String, dynamic>;
  } catch (e) {
    throw AnalysisValidationException('Invalid JSON: $e');
  }

  json['evidence_type'] = evidenceType.name;

  final disaster = json['disaster_type'] as String?;
  if (disaster == null ||
      !['landslide', 'flood', 'el_nino_related'].contains(disaster)) {
    throw AnalysisValidationException('Invalid disaster_type: $disaster');
  }

  final priority = (json['priority'] as num?)?.toInt();
  if (priority == null || priority < 1 || priority > 5) {
    throw AnalysisValidationException('Invalid priority: $priority');
  }

  final risk = json['risk_level'] as String?;
  if (risk == null || !['low', 'medium', 'high', 'critical'].contains(risk)) {
    throw AnalysisValidationException('Invalid risk_level: $risk');
  }

  json.putIfAbsent('ai_disclaimer', () => 'recommendation_only');
  json.putIfAbsent('confidence', () => 0.5);
  json.putIfAbsent('summary', () => '');
  json.putIfAbsent('suggested_resources', () => <String>[]);
  json.putIfAbsent('estimated_people', () => 0);

  return EmergencyAnalysis.fromJson(json);
}
