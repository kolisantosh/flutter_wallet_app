import 'package:sqflite/sqflite.dart';

import '../../core/constants/database_constants.dart';
import '../../core/utils/password_utils.dart';

class AppDatabase {
  final String dbPath;
  Database? _database;

  AppDatabase(this.dbPath);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await _createUsersTable(db);
        await _createWalletBalanceTable(db);
        await _createTransactionsTable(db);
        await _insertDummyUsers(db);
      },
    );
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableUsers} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnEmail} TEXT UNIQUE NOT NULL,
        ${DatabaseConstants.columnPassword} TEXT NOT NULL,
        ${DatabaseConstants.columnName} TEXT NOT NULL,
        ${DatabaseConstants.columnCreatedAt} TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createWalletBalanceTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableWalletBalance} (
        ${DatabaseConstants.columnUserId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnBalance} REAL NOT NULL DEFAULT 0,
        ${DatabaseConstants.columnUpdatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DatabaseConstants.columnUserId}) 
          REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnId})
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableTransactions} (
        ${DatabaseConstants.columnTransactionId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnFromUserId} TEXT,
        ${DatabaseConstants.columnToUserId} TEXT NOT NULL,
        ${DatabaseConstants.columnAmount} REAL NOT NULL,
        ${DatabaseConstants.columnType} TEXT NOT NULL,
        ${DatabaseConstants.columnDatetime} TEXT NOT NULL,
        ${DatabaseConstants.columnNote} TEXT,
        FOREIGN KEY (${DatabaseConstants.columnFromUserId}) 
          REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnId}),
        FOREIGN KEY (${DatabaseConstants.columnToUserId}) 
          REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnId})
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_to_user 
      ON ${DatabaseConstants.tableTransactions}(${DatabaseConstants.columnToUserId})
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_from_user 
      ON ${DatabaseConstants.tableTransactions}(${DatabaseConstants.columnFromUserId})
    ''');
  }

  Future<void> _insertDummyUsers(Database db) async {
    final dummyUsers = [
      {
        'id': 'user_001',
        'email': 'santosh@gmail.com',
        'password': PasswordUtils.hashPassword('password123'),
        'name': 'Santosh Koli',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'user_002',
        'email': 'satyam@gmail.com',
        'password': PasswordUtils.hashPassword('password123'),
        'name': 'Satyam Baranwal',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'user_003',
        'email': 'umesh@gmail.com',
        'password': PasswordUtils.hashPassword('password123'),
        'name': 'Umesh Shah',
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    for (var user in dummyUsers) {
      await db.insert(DatabaseConstants.tableUsers, user);
      await db.insert(DatabaseConstants.tableWalletBalance, {
        'user_id': user['id'],
        'balance': 0.0,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
