import 'package:mysql_dart/mysql_dart.dart';

extension ResultSetRowCompat on ResultSetRow {
  Map<String, dynamic> toColumnMap() {
    final map = assoc();

    return {
      for (final entry in map.entries)
        entry.key: _convertValue(entry.value),
    };
  }
}

extension IResultSetCompat on IResultSet {
  Map<String, dynamic> toColumnMap() {
    if (rows.isEmpty) {
      return <String, dynamic>{};
    }

    return rows.first.toColumnMap();
  }

  int get insertId {
    return _toInt(lastInsertID);
  }
}

dynamic _convertValue(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is double) {
    return value;
  }

  if (value is num) {
    return value;
  }

  if (value is BigInt) {
    return value.toInt();
  }

  if (value is String) {
    final intValue = int.tryParse(value);
    if (intValue != null) {
      return intValue;
    }

    final doubleValue = double.tryParse(value);
    if (doubleValue != null) {
      return doubleValue;
    }

    return value;
  }

  return value;
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is BigInt) {
    return value.toInt();
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString()) ?? 0;
}