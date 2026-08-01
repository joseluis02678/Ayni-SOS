import 'model_path_stub.dart'
    if (dart.library.io) 'model_path_io.dart' as impl;

/// Resolves on-device Gemma `.litertlm` path if present.
Future<String?> resolveGemmaModelPath() => impl.resolveGemmaModelPath();
