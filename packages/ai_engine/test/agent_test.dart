import 'dart:typed_data';

import 'package:ai_engine/ai_engine.dart';
import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  test('parseAndValidateAnalysis accepts valid JSON', () {
    const raw = '''
    {
      "evidence_type": "photo",
      "disaster_type": "flood",
      "transcription": null,
      "visual_analysis": {
        "people_visible": 2,
        "water_level": "high",
        "mud_present": true,
        "landslide_visible": false,
        "damaged_homes": 1,
        "vehicles_affected": 0,
        "obstacles": ["debris"]
      },
      "estimated_people": 4,
      "risk_level": "high",
      "suggested_resources": ["boat", "pumps"],
      "priority": 2,
      "summary": "Inundación con personas visibles",
      "confidence": 0.8,
      "ai_disclaimer": "recommendation_only"
    }
    ''';
    final analysis = parseAndValidateAnalysis(raw, evidenceType: EvidenceType.photo);
    expect(analysis.disasterType, DisasterType.flood);
    expect(analysis.priority, 2);
    expect(analysis.visualAnalysis?.waterLevel, 'high');
  });

  test('HeuristicRuntime returns valid analysis via agent', () async {
    final runtime = HeuristicRuntime();
    final agent = EmergencyAgent(runtime);
    await agent.warmUp();
    final result = await agent.analyze(
      EvidenceInput(
        type: EvidenceType.photo,
        locationHint: '-12.04,-77.04',
        imageBytes: Uint8List(2000),
      ),
    );
    expect(result.aiDisclaimer, 'recommendation_only');
    expect(result.priority, inInclusiveRange(1, 5));
  });
}
