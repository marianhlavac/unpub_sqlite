class UnpubSqliteException implements Exception {}

class AutocommitRequired extends UnpubSqliteException {
  @override
  String toString() =>
      "Auto-commit is required to be enabled on the Database instance";
}
