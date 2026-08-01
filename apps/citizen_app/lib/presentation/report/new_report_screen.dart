import 'dart:typed_data';

import 'package:ai_engine/ai_engine.dart';
import 'package:citizen_app/injection/injection.dart';
import 'package:citizen_app/presentation/report/evidence_store_io.dart'
    if (dart.library.html) 'package:citizen_app/presentation/report/evidence_store_web.dart';
import 'package:citizen_app/routes/app_router.dart';
import 'package:core/core.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geo_service/geo_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:uuid/uuid.dart';

enum _EvidenceChoice { none, audio, photo }

class NewReportScreen extends StatefulWidget {
  const NewReportScreen({super.key});

  @override
  State<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends State<NewReportScreen> {
  _EvidenceChoice _choice = _EvidenceChoice.none;
  bool _busy = false;
  String _status = '';
  XFile? _evidenceFile;
  final _recorder = AudioRecorder();
  bool _recording = false;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    XFile? file;
    try {
      file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1600,
      );
    } catch (_) {
      file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1600,
      );
    }
    if (file == null) return;
    final stored = await persistEvidenceFile(file, 'jpg');
    setState(() {
      _choice = _EvidenceChoice.photo;
      _evidenceFile = stored;
      _status = 'Foto lista';
    });
  }

  Future<void> _toggleAudio() async {
    if (_recording) {
      final path = await _recorder.stop();
      XFile? stored;
      if (path != null) {
        stored = await persistEvidenceFile(XFile(path), kIsWeb ? 'wav' : 'm4a');
      }
      setState(() {
        _recording = false;
        _choice = _EvidenceChoice.audio;
        _evidenceFile = stored;
        _status = stored != null ? 'Audio listo' : 'No se guardó el audio';
      });
      return;
    }
    if (!await _recorder.hasPermission()) {
      setState(() => _status = 'Permiso de micrófono denegado');
      return;
    }
    final path = kIsWeb
        ? 'ayni_${const Uuid().v4()}.wav'
        : await newAudioCapturePath();
    await _recorder.start(
      RecordConfig(encoder: kIsWeb ? AudioEncoder.wav : AudioEncoder.aacLc),
      path: path,
    );
    setState(() {
      _recording = true;
      _status = 'Grabando… toca de nuevo para detener';
    });
  }

  Future<void> _submit() async {
    if (_evidenceFile == null || _choice == _EvidenceChoice.none) {
      setState(() => _status = 'Selecciona audio o fotografía');
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Obteniendo ubicación GPS…';
    });

    try {
      GeoPoint location;
      try {
        location = await getIt<LocationService>().currentPosition();
      } catch (_) {
        location = const GeoPoint(latitude: -12.0464, longitude: -77.0428);
        setState(() => _status = 'GPS simulado (Lima)…');
      }

      setState(() => _status = 'Analizando con IA local…');

      final bytes = await _evidenceFile!.readAsBytes();
      final hash = sha256.convert(bytes).toString();
      final evidenceType =
          _choice == _EvidenceChoice.audio ? EvidenceType.audio : EvidenceType.photo;

      final agent = getIt<EmergencyAgent>();
      final analysis = await agent.analyze(
        EvidenceInput(
          type: evidenceType,
          locationHint: '${location.latitude},${location.longitude}',
          imageBytes:
              evidenceType == EvidenceType.photo ? Uint8List.fromList(bytes) : null,
          audioBytes:
              evidenceType == EvidenceType.audio ? Uint8List.fromList(bytes) : null,
        ),
      );

      setState(() => _status = 'Guardando y sincronizando…');

      final report = await getIt<CreateEmergencyReport>()(
        evidenceType: evidenceType,
        location: location,
        evidenceLocalPath: _evidenceFile!.path,
        evidenceHash: hash,
        analysis: analysis,
      );

      await getIt<SyncRepository>().processOutbox();

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRouter.reportStatus,
        arguments: report.id,
      );
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva solicitud')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Elige UNA evidencia',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Tu ubicación GPS se compartirá automáticamente.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _EvidenceCard(
                        icon: Icons.mic,
                        label: _recording ? 'Detener' : 'Audio',
                        selected: _choice == _EvidenceChoice.audio,
                        onTap: _busy ? null : _toggleAudio,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _EvidenceCard(
                        icon: Icons.photo_camera,
                        label: 'Fotografía',
                        selected: _choice == _EvidenceChoice.photo,
                        onTap: _busy ? null : _pickPhoto,
                      ),
                    ),
                  ],
                ),
              ),
              if (_evidenceFile != null)
                AyniStatusChip(
                  label: _choice == _EvidenceChoice.audio ? 'Audio listo' : 'Foto lista',
                  color: AyniColors.success,
                ),
              const SizedBox(height: 12),
              if (_status.isNotEmpty) Text(_status, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              AyniPrimaryButton(
                label: 'Enviar solicitud',
                icon: Icons.send,
                isLoading: _busy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AyniColors.primary.withValues(alpha: 0.12) : AyniColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AyniColors.primary : const Color(0xFFD5E0E4),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: AyniColors.textPrimary),
              const SizedBox(height: 16),
              Text(label, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}
