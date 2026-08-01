import 'package:equatable/equatable.dart';
import 'package:core/src/domain/value_objects/enums.dart';

class RescueAssignment extends Equatable {
  const RescueAssignment({
    required this.id,
    required this.reportId,
    required this.rescuerId,
    required this.status,
    required this.acceptedAt,
    this.rescuerName,
  });

  final String id;
  final String reportId;
  final String rescuerId;
  final AssignmentStatus status;
  final DateTime acceptedAt;
  final String? rescuerName;

  @override
  List<Object?> get props => [id, reportId, rescuerId, status, acceptedAt, rescuerName];
}
