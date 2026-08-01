import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_engine/src/gemma_runtime.dart';
import 'package:core/core.dart';

/// Deterministic heuristic "model" for prototypes without the 1.1 GB weights.
/// Produces valid structured JSON so the rest of the pipeline can be tested.
class HeuristicRuntime implements GemmaRuntime {
  bool _ready = false;
  EvidenceType? _hintType;

  void setEvidenceHint(EvidenceType type) => _hintType = type;

  @override
  Future<bool> get isReady async => _ready;

  @override
  Future<void> loadModel({required String modelPath}) async {
    _ready = true;
  }

  @override
  Future<String> generate({
    required String systemPrompt,
    required String userPrompt,
    Uint8List? imageBytes,
    Uint8List? audioBytes,
  }) async {
    final isAudio = audioBytes != null ||
        _hintType == EvidenceType.audio ||
        userPrompt.toLowerCase().contains('audio');
    final sizeHint = (imageBytes?.length ?? 0) + (audioBytes?.length ?? 0);

    // Simple heuristics for demo: larger evidence → higher urgency signal
    final priority = sizeHint > 500000
        ? 1
        : sizeHint > 100000
            ? 2
            : 3;
    final risk = priority <= 1
        ? 'critical'
        : priority == 2
            ? 'high'
            : 'medium';

    final map = <String, dynamic>{
      'evidence_type': isAudio ? 'audio' : 'photo',
      'disaster_type': userPrompt.toLowerCase().contains('inund')
          ? 'flood'
          : userPrompt.toLowerCase().contains('niño') ||
                  userPrompt.toLowerCase().contains('nino')
              ? 'el_nino_related'
              : 'landslide',
      'transcription': isAudio
          ? 'Transcripción heurística: se reporta emergencia con posible '
              'afectación a viviendas y personas en la zona.'
          : null,
      'visual_analysis': isAudio
          ? null
          : {
              'people_visible': priority <= 2 ? 3 : 1,
              'water_level': priority <= 2 ? 'high' : 'medium',
              'mud_present': true,
              'landslide_visible': true,
              'damaged_homes': priority <= 2 ? 2 : 0,
              'vehicles_affected': 1,
              'obstacles': ['debris', 'mud'],
            },
      'estimated_people': priority <= 2 ? 5 : 2,
      'risk_level': risk,
      'suggested_resources': priority <= 2
          ? ['shovel_team', 'ambulance', 'heavy_machinery']
          : ['shovel_team'],
      'priority': priority,
      'summary': isAudio
          ? 'Reporte de audio analizado localmente. Posible huaico/inundación. '
              'Recomendación solo — decisión humana requerida.'
          : 'Fotografía analizada localmente. Señales de lodo/agua/afectación. '
              'Recomendación solo — decisión humana requerida.',
      'confidence': 0.55,
      'ai_disclaimer': 'recommendation_only',
    };

    // Simulate inference latency
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return jsonEncode(map);
  }

  @override
  Future<void> dispose() async {
    _ready = false;
  }
}
