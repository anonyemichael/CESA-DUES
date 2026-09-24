import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../constants/enums.dart';

/// Record of a student data import operation.
class ImportRecord extends Equatable {
  const ImportRecord({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.uploadedBy,
    required this.academicYear,
    this.totalRows = 0,
    this.successfulRows = 0,
    this.failedRows = 0,
    this.warningRows = 0,
    this.createdRecords = 0,
    this.updatedRecords = 0,
    this.errors = const [],
    this.status = ImportStatus.processing,
    this.createdAt,
    this.completedAt,
  });

  final String id;
  final String fileName;
  final String fileType; // "csv" or "xlsx"
  final String uploadedBy;
  final String academicYear;
  final int totalRows;
  final int successfulRows;
  final int failedRows;
  final int warningRows;
  final int createdRecords;
  final int updatedRecords;
  final List<Map<String, dynamic>> errors;
  final ImportStatus status;
  final DateTime? createdAt;
  final DateTime? completedAt;

  factory ImportRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ImportRecord(
      id: doc.id,
      fileName: data['fileName'] as String,
      fileType: data['fileType'] as String,
      uploadedBy: data['uploadedBy'] as String,
      academicYear: data['academicYear'] as String,
      totalRows: data['totalRows'] as int? ?? 0,
      successfulRows: data['successfulRows'] as int? ?? 0,
      failedRows: data['failedRows'] as int? ?? 0,
      warningRows: data['warningRows'] as int? ?? 0,
      createdRecords: data['createdRecords'] as int? ?? 0,
      updatedRecords: data['updatedRecords'] as int? ?? 0,
      errors: List<Map<String, dynamic>>.from(
        data['errors'] as List? ?? [],
      ),
      status: ImportStatus.fromValue(
        data['status'] as String? ?? 'processing',
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fileName': fileName,
      'fileType': fileType,
      'uploadedBy': uploadedBy,
      'academicYear': academicYear,
      'totalRows': totalRows,
      'successfulRows': successfulRows,
      'failedRows': failedRows,
      'warningRows': warningRows,
      'createdRecords': createdRecords,
      'updatedRecords': updatedRecords,
      'errors': errors,
      'status': status.value,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (completedAt != null)
        'completedAt': Timestamp.fromDate(completedAt!),
    };
  }

  @override
  List<Object?> get props => [id, fileName, status, totalRows];
}
