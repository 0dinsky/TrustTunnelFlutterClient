import 'package:drift/drift.dart';
import 'package:trusttunnel/data/database/app_database.dart';
import 'package:trusttunnel/data/database/migrations/migrations.dart';

class MigrationsV5 implements Migrations {
  const MigrationsV5();

  @override
  Future<void> migrate(GeneratedDatabase db, Migrator m) async {
    await m.addColumn(Servers(db), Servers(db).mtuSize);
  }
}
