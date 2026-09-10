import 'package:intl/intl.dart';

abstract final class DateFormatter {
  static final DateFormat _shortDate = DateFormat('dd/MM/yyyy');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'es_MX');

  static String shortDate(DateTime date) => _shortDate.format(date);

  static String monthYear(DateTime date) => _monthYear.format(date);

  static String relative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inDays < 1) return '${diff.inHours} h';
    if (diff.inDays < 30) return '${diff.inDays} d';
    return shortDate(date);
  }
}
