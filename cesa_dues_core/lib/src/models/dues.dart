import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../constants/enums.dart';

/// Departmental dues configuration for an academic year.
class Dues extends Equatable {
  const Dues({
    required this.id,
    required this.name,
    required this.amount,
    required this.academicYear,
    required this.applicableLevels,
    this.description,
    this.deadline,
    this.status = DuesStatus.active,
    this.createdBy,
    this.version = 1,
    this.previousVersions = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final int amount; // in pesewas (GH₵50 = 5000)
  final String academicYear;
  final List<int> applicableLevels;
  final String? description;
  final DateTime? deadline;
  final DuesStatus status;
  final String? createdBy;
  final int version;
  final List<Map<String, dynamic>> previousVersions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Amount in major currency units (cedis).
  double get amountInCedis => amount / 100;

  bool get isActive => status == DuesStatus.active;

  bool isApplicableToLevel(int level) => applicableLevels.contains(level);

  factory Dues.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Dues(
      id: doc.id,
      name: data['name'] as String,
      amount: data['amount'] as int,
      academicYear: data['academicYear'] as String,
      applicableLevels: List<int>.from(data['applicableLevels'] as List),
      description: data['description'] as String?,
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      status: DuesStatus.fromValue(data['status'] as String? ?? 'active'),
      createdBy: data['createdBy'] as String?,
      version: data['version'] as int? ?? 1,
      previousVersions: List<Map<String, dynamic>>.from(
        data['previousVersions'] as List? ?? [],
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'amount': amount,
      'academicYear': academicYear,
      'applicableLevels': applicableLevels,
      if (description != null) 'description': description,
      if (deadline != null) 'deadline': Timestamp.fromDate(deadline!),
      'status': status.value,
      if (createdBy != null) 'createdBy': createdBy,
      'version': version,
      'previousVersions': previousVersions,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Dues copyWith({
    String? id,
    String? name,
    int? amount,
    String? academicYear,
    List<int>? applicableLevels,
    String? description,
    DateTime? deadline,
    DuesStatus? status,
    String? createdBy,
    int? version,
    List<Map<String, dynamic>>? previousVersions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Dues(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      academicYear: academicYear ?? this.academicYear,
      applicableLevels: applicableLevels ?? this.applicableLevels,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      version: version ?? this.version,
      previousVersions: previousVersions ?? this.previousVersions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        amount,
        academicYear,
        applicableLevels,
        description,
        deadline,
        status,
        version,
      ];
}
