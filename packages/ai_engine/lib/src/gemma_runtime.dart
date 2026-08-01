import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter/services.dart';

/// Abstraction over on-device LLM runtimes (LiteRT-LM / MediaPipe / llama.cpp).
abstract class GemmaRuntime {
  Future<bool> get isReady;

  /// Load quantized Gemma 4 E2B weights (`.litertlm`, ~2–3 GB).
  Future<void> loadModel({required String modelPath});

  Future<String> generate({
    required String systemPrompt,
    required String userPrompt,
    Uint8List? imageBytes,
    Uint8List? audioBytes,
  });

  Future<void> dispose();
}

/// Production path: Dart ↔ Android MethodChannel ↔ LiteRT-LM native Engine.
class LiteRtGemmaRuntime implements GemmaRuntime {
  static const MethodChannel _channel = MethodChannel('pe.ayni.sos/gemma');

  bool _ready = false;
  String? _modelPath;

  @override
  Future<bool> get isReady async => _ready;

  @override
  Future<void> loadModel({required String modelPath}) async {
    _modelPath = modelPath;
    try {
      final ok = await _channel.invokeMethod<bool>('loadModel', {
        'modelPath': modelPath,
      });
      _ready = ok == true;
    } on MissingPluginException {
      _ready = false;
      rethrow;
    } on PlatformException {
      _ready = false;
      rethrow;
    }
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
    final result = await _channel.invokeMethod<String>('generate', {
      'systemPrompt': systemPrompt,
      'userPrompt': userPrompt,
      'imageBytes': imageBytes,
      'audioBytes': audioBytes,
    });
    if (result == null || result.trim().isEmpty) {
      throw StateError('LiteRT returned empty generation');
    }
    return result;
  }

  @override
  Future<void> dispose() async {
    try {
      await _channel.invokeMethod<void>('dispose');
    } catch (_) {}
    _ready = false;
  }
}

/// Tries [primary] then falls back to [fallback] (typically HeuristicRuntime).
class FallbackGemmaRuntime implements GemmaRuntime {
  FallbackGemmaRuntime({
    required this.primary,
    required this.fallback,
  }) : _active = fallback;

  final GemmaRuntime primary;
  final GemmaRuntime fallback;
  GemmaRuntime _active;

  @override
  Future<bool> get isReady async => _active.isReady;

  @override
  Future<void> loadModel({required String modelPath}) async {
    try {
      await primary.loadModel(modelPath: modelPath);
      if (await primary.isReady) {
        _active = primary;
        return;
      }
    } catch (_) {}
    await fallback.loadModel(modelPath: modelPath);
    _active = fallback;
  }

  @override
  Future<String> generate({
    required String systemPrompt,
    required String userPrompt,
    Uint8List? imageBytes,
    Uint8List? audioBytes,
  }) async {
    try {
      return await _active.generate(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        imageBytes: imageBytes,
        audioBytes: audioBytes,
      );
    } catch (_) {
      if (!identical(_active, fallback)) {
        _active = fallback;
        await fallback.loadModel(modelPath: 'heuristic');
        return fallback.generate(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          imageBytes: imageBytes,
          audioBytes: audioBytes,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    await primary.dispose();
    await fallback.dispose();
  }
}
