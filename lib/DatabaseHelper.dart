import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:smart_expense_tracker/schema.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppSchema.dbName);
    return await openDatabase(
      path,
      version: AppSchema.dbVersion,
      onCreate: _createDB,
    );
  }
  Future<void> _createDB(Database db, int version) async {
    for (final statement in AppSchema.createStatements) {
      await db.execute(statement);
    }
  }
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
  Future<bool> hasAnyUser() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    int count = result.first['count'] as int;
    return count > 0;
  }
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    Map<String, dynamic> userToInsert = Map.from(user);
    if (userToInsert.containsKey('password')) {
      userToInsert['password'] = _hashPassword(userToInsert['password']);
    }
    return await db.insert('users', userToInsert);
  }
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    String hashedPassword = _hashPassword(password);
    final results = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashedPassword],
      limit: 1,
    );
    if (results.isNotEmpty) return results.first;
    return null;
  }
  Future<bool> emailExists(String email) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return results.isNotEmpty;
  }
  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isNotEmpty) return results.first;
    return null;
  }
  Future<int> updateUser(int id, Map<String, dynamic> data) async {
    final db = await database;
    Map<String, dynamic> updateData = Map.from(data);
    if (updateData.containsKey('password')) {
      updateData['password'] = _hashPassword(updateData['password']);
    }
    return await db.update('users', updateData, where: 'id = ?', whereArgs: [id]);
  }
  Future<int> insertTransaction(Map<String, dynamic> txn) async {
    final db = await database;
    return await db.insert('transactions', txn);
  }
  Future<List<Map<String, dynamic>>> getTransactions(int userid,
      {String? monthStart, String? monthEnd}) async {
    final db = await database;
    if (monthStart != null && monthEnd != null) {
      return await db.query(
        'transactions',
        where: 'userid = ? AND is_deleted = 0 AND is_archived = 0 AND date >= ? AND date <= ?',
        whereArgs: [userid, monthStart, monthEnd],
        orderBy: 'date DESC',
      );
    }
    return await db.query(
      'transactions',
      where: 'userid = ? AND is_deleted = 0 AND is_archived = 0',
      whereArgs: [userid],
      orderBy: 'date DESC',
    );
  }
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.update(
      'transactions',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<Map<String, int>> getIncomeExpenseSummary(int userid) async {
    final db = await database;
    final data = await db.query(
      'transactions',
      columns: ['type', 'amount'],
      where: 'userid = ?',
      whereArgs: [userid],
    );
    int income = 0;
    int expense = 0;
    for (var row in data) {
      int amount = row['amount'] as int;
      if (row['type'] == 'Expense') {
        expense += amount;
      } else {
        income += amount;
      }
    }
    return {'income': income, 'expense': expense, 'balance': income - expense};
  }
  Future<Map<String, int>> archiveOldTransactions(int userid, String cutoffDate) async {
    final db = await database;
    final oldRows = await db.query(
      'transactions',
      where: 'userid = ? AND date < ? AND is_deleted = 0',
      whereArgs: [userid, cutoffDate],
    );
    if (oldRows.isEmpty) return {'archived': 0, 'summariesCreated': 0};
    Map<String, Map<String, dynamic>> grouped = {};
    for (var row in oldRows) {
      String monthKey = (row['date'] as String).substring(0, 7); 
      String type = row['type'] as String;
      String category = row['category'] as String;
      String key = '$monthKey|$type|$category';
      if (!grouped.containsKey(key)) {
        grouped[key] = {
          'month': monthKey,
          'type': type,
          'category': category,
          'totalAmount': 0,
          'count': 0,
        };
      }
      grouped[key]!['totalAmount'] += row['amount'] as int;
      grouped[key]!['count'] += 1;
    }
    await db.transaction((txn) async {
      for (var entry in grouped.values) {
        await txn.insert('transactions', {
          'userid': userid,
          'amount': entry['totalAmount'],
          'type': entry['type'],
          'category': entry['category'],
          'date': '${entry['month']}-01', 
          'description': 'Archived: ${entry['count']} transactions',
          'is_deleted': 0,
          'is_archived': 1,
        });
      }
      await txn.delete(
        'transactions',
        where: 'userid = ? AND date < ? AND is_deleted = 0 AND description NOT LIKE ?',
        whereArgs: [userid, cutoffDate, 'Archived:%'],
      );
    });
    return {'archived': oldRows.length, 'summariesCreated': grouped.length};
  }
  Future<int> getTransactionCount(int userid) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE userid = ?',
      [userid],
    );
    return result.first['count'] as int;
  }
  Future<Map<String, dynamic>> getStreakData(int userid, int dailyBudget) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT date, SUM(amount) as total
      FROM transactions
      WHERE userid = ? AND type = 'Expense' AND is_deleted = 0 AND is_archived = 0
      GROUP BY date
      ORDER BY date DESC
    ''', [userid]);
    if (rows.isEmpty) {
      return {'streak': 0, 'todaySpent': 0, 'broken': false};
    }
    String today = DateTime.now().toString().substring(0, 10);
    int todaySpent = 0;
    int streak = 0;
    DateTime checkDate = DateTime.now();
    Map<String, int> dailyMap = {};
    for (var row in rows) {
      dailyMap[row['date'] as String] = row['total'] as int;
    }
    if (dailyMap.containsKey(today)) {
      todaySpent = dailyMap[today]!;
    }
    for (int i = 0; i < 365; i++) {
      String dateStr = checkDate.subtract(Duration(days: i)).toString().substring(0, 10);
      int spent = dailyMap[dateStr] ?? 0;
      if (spent > dailyBudget) break;
      if (dailyMap.containsKey(dateStr) || i == 0) {
        streak++;
      }
    }
    return {
      'streak': streak,
      'todaySpent': todaySpent,
      'broken': todaySpent > dailyBudget,
    };
  }
}
