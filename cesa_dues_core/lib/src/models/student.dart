import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../constants/enums.dart';

/// Official student record from the departmental student list.
class Student extends Equatable {
  const Student({
    required this.indexNumber,
    required this.fullName,
    required this.programme,
    required this.level,
    required this.academicYear,
    this.email,
    this.phone,
    this.linkedUid,
    this.fcmToken,
    this.verificationStatus = VerificationStatus.unverified,
    this.verificationImagePath,
    this.importId,
    this.createdAt,
    this.updatedAt,
  });

  final String indexNumber;
  final String fullName;
  final String programme;
  final int level;
  final String academicYear;
  final String? email;
  final String? phone;
  final String? linkedUid;
  final String? fcmToken;
  final VerificationStatus verificationStatus;
  final String? verificationImagePath;
  final String? importId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isLinked => linkedUid != null;
  bool get isVerified => verificationStatus == VerificationStatus.verified;

  factory Student.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Student(
      indexNumber: data['indexNumber'] as String,
      fullName: data['fullName'] as String,
      programme: data['programme'] as String,
      level: data['level'] as int,
      academicYear: data['academicYear'] as String,
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      linkedUid: data['linkedUid'] as String?,
      fcmToken: data['fcmToken'] as String?,
      verificationStatus: VerificationStatus.fromValue(
        data['verificationStatus'] as String? ?? 'unverified',
      ),
      verificationImagePath: data['verificationImagePath'] as String?,
      importId: data['importId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'indexNumber': indexNumber,
      'fullName': fullName,
      'programme': programme,
      'level': level,
      'academicYear': academicYear,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'linkedUid': linkedUid,
      if (fcmToken != null) 'fcmToken': fcmToken,
      'verificationStatus': verificationStatus.value,
      if (verificationImagePath != null)
        'verificationImagePath': verificationImagePath,
      if (importId != null) 'importId': importId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Student copyWith({
    String? indexNumber,
    String? fullName,
    String? programme,
    int? level,
    String? academicYear,
    String? email,
    String? phone,
    String? linkedUid,
    String? fcmToken,
    VerificationStatus? verificationStatus,
    String? verificationImagePath,
    String? importId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      indexNumber: indexNumber ?? this.indexNumber,
      fullName: fullName ?? this.fullName,
      programme: programme ?? this.programme,
      level: level ?? this.level,
      academicYear: academicYear ?? this.academicYear,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      linkedUid: linkedUid ?? this.linkedUid,
      fcmToken: fcmToken ?? this.fcmToken,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationImagePath:
          verificationImagePath ?? this.verificationImagePath,
      importId: importId ?? this.importId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        indexNumber,
        fullName,
        programme,
        level,
        academicYear,
        email,
        phone,
        linkedUid,
        fcmToken,
        verificationStatus,
        verificationImagePath,
        importId,
      ];
}
