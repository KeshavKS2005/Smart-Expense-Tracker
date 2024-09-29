class AppSchema {
  AppSchema._(); 
  static const String dbName = 'expense_tracker.db';
  static const int dbVersion = 1;
  static const String createUsersTable = '''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL
    )
  ''';
  static const String createTransactionsTable = '''
    CREATE TABLE IF NOT EXISTS transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userid INTEGER NOT NULL,
      amount INTEGER NOT NULL,
      type TEXT NOT NULL,
      category TEXT NOT NULL,
      date TEXT NOT NULL,
      description TEXT,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      is_archived INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (userid) REFERENCES users(id)
    )
  ''';
  static const List<String> createStatements = [
    createUsersTable,
    createTransactionsTable,
  ];
}
