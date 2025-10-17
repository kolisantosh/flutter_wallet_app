import 'package:uuid/uuid.dart';

import '../../core/constants/database_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/password_utils.dart';
import '../database/app_database.dart';
import '../models/user_model.dart';

class UserRepository {
  final AppDatabase database;
  final Uuid _uuid = const Uuid();

  UserRepository(this.database);

  Future<UserModel> register({required String email, required String password, required String name}) async {
    try {
      final db = await database.database;

      final existingUser = await db.query(DatabaseConstants.tableUsers, where: '${DatabaseConstants.columnEmail} = ?', whereArgs: [email]);

      if (existingUser.isNotEmpty) {
        throw const AuthenticationFailure('Email already registered');
      }

      final userId = _uuid.v4();
      final hashedPassword = PasswordUtils.hashPassword(password);

      final user = UserModel(id: userId, email: email, password: hashedPassword, name: name, createdAt: DateTime.now());

      await db.insert(DatabaseConstants.tableUsers, user.toMap());

      await db.insert(DatabaseConstants.tableWalletBalance, {
        DatabaseConstants.columnUserId: userId,
        DatabaseConstants.columnBalance: 0.0,
        DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
      });

      return user;
    } catch (e) {
      if (e is AuthenticationFailure) rethrow;
      throw DatabaseFailure('Failed to register user: ${e.toString()}');
    }
  }

  Future<UserModel> login({required String email, required String password}) async {
    try {
      final db = await database.database;

      final result = await db.query(DatabaseConstants.tableUsers, where: '${DatabaseConstants.columnEmail} = ?', whereArgs: [email]);

      if (result.isEmpty) {
        throw const AuthenticationFailure('Invalid email or password');
      }

      final user = UserModel.fromMap(result.first);

      if (!PasswordUtils.verifyPassword(password, user.password)) {
        throw const AuthenticationFailure('Invalid email or password');
      }

      return user;
    } catch (e) {
      if (e is AuthenticationFailure) rethrow;
      throw DatabaseFailure('Failed to login: ${e.toString()}');
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final db = await database.database;

      final result = await db.query(DatabaseConstants.tableUsers, where: '${DatabaseConstants.columnId} = ?', whereArgs: [userId]);

      if (result.isEmpty) return null;
      return UserModel.fromMap(result.first);
    } catch (e) {
      throw DatabaseFailure('Failed to get user: ${e.toString()}');
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final db = await database.database;
      final result = await db.query(DatabaseConstants.tableUsers);
      return result.map((map) => UserModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseFailure('Failed to get users: ${e.toString()}');
    }
  }

  Future<List<UserModel>> getOtherUsers(String currentUserId) async {
    try {
      final db = await database.database;
      final result = await db.query(DatabaseConstants.tableUsers, where: '${DatabaseConstants.columnId} != ?', whereArgs: [currentUserId]);
      return result.map((map) => UserModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseFailure('Failed to get other users: ${e.toString()}');
    }
  }
}
