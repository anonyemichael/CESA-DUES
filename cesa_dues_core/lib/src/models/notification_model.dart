import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../constants/enums.dart';

/// Notification sent by Financial Secretary to students.
class NotificationModel extends Equatable {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type = NotificationType.announcement,
    required this.targetAudience,
    required this.academicYear,
    this.studentId,
    this.sentBy,
    this.sentAt,
    this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationTarget targetAudience;
  final String academicYear;
  final String? studentId;
  final String? sentBy;
  final DateTime? sentAt;
  final DateTime? createdAt;
  final bool isRead;

  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return NotificationModel(
      id: doc.id,
      title: data['title'] as String,
      body: data['body'] as String,
      type: NotificationType.fromValue(
        data['type'] as String? ?? 'announcement',
      ),
      targetAudience: NotificationTarget.fromValue(
        data['targetAudience'] as String? ?? 'all',
      ),
      academicYear: data['academicYear'] as String,
      studentId: data['studentId'] as String?,
      sentBy: data['sentBy'] as String?,
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'type': type.value,
      'targetAudience': targetAudience.value,
      'academicYear': academicYear,
      if (studentId != null) 'studentId': studentId,
      if (sentBy != null) 'sentBy': sentBy,
      'sentAt': sentAt != null
          ? Timestamp.fromDate(sentAt!)
          : FieldValue.serverTimestamp(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }

  @override
  List<Object?> get props => [id, title, type, targetAudience, academicYear, studentId, isRead];
}
