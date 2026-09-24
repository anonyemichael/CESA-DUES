import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../constants/enums.dart';

/// Immutable audit log entry for administrative actions.
class AuditLog extends Equatable {
  const AuditLog({
    required this.id,
    required this.actor,
    required this.actorRole,
    required this.action,
    this.target,
    this.targetType,
    this.metadata,
    required this.timestamp,
  });

  final String id;
  final String actor; // email or system identifier
  final UserRole actorRole;
  final AuditAction action;
  final String? target; // resource path e.g. "students/CE2024001"
  final String? targetType;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  factory AuditLog.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AuditLog(
      id: doc.id,
      actor: data['actor'] as String,
      actorRole: UserRole.fromValue(data['actorRole'] as String),
      action: AuditAction.fromValue(data['action'] as String),
      target: data['target'] as String?,
      targetType: data['targetType'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'actor': actor,
      'actorRole': actorRole.value,
      'action': action.value,
      if (target != null) 'target': target,
      if (targetType != null) 'targetType': targetType,
      if (metadata != null) 'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  @override
  List<Object?> get props => [id, actor, action, timestamp];
}
