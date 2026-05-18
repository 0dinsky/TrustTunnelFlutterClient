import 'package:drift/drift.dart';
import 'package:trusttunnel/data/database/app_database.dart';
import 'package:trusttunnel/data/database/migrations/migrations.dart';

class MigrationsV4 implements Migrations {
  const MigrationsV4();

  @override
  Future<void> migrate(GeneratedDatabase db, Migrator m) async {
    await m.addColumn(Servers(db), Servers(db).skipCertVerification);
    await m.addColumn(Servers(db), Servers(db).antiDpi);
  }
}
