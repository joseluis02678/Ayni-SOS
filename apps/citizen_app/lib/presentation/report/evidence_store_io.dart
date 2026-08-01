import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

Future<XFile> persistEvidenceFile(XFile source, String extension) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/evidence');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final destPath = '${dir.path}/${const Uuid().v4()}.$extension';
  await source.saveTo(destPath);
  return XFile(destPath);
}

Future<String> newAudioCapturePath() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/evidence');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return '${dir.path}/ayni_${const Uuid().v4()}.m4a';
}
