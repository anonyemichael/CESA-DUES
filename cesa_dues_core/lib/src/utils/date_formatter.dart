import 'package:intl/intl.dart';

/// Date and time formatting utilities.
class DateFormatter {
  DateFormatter._();

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm');
  static final _timeFormat = DateFormat('HH:mm');
  static final _fullFormat = DateFormat('EEEE, dd MMMM yyyy');

  /// Format date: "12 Aug 2026"
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// Format date and time: "12 Aug 2026, 14:30"
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  /// Format time only: "14:30"
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// Format full date: "Monday, 12 August 2026"
  static String formatFull(DateTime date) => _fullFormat.format(date);

  /// Relative time: "2 hours ago", "Just now", etc.
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    return formatDate(date);
  }

  /// Greeting based on time of day.
  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
