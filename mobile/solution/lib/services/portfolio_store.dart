import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/portfolio.dart';

/// A portfolio snapshot read from (or written to) the local store, together
/// with the time it was written, so the UI can show how stale it is.
class CachedPortfolio {
  const CachedPortfolio({required this.portfolio, required this.cachedAt});

  final Portfolio portfolio;
  final DateTime cachedAt;
}

/// Local persistent storage for portfolio data (Task 3).
///
/// Implementations must be real durable storage (SQLite, Realm, etc.), not an
/// in-memory map. See [SqflitePortfolioStore].
abstract class PortfolioStore {
  /// Reads the cached portfolio for [portfolioId], or null if never stored.
  Future<CachedPortfolio?> read(String portfolioId);

  /// Persists [portfolio] under [portfolioId], replacing any previous entry.
  Future<void> write(String portfolioId, Portfolio portfolio,
      {DateTime? cachedAt});

  /// Removes all cached entries.
  Future<void> clear();
}

/// SQLite-backed [PortfolioStore].
///
/// Schema — single table `portfolio_cache`:
///   id         TEXT PRIMARY KEY  -- portfolio id, e.g. 'P-9001'
///   json       TEXT NOT NULL     -- serialized [Portfolio]
///   cached_at  INTEGER NOT NULL  -- write time, milliseconds since epoch
class SqflitePortfolioStore implements PortfolioStore {
  static const String _table = 'portfolio_cache';

  Database? _db;

  Future<Database> _database() async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'portfolio.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT PRIMARY KEY,
            json TEXT NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  @override
  Future<CachedPortfolio?> read(String portfolioId) async {
    final db = await _database();
    final rows = await db.query(
      _table,
      columns: ['json', 'cached_at'],
      where: 'id = ?',
      whereArgs: [portfolioId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    final portfolio = Portfolio.fromJson(
      jsonDecode(row['json'] as String) as Map<String, dynamic>,
    );
    final cachedAt =
        DateTime.fromMillisecondsSinceEpoch(row['cached_at'] as int);
    return CachedPortfolio(portfolio: portfolio, cachedAt: cachedAt);
  }

  @override
  Future<void> write(String portfolioId, Portfolio portfolio,
      {DateTime? cachedAt}) async {
    final db = await _database();
    await db.insert(
      _table,
      {
        'id': portfolioId,
        'json': jsonEncode(portfolio.toJson()),
        'cached_at': (cachedAt ?? DateTime.now()).millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clear() async {
    final db = await _database();
    await db.delete(_table);
  }
}
