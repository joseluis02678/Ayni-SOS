import 'dart:typed_data';

import 'package:core/core.dart';

/// Abstraction over on-device LLM runtimes (LiteRT-LM / MediaPipe / llama.cpp).
abstract class GemmaRuntime {
  Future<bool> get isReady;

  /// Load quantized Gemma 4 E2B QAT mobile weights (~1.1 GB).
  Future<void> loadModel({required String modelPath});

  Future<String> generate({
    required String systemPrompt,
    required String userPrompt,
    Uint8List? imageBytes,
    Uint8List? audioBytes,
  });

  Future<void> dispose();
}

/// Stub that documents the production integration surface.
/// Wire LiteRT-LM via MethodChannel / FFI in Android module.
class LiteRtGemmaRuntime implements GemmaRuntime {
  bool _ready = false;
  String? _modelPath;

  @override
  Future<bool> get isReady async => _ready;

  @override
  Future<void> loadModel({required String modelPath}) async {
    _modelPath = modelPath;
    // Production: invoke native LiteRT-LM with gemma-4-E2B-it-qat-mobile
    _ready = true;
  }

  @override
  Future<String> generate({
    required String systemPrompt,
    required String userPrompt,
    Uint8List? imageBytes,
    Uint8List? audioBytes,
  }) async {
    if (!_ready) {
      throw StateError('Gemma model not loaded (path=$_modelPath)');
    }
    // Placeholder until native FFI is linked — callers should use
    // HeuristicRuntime for emulator/dev without the 1.1 GB model.
    throw UnimplementedError(
      'LiteRT-LM FFI not linked. Use HeuristicRuntime for development '
      'or provide a native Gemma 4 E2B QAT mobile binding.',
    );
  }

  @override
  Future<void> dispose() async {
    _ready = false;
  }
}
