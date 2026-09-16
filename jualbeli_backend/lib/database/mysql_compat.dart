import 'package:mysql_dart/mysql_dart.dart';

/// Compatibility with mysql1 ResultRow.toColumnMap()
extension ResultSetRowCompat on ResultSetRow {
  Map<String, dynamic> toColumnMap() {
    return assoc();
  }
}

/// Compatibility for code that calls:
/// result.toColumnMap()
/// where result is an IResultSet.
extension IResultSetCompat on IResultSet {
  Map<String, dynamic> toColumnMap() {
    if (rows.isEmpty) {
      return <String, dynamic>{};
    }

    return rows.first.assoc();
  }

  /// Compatibility with mysql1:
  /// result.insertId
  int get insertId {
    return lastInsertID.toInt();
  }
}