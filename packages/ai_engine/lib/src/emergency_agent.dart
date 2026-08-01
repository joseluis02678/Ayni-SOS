import 'dart:typed_data';

import 'package:ai_engine/src/gemma_runtime.dart';
import 'package:ai_engine/src/json_validator.dart';
import 'package:ai_engine/src/prompts.dart';
import 'package:core/core.dart';

class EvidenceInput {
  EvidenceInput({
    required this.type,
    required this.locationHint,
    this.imageBytes,
    this.audioBytes,
  });

  final EvidenceType type;
  final String locationHint;
  final Uint8List? imageBytes;
  final Uint8List? audioBytes;
}

/// Specialized emergency evaluation agent (recommendation only).
class EmergencyAgent {
  EmergencyAgent(this._runtime, {this.maxRetries = 2});

  final GemmaRuntime _runtime;
  final int maxRetries;

  Future<void> warmUp({String modelPath = 'models/gemma-4-E2B-it-qat-mobile'}) {
    return _runtime.loadModel(modelPath: modelPath);
  }

  Future<EmergencyAnalysis> analyze(EvidenceInput input) async {
    final userPrompt = input.type == EvidenceType.audio
        ? buildAudioUserPrompt(locationHint: input.locationHint)
        : buildPhotoUserPrompt(locationHint: input.locationHint);

    Object? lastError;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final raw = await _runtime.generate(
          systemPrompt: kEmergencyAgentSystemPrompt,
          userPrompt: userPrompt,
          imageBytes: input.imageBytes,
          audioBytes: input.audioBytes,
        );
        return parseAndValidateAnalysis(raw, evidenceType: input.type);
      } catch (e) {
        lastError = e;
      }
    }

    // Fallback minimal report so citizen flow never hard-blocks
    return EmergencyAnalysis(
      evidenceType: input.type,
      disasterType: DisasterType.landslide,
      riskLevel: RiskLevel.medium,
      priority: 3,
      summary:
          'Análisis IA incompleto. Se envió ubicación GPS. Revisión humana requerida.',
      confidence: 0.1,
      estimatedPeople: 0,
      suggestedResources: const ['shovel_team'],
      transcription: input.type == EvidenceType.audio ? '' : null,
      visualAnalysis:
          input.type == EvidenceType.photo ? const VisualAnalysis() : null,
    );
  }
}
