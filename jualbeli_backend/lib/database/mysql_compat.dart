import 'package:mysql_dart/mysql_dart.dart';

extension IResultSetMysql1Compat on IResultSet {
  int get insertId {
    return lastInsertID.toInt();
  }

  Map<String, dynamic> toColumnMap() {
    if (rows.isEmpty) {
      return <String, dynamic>{};
    }

    return rows.first.assoc();
  }
}

extension ResultSetRowMysql1Compat on ResultSetRow {
  Map<String, dynamic> toColumnMap() {
    return assoc();
  }
}