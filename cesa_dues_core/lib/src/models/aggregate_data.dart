import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Pre-computed aggregate data for dashboard display.
/// Updated by Cloud Functions on payment success and student import.
/// Avoids scanning entire collections on every dashboard load.
class AggregateData extends Equatable {
  const AggregateData({
    required this.academicYear,
    this.totalStudents = 0,
    this.paidStudents = 0,
    this.unpaidStudents = 0,
    this.expectedAmount = 0,
    this.collectedAmount = 0,
    this.outstandingAmount = 0,
    this.byLevel = const {},
    this.lastUpdatedAt,
  });

  final String academicYear;
  final int totalStudents;
  final int paidStudents;
  final int unpaidStudents;
  final int expectedAmount; // pesewas
  final int collectedAmount; // pesewas
  final int outstandingAmount; // pesewas
  final Map<String, LevelAggregate> byLevel;
  final DateTime? lastUpdatedAt;

  double get collectedInCedis => collectedAmount / 100;
  double get expectedInCedis => expectedAmount / 100;
  double get outstandingInCedis => outstandingAmount / 100;

  double get collectionPercentage =>
      totalStudents > 0 ? (paidStudents / totalStudents) * 100 : 0;

  factory AggregateData.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final byLevelRaw = data['byLevel'] as Map<String, dynamic>? ?? {};
    final byLevel = byLevelRaw.map(
      (key, value) => MapEntry(
        key,
        LevelAggregate.fromMap(value as Map<String, dynamic>),
      ),
    );

    return AggregateData(
      academicYear: data['academicYear'] as String,
      totalStudents: data['totalStudents'] as int? ?? 0,
      paidStudents: data['paidStudents'] as int? ?? 0,
      unpaidStudents: data['unpaidStudents'] as int? ?? 0,
      expectedAmount: data['expectedAmount'] as int? ?? 0,
      collectedAmount: data['collectedAmount'] as int? ?? 0,
      outstandingAmount: data['outstandingAmount'] as int? ?? 0,
      byLevel: byLevel,
      lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'academicYear': academicYear,
      'totalStudents': totalStudents,
      'paidStudents': paidStudents,
      'unpaidStudents': unpaidStudents,
      'expectedAmount': expectedAmount,
      'collectedAmount': collectedAmount,
      'outstandingAmount': outstandingAmount,
      'byLevel': byLevel.map((key, value) => MapEntry(key, value.toMap())),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [
        academicYear,
        totalStudents,
        paidStudents,
        collectedAmount,
      ];
}

/// Aggregate data for a single academic level.
class LevelAggregate extends Equatable {
  const LevelAggregate({
    this.total = 0,
    this.paid = 0,
    this.collected = 0,
  });

  final int total;
  final int paid;
  final int collected; // pesewas

  int get unpaid => total - paid;
  double get collectedInCedis => collected / 100;

  factory LevelAggregate.fromMap(Map<String, dynamic> map) {
    return LevelAggregate(
      total: map['total'] as int? ?? 0,
      paid: map['paid'] as int? ?? 0,
      collected: map['collected'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total': total,
      'paid': paid,
      'collected': collected,
    };
  }

  @override
  List<Object?> get props => [total, paid, collected];
}
