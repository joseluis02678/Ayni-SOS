import 'package:equatable/equatable.dart';
import 'package:core/src/domain/value_objects/enums.dart';

class VisualAnalysis extends Equatable {
  const VisualAnalysis({
    this.peopleVisible = 0,
    this.waterLevel = 'none',
    this.mudPresent = false,
    this.landslideVisible = false,
    this.damagedHomes = 0,
    this.vehiclesAffected = 0,
    this.obstacles = const [],
  });

  final int peopleVisible;
  final String waterLevel;
  final bool mudPresent;
  final bool landslideVisible;
  final int damagedHomes;
  final int vehiclesAffected;
  final List<String> obstacles;

  Map<String, dynamic> toJson() => {
        'people_visible': peopleVisible,
        'water_level': waterLevel,
        'mud_present': mudPresent,
        'landslide_visible': landslideVisible,
        'damaged_homes': damagedHomes,
        'vehicles_affected': vehiclesAffected,
        'obstacles': obstacles,
      };

  factory VisualAnalysis.fromJson(Map<String, dynamic> json) => VisualAnalysis(
        peopleVisible: (json['people_visible'] as num?)?.toInt() ?? 0,
        waterLevel: json['water_level'] as String? ?? 'none',
        mudPresent: json['mud_present'] as bool? ?? false,
        landslideVisible: json['landslide_visible'] as bool? ?? false,
        damagedHomes: (json['damaged_homes'] as num?)?.toInt() ?? 0,
        vehiclesAffected: (json['vehicles_affected'] as num?)?.toInt() ?? 0,
        obstacles: (json['obstacles'] as List?)?.cast<String>() ?? const [],
      );

  @override
  List<Object?> get props => [
        peopleVisible,
        waterLevel,
        mudPresent,
        landslideVisible,
        damagedHomes,
        vehiclesAffected,
        obstacles,
      ];
}

class EmergencyAnalysis extends Equatable {
  const EmergencyAnalysis({
    required this.evidenceType,
    required this.disasterType,
    required this.riskLevel,
    required this.priority,
    required this.summary,
    required this.confidence,
    this.transcription,
    this.visualAnalysis,
    this.estimatedPeople = 0,
    this.suggestedResources = const [],
    this.aiDisclaimer = 'recommendation_only',
  });

  final EvidenceType evidenceType;
  final DisasterType disasterType;
  final RiskLevel riskLevel;
  final int priority;
  final String summary;
  final double confidence;
  final String? transcription;
  final VisualAnalysis? visualAnalysis;
  final int estimatedPeople;
  final List<String> suggestedResources;
  final String aiDisclaimer;

  Map<String, dynamic> toJson() => {
        'evidence_type': evidenceType.name,
        'disaster_type': disasterType.apiValue,
        'transcription': transcription,
        'visual_analysis': visualAnalysis?.toJson(),
        'estimated_people': estimatedPeople,
        'risk_level': riskLevel.name,
        'suggested_resources': suggestedResources,
        'priority': priority,
        'summary': summary,
        'confidence': confidence,
        'ai_disclaimer': aiDisclaimer,
      };

  factory EmergencyAnalysis.fromJson(Map<String, dynamic> json) {
    DisasterType parseDisaster(String? v) => switch (v) {
          'flood' => DisasterType.flood,
          'el_nino_related' => DisasterType.elNinoRelated,
          _ => DisasterType.landslide,
        };
    RiskLevel parseRisk(String? v) => switch (v) {
          'medium' => RiskLevel.medium,
          'high' => RiskLevel.high,
          'critical' => RiskLevel.critical,
          _ => RiskLevel.low,
        };

    return EmergencyAnalysis(
      evidenceType: (json['evidence_type'] as String?) == 'audio'
          ? EvidenceType.audio
          : EvidenceType.photo,
      disasterType: parseDisaster(json['disaster_type'] as String?),
      riskLevel: parseRisk(json['risk_level'] as String?),
      priority: (json['priority'] as num?)?.toInt() ?? 3,
      summary: json['summary'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      transcription: json['transcription'] as String?,
      visualAnalysis: json['visual_analysis'] is Map<String, dynamic>
          ? VisualAnalysis.fromJson(json['visual_analysis'] as Map<String, dynamic>)
          : null,
      estimatedPeople: (json['estimated_people'] as num?)?.toInt() ?? 0,
      suggestedResources:
          (json['suggested_resources'] as List?)?.cast<String>() ?? const [],
      aiDisclaimer: json['ai_disclaimer'] as String? ?? 'recommendation_only',
    );
  }

  @override
  List<Object?> get props => [
        evidenceType,
        disasterType,
        riskLevel,
        priority,
        summary,
        confidence,
        transcription,
        visualAnalysis,
        estimatedPeople,
        suggestedResources,
      ];
}
