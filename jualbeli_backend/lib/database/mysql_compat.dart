import 'package:mysql_dart/mysql_dart.dart';

/// Compatibility with mysql1 ResultRow.toColumnMap()
extension ResultSetRowCompat on ResultSetRow {
  Map<String, dynamic> toColumnMap() {
    final map = assoc();

    return Map<String, dynamic>.fromEntries(
      map.entries.map((entry) {
        final value = entry.value;

        // Convert numeric strings to int/double where appropriate.
        if (value is String) {
          final intValue = int.tryParse(value);

          if (intValue != null) {
            return MapEntry(entry.key, intValue);
          }

          final doubleValue = double.tryParse(value);

          if (doubleValue != null) {
            return MapEntry(entry.key, doubleValue);
          }
        }

        return MapEntry(entry.key, value);
      }),
    );
  }
}

/// Compatibility for code that calls result.toColumnMap()
extension IResultSetCompat on IResultSet {
  Map<String, dynamic> toColumnMap() {
    if (rows.isEmpty) {
      return <String, dynamic>{};
    }

    return rows.first.toColumnMap();
  }

  /// Compatibility with mysql1:
  /// result.insertId
  int get insertId {
    return int.tryParse(lastInsertID.toString()) ?? 0;
  }
}