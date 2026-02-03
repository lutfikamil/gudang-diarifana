import 'package:cloud_firestore/cloud_firestore.dart';

class DateRangeHelper {
  /// Awal hari (00:00:00.000)
  static Timestamp startOfDay(DateTime date) {
    return Timestamp.fromDate(DateTime(date.year, date.month, date.day));
  }

  /// Akhir hari (23:59:59.999)
  static Timestamp endOfDay(DateTime date) {
    return Timestamp.fromDate(
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999),
    );
  }

  /// Range custom (AMAN lintas bulan & tahun)
  static Map<String, Timestamp> customRange(DateTime start, DateTime end) {
    return {'start': startOfDay(start), 'end': endOfDay(end)};
  }

  /// Range harian
  static Map<String, Timestamp> harian(DateTime date) {
    return {'start': startOfDay(date), 'end': endOfDay(date)};
  }

  /// Range bulanan
  static Map<String, Timestamp> bulanan(DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 0);

    return {'start': startOfDay(start), 'end': endOfDay(end)};
  }
}
