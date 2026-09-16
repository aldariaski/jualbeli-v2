import 'package:mysql_dart/mysql_dart.dart';

/// Compatibility extensions for the old mysql1 API.
extension IResultSetMysql1Compat on IResultSet {
  /// mysql1 compatibility:
  ///
  /// old:
  ///   result.insertId
  ///
  /// mysql_dart:
  ///   result.lastInsertID
  int get insertId {
    return lastInsertID.toInt();
  }

  /// Converts the first row into a Map.
  ///
  /// mysql1-compatible helper:
  ///   result.toColumnMap()
  Map<String, dynamic> toColumnMap() {
    if (rows.isEmpty) {
      return <String, dynamic>{};
    }

    return rows.first.assoc();
  }
}

/// Compatibility helper for individual rows.
extension ResultSetRowMysql1Compat on ResultSetRow {
  Map<String, dynamic> toColumnMap() {
    return assoc();
  }
}