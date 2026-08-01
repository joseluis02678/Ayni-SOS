import 'package:core/src/domain/entities/report.dart';

abstract class SyncRepository {
  Future<void> enqueue(EmergencyReport report);

  Future<void> processOutbox();

  Future<void> pullRemote({DateTime? since});
}
