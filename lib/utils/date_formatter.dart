class DateFormatter {
  static String formatTripDates(String startStr, String endStr) {
    try {
      final start = DateTime.parse(startStr);
      final end = DateTime.parse(endStr);
      final months = [
        'января',
        'февраля',
        'марта',
        'апреля',
        'мая',
        'июня',
        'июля',
        'августа',
        'сентября',
        'октября',
        'ноября',
        'декабря',
      ];

      String formatTime(DateTime dt) {
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }

      final startMonth = months[start.month - 1];
      if (start.year == end.year &&
          start.month == end.month &&
          start.day == end.day) {
        return '${start.day} $startMonth: ${formatTime(start)} - ${formatTime(end)}';
      } else {
        final endMonth = months[end.month - 1];
        return '${start.day} $startMonth ${formatTime(start)} - ${end.day} $endMonth ${formatTime(end)}';
      }
    } catch (e) {
      return '$startStr - $endStr';
    }
  }

  static String formatNullableDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Не указано';
    try {
      final dt = DateTime.parse(dateStr);
      final months = [
        'янв',
        'фев',
        'мар',
        'апр',
        'мая',
        'июн',
        'июл',
        'авг',
        'сен',
        'окт',
        'ноя',
        'дек',
      ];
      final month = months[dt.month - 1];
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} $month, $h:$m';
    } catch (_) {
      return dateStr;
    }
  }

  static String formatTimeOnly(String timeStr) {
    try {
      final dt = DateTime.parse(timeStr);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (e) {
      return timeStr;
    }
  }
}

