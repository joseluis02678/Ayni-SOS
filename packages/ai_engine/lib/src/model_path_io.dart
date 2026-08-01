import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String?> resolveGemmaModelPath() async {
  const override = String.fromEnvironment('GEMMA_MODEL_PATH');
  if (override.isNotEmpty) {
    if (await File(override).exists()) return override;
  }

  final docs = await getApplicationDocumentsDirectory();
  final candidates = <String>[
    '${docs.path}/models/gemma-4-E2B-it.litertlm',
    '${docs.path}/models/gemma-4-E2B-it-qat-mobile.litertlm',
  ];
  for (final path in candidates) {
    if (await File(path).exists()) return path;
  }
  return null;
}
