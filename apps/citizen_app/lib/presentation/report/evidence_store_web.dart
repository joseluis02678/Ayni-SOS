import 'package:cross_file/cross_file.dart';
import 'package:uuid/uuid.dart';

Future<XFile> persistEvidenceFile(XFile source, String extension) async => source;

Future<String> newAudioCapturePath() async =>
    'ayni_${const Uuid().v4()}.wav';
