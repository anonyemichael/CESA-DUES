import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../constants/enums.dart';

/// Academic year record.
class AcademicYear extends Equatable {
  const AcademicYear({
    required this.id,
    required this.label,
    this.status = AcademicYearStatus.active,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  final String id; // e.g. "2026_2027"
  final String label; // e.g. "2026/2027"
  final AcademicYearStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == AcademicYearStatus.active;

  factory AcademicYear.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AcademicYear(
      id: doc.id,
      label: data['label'] as String,
      status: AcademicYearStatus.fromValue(
        data['status'] as String? ?? 'active',
      ),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'label': label,
      'status': status.value,
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [id, label, status];
}
