import 'package:mysql_dart/mysql_dart.dart';

extension ResultSetRowCompat on ResultSetRow {
  Map<String, dynamic> toColumnMap() {
    final map = assoc();

    // Normalize common MySQL/TiDB numeric values.
    for (final key in map.keys.toList()) {
      final value = map[key];

      if (value is String) {
        final intValue = int.tryParse(value);

        if (intValue != null) {
          map[key] = intValue;
          continue;
        }

        final doubleValue = double.tryParse(value);

        if (doubleValue != null) {
          map[key] = doubleValue;
        }
      }
    }

    return map;
  }
}

extension IResultSetCompat on IResultSet {
  int get insertId {
    return lastInsertID.toInt();
  }
}