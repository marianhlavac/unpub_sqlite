import 'package:sqlite3/sqlite3.dart';
import 'package:unpub/unpub.dart' as unpub;
import 'package:unpub_sqlite/src/sqlite_meta_store.dart';

void main(List<String> args) async {
  print('Using sqlite3 ${sqlite3.version}');

  // To use a database backed by a file, you
  // can replace this with sqlite3.open(yourFilePath).
  final db = sqlite3.openInMemory();

  final metaStore = SqliteMetaStore(sqliteDatabase: db);
  metaStore.initialize();

  final app = unpub.App(
    metaStore: metaStore,
    packageStore: unpub.FileStore('./unpub-packages'),
  );

  final server = await app.serve('0.0.0.0', 4000);
  print('Serving server at http://${server.address.host}:${server.port}');
}
