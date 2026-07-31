import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:habitos_app/config/config.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), AppConstants.dbName);
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        gender TEXT,
        weight REAL,
        height REAL,
        age INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        frequency TEXT NOT NULL DEFAULT 'daily',
        category TEXT NOT NULL DEFAULT 'otro',
        created_at TEXT NOT NULL,
        reminder_time TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        current_streak INTEGER NOT NULL DEFAULT 0,
        best_streak INTEGER NOT NULL DEFAULT 0,
        goal_target INTEGER,
        goal_days INTEGER,
        repeat_days TEXT NOT NULL DEFAULT '',
        times_per_day INTEGER NOT NULL DEFAULT 1,
        target_type TEXT NOT NULL DEFAULT 'simpleCheck',
        target_value INTEGER NOT NULL DEFAULT 1,
        unit TEXT NOT NULL DEFAULT 'check',
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_logs (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        date TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 1,
        completed_at TEXT,
        FOREIGN KEY (habit_id) REFERENCES habits(id)
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          "ALTER TABLE habits ADD COLUMN category TEXT NOT NULL DEFAULT 'otro'",
        );
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute(
          "ALTER TABLE habits ADD COLUMN goal_target INTEGER",
        );
        await db.execute(
          "ALTER TABLE habits ADD COLUMN goal_days INTEGER",
        );
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute(
          "ALTER TABLE habits ADD COLUMN repeat_days TEXT NOT NULL DEFAULT ''",
        );
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute(
          "ALTER TABLE habits ADD COLUMN times_per_day INTEGER NOT NULL DEFAULT 1",
        );
        await db.execute('''
          CREATE TABLE habit_logs_v5 (
            id TEXT PRIMARY KEY,
            habit_id TEXT NOT NULL,
            date TEXT NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 1,
            completed_at TEXT,
            FOREIGN KEY (habit_id) REFERENCES habits(id)
          )
        ''');
        await db.execute(
          'INSERT INTO habit_logs_v5 SELECT * FROM habit_logs',
        );
        await db.execute('DROP TABLE habit_logs');
        await db.execute('ALTER TABLE habit_logs_v5 RENAME TO habit_logs');
      } catch (_) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute("ALTER TABLE users ADD COLUMN gender TEXT");
        await db.execute("ALTER TABLE users ADD COLUMN weight REAL");
        await db.execute("ALTER TABLE users ADD COLUMN height REAL");
        await db.execute("ALTER TABLE users ADD COLUMN age INTEGER");
      } catch (_) {}
    }
    if (oldVersion < 7) {
      try {
        await db.execute("ALTER TABLE habits ADD COLUMN target_type TEXT NOT NULL DEFAULT 'simpleCheck'");
        await db.execute("ALTER TABLE habits ADD COLUMN target_value INTEGER NOT NULL DEFAULT 1");
        await db.execute("ALTER TABLE habits ADD COLUMN unit TEXT NOT NULL DEFAULT 'check'");
      } catch (_) {}
    }
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  static Future<void> resetDatabase() async {
    await close();
    final path = join(await getDatabasesPath(), AppConstants.dbName);
    await deleteDatabase(path);
  }
}
