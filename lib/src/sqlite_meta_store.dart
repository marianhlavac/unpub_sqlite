import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';
import 'package:unpub/unpub.dart';

import 'exceptions.dart';

const uploadersTableName = 'uploaders';
const packagesTableName = 'packages';
const versionsTableName = 'versions';

class SqliteMetaStore extends MetaStore {
  final Database sqliteDatabase;

  SqliteMetaStore({required this.sqliteDatabase}) {
    if (!sqliteDatabase.autocommit) throw AutocommitRequired();
  }

  void initialize() {
    sqliteDatabase.execute('''
      create table if not exists $packagesTableName (
        id integer not null primary key,
        name text not null unique,
        downloads integer not null default 0,
        created_at datetime default current_timestamp,
        updated_at datetime default current_timestamp
      );
      create table if not exists $uploadersTableName (
        id integer not null primary key,
        package_id integer not null,
        email text not null,
        foreign key (package_id) references $packagesTableName(id)
      );
      create table if not exists $versionsTableName (
        id integer not null primary key,
        package_id integer not null,
        data text not null,
        foreign key (package_id) references $packagesTableName(id)
      );
    ''');
  }

  @override
  Future<void> addUploader(String name, String email) async {
    final packageId = getPackageId(name);
    if (packageId == null) return; // FIXME: silent error?

    sqliteDatabase.prepare('''
      insert 
        into $uploadersTableName 
      (package_id, email) values (?, ?)
    ''').execute([packageId, email]);
  }

  @override
  Future<void> removeUploader(String name, String email) async {
    final packageId = getPackageId(name);
    if (packageId == null) return; // FIXME: silent error?

    sqliteDatabase.prepare('''
      delete 
        from $uploadersTableName 
      where 
        package_id = ? AND email = ?
    ''').execute([packageId, email]);
  }

  @override
  void increaseDownloads(String name, String version) {
    sqliteDatabase.prepare('''
      update 
        $packagesTableName 
      set 
        downloads = downloads + 1 
      where 
        name = ? 
    ''').execute([name]);
  }

  @override
  Future<void> addVersion(String name, UnpubVersion version) async {
    final versionJsonData = json.encode(
      version.toJson(),
      toEncodable: (obj) => obj is DateTime ? obj.toIso8601String() : obj,
    );

    // Upsert to packages
    sqliteDatabase.prepare('''
      insert 
        into $packagesTableName 
      (name) values (?)
      on conflict (name) 
        do update set updated_at = current_timestamp
    ''').execute([name]);

    final packageId = sqliteDatabase.lastInsertRowId;

    // Create new version
    sqliteDatabase.prepare('''
      insert 
        into $versionsTableName
      (data, package_id) values (?, ?)
    ''').execute([versionJsonData, packageId]);
  }

  @override
  Future<UnpubPackage?> queryPackage(String name) async {
    final packageId = getPackageId(name);
    if (packageId == null) return null;
    return queryPackageById(packageId);
  }

  @override
  Future<UnpubQueryResult> queryPackages(
      {required int size,
      required int page,
      required String sort,
      String? keyword,
      String? uploader,
      String? dependency}) async {
    // FIXME: Querying by dependency is not supported, returns none
    if (dependency != null) return UnpubQueryResult(0, []);

    final likeKeyword = keyword != null ? '%$keyword%' : '%';
    final likeUploader = uploader != null ? '%$uploader%' : '%';

    final filterQueryPartial = '''
      from $packagesTableName p
      full join $uploadersTableName u on p.id = u.package_id
      where 
        p.name like ?
        and coalesce(u.email,'') like ?
    ''';

    final countPackagesQuery = sqliteDatabase.prepare('''
      select count(*)
      $filterQueryPartial
    ''').select([likeKeyword, likeUploader]);

    final foundPackagesQuery = sqliteDatabase.prepare('''
      select distinct p.id
      $filterQueryPartial
      order by ?
      limit ?
      offset ?
    ''').select([likeKeyword, likeUploader, sort, size, page * size]);

    final totalCount = countPackagesQuery.first.values.first;

    final packages = foundPackagesQuery
        .map((row) => row['id'] as int)
        .map<UnpubPackage?>(queryPackageById)
        .whereType<UnpubPackage>();

    return UnpubQueryResult(totalCount as int, packages.toList());
  }

  int? getPackageId(String name) {
    return sqliteDatabase.prepare('''
      select id from $packagesTableName 
      where 
        name = ?
    ''').select([name]).firstOrNull?['id'];
  }

  UnpubPackage? queryPackageById(int id) {
    final packageRow = sqliteDatabase.prepare('''
      select * from $packagesTableName 
      where 
        id = ?
    ''').select([id]).firstOrNull;

    if (packageRow == null) return null;

    final versionsRows = sqliteDatabase.prepare('''
      select * from $versionsTableName where package_id = ?
    ''').select([id]);

    final versions = versionsRows.map((row) {
      final dataJson = UnpubVersion.fromJson(json.decode(row['data'],
          reviver: (key, value) =>
              key == 'createdAt' ? DateTime.parse(value as String) : value));
      return dataJson;
    });

    return UnpubPackage(
      packageRow['name'],
      versions.toList(),
      true,
      versions.map((version) => version.uploader ?? '').toSet().toList(),
      DateTime.parse(packageRow['created_at']),
      DateTime.parse(packageRow['updated_at']),
      packageRow['downloads'],
    );
  }
}
