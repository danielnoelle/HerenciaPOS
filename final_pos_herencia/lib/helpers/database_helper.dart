import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../models/menu_item_model.dart';
import '../models/cashier_model.dart';
import '../models/sale_model.dart';
import '../models/time_log_model.dart';

class DatabaseHelper {
  static const _databaseName = "HerenciaPOS.db";
  static const _databaseVersion = 2;

  static const tableMenuItems = 'menu_items';
  static const columnMenuId = 'id';
  static const columnMenuName = 'name';
  static const columnMenuPrice = 'price';
  static const columnMenuDescription = 'description';
  static const columnMenuCategoryId = 'category_id';
  static const columnMenuVarieties = 'varieties';
  static const columnMenuImageUrl = 'image_url';
  static const columnMenuStock = 'stock';
  static const columnMenuFirebaseDocId = 'firebase_doc_id';
  static const columnMenuLastUpdated = 'last_updated';

  static const tableCashiers = 'cashiers';
  static const tableSales = 'sales';
  static const columnSaleFirebaseDocId = 'firebase_doc_id';
  static const columnSaleItemsJson = 'items_json';
  static const columnSaleTotalAmount = 'total_amount';
  static const columnSaleTimestamp = 'sale_timestamp';
  static const columnSaleCashierId = 'cashier_id';
  static const columnSaleIsSynced = 'is_synced';
  static const columnSaleOrderType = 'order_type';

  static const tableTimeLogs = 'time_logs';
  static const columnTimeLogFirebaseDocId = 'firebase_doc_id';
  static const columnTimeLogCashierId = 'cashier_id';
  static const columnTimeLogLoginTime = 'login_time';
  static const columnTimeLogLogoutTime = 'logout_time';
  static const columnTimeLogIsSynced = 'is_synced';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableMenuItems (
        $columnMenuId TEXT PRIMARY KEY,
        $columnMenuName TEXT NOT NULL,
        $columnMenuPrice REAL NOT NULL,
        $columnMenuDescription TEXT,
        $columnMenuCategoryId TEXT NOT NULL,
        $columnMenuVarieties TEXT,
        image_url TEXT,
        $columnMenuStock INTEGER NOT NULL DEFAULT 0,
        $columnMenuFirebaseDocId TEXT UNIQUE,
        $columnMenuLastUpdated INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableCashiers (
        $columnMenuId TEXT PRIMARY KEY,
        $columnMenuName TEXT,
        $columnMenuImageUrl TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableSales (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        $columnSaleFirebaseDocId TEXT UNIQUE,
        $columnSaleItemsJson TEXT NOT NULL,
        $columnSaleTotalAmount REAL NOT NULL,
        $columnSaleTimestamp INTEGER NOT NULL,
        $columnSaleCashierId TEXT NOT NULL,
        $columnSaleIsSynced INTEGER DEFAULT 0,
        $columnSaleOrderType TEXT NOT NULL,
        FOREIGN KEY ($columnSaleCashierId) REFERENCES $tableCashiers ($columnMenuId)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableTimeLogs (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        $columnTimeLogFirebaseDocId TEXT UNIQUE,
        $columnTimeLogCashierId TEXT NOT NULL,
        $columnTimeLogLoginTime INTEGER NOT NULL,
        $columnTimeLogLogoutTime INTEGER,
        $columnTimeLogIsSynced INTEGER DEFAULT 0,
        FOREIGN KEY ($columnTimeLogCashierId) REFERENCES $tableCashiers ($columnMenuId)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE $tableMenuItems ADD COLUMN image_url TEXT;");
    }
  }

  //MenuItemModel CRUD

  Future<int> insertMenuItem(MenuItemModel item) async {
    Database db = await instance.database;
    return await db.insert(tableMenuItems, item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MenuItemModel>> getAllMenuItems() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(tableMenuItems);
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) {
      return MenuItemModel.fromMap(maps[i]);
    });
  }

  Future<MenuItemModel?> getMenuItemById(String id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableMenuItems,
      where: '$columnMenuId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return MenuItemModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateMenuItem(MenuItemModel item) async {
    Database db = await instance.database;
    return await db.update(
      tableMenuItems,
      item.toMap(),
      where: '$columnMenuId = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteMenuItem(String id) async {
    Database db = await instance.database;
    return await db.delete(
      tableMenuItems,
      where: '$columnMenuId = ?',
      whereArgs: [id],
    );
  }

  // Upsert: Insert if new, replace if exists (based on primary key)
  Future<int> upsertMenuItem(MenuItemModel item) async {
    Database db = await instance.database;
    return await db.insert(
      tableMenuItems,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> batchInsertMenuItems(List<MenuItemModel> items) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    for (var item in items) {
      batch.insert(tableMenuItems, item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> batchUpsertMenuItems(List<MenuItemModel> items) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    for (var item in items) {
      batch.insert(tableMenuItems, item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  //CashierModel CRUD

  Future<int> upsertCashier(CashierModel cashier) async {
    Database db = await instance.database;
    return await db.insert(
      tableCashiers,
      cashier.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<CashierModel?> getCashierById(String id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableCashiers,
      where: '$columnMenuId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CashierModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<CashierModel>> getAllCashiers() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(tableCashiers);
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) {
      return CashierModel.fromMap(maps[i]);
    });
  }

  Future<void> batchUpsertCashiers(List<CashierModel> cashiers) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    for (var cashier in cashiers) {
      batch.insert(tableCashiers, cashier.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<int> deleteCashier(String id) async {
    Database db = await instance.database;
    return await db.delete(
      tableCashiers,
      where: '$columnMenuId = ?',
      whereArgs: [id],
    );
  }

  //SaleModel CRUD

  Future<SaleModel> insertSale(SaleModel sale) async {
    Database db = await instance.database;
    // Ensure isSynced is false (0) for new local sales and id is null for autoincrement
    Map<String, dynamic> saleMap = sale.toMap();
    saleMap.remove('id');
    saleMap['is_synced'] = 0;

    int id = await db.insert(tableSales, saleMap, conflictAlgorithm: ConflictAlgorithm.replace);
    return sale.copyWith(id: id, isSynced: false);
  }

  Future<List<SaleModel>> getAllSales({String? orderBy}) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(tableSales, orderBy: orderBy ?? '$columnSaleTimestamp DESC');
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) {
      return SaleModel.fromMap(maps[i]);
    });
  }

  Future<List<SaleModel>> getUnsyncedSales() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableSales,
      where: '$columnSaleIsSynced = ?',
      whereArgs: [0],
      orderBy: '$columnSaleTimestamp ASC',
    );
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) {
      return SaleModel.fromMap(maps[i]);
    });
  }

  Future<int> markSaleAsSynced(int localSaleId, String firebaseDocId) async {
    Database db = await instance.database;
    return await db.update(
      tableSales,
      {
        columnSaleIsSynced: 1,
        columnSaleFirebaseDocId: firebaseDocId,
      },
      where: 'id = ?',
      whereArgs: [localSaleId],
    );
  }

  Future<SaleModel?> getSaleById(int localSaleId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableSales,
      where: 'id = ?',
      whereArgs: [localSaleId],
    );
    if (maps.isNotEmpty) {
      return SaleModel.fromMap(maps.first);
    }
    return null;
  }
  
  Future<int> deleteSale(int localSaleId) async {
    Database db = await instance.database;
    return await db.delete(
      tableSales,
      where: 'id = ?',
      whereArgs: [localSaleId],
    );
  }

  //TimeLogModel CRUD

  Future<TimeLogModel> insertTimeLog(TimeLogModel timeLog) async {
    Database db = await instance.database;
    Map<String, dynamic> logMap = timeLog.toMap();
    logMap.remove('id');
    logMap['is_synced'] = 0;

    int id = await db.insert(tableTimeLogs, logMap, conflictAlgorithm: ConflictAlgorithm.fail);
    return timeLog.copyWith(id: id, isSynced: false);
  }

  Future<int> updateTimeLog(TimeLogModel timeLog) async {
    Database db = await instance.database;
    if (timeLog.id == null) {
      throw ArgumentError("TimeLogModel must have an ID to be updated.");
    }
    return await db.update(
      tableTimeLogs,
      timeLog.toMap(),
      where: 'id = ?',
      whereArgs: [timeLog.id],
    );
  }

  Future<List<TimeLogModel>> getUnsyncedTimeLogs() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTimeLogs,
      where: '$columnTimeLogIsSynced = ?',
      whereArgs: [0],
      orderBy: '$columnTimeLogLoginTime ASC',
    );
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) {
      return TimeLogModel.fromMap(maps[i]);
    });
  }

  Future<int> markTimeLogAsSynced(int localTimeLogId, String firebaseDocId) async {
    Database db = await instance.database;
    return await db.update(
      tableTimeLogs,
      {
        columnTimeLogIsSynced: 1,
        columnTimeLogFirebaseDocId: firebaseDocId,
      },
      where: 'id = ?',
      whereArgs: [localTimeLogId],
    );
  }

  Future<TimeLogModel?> getOpenTimeLogForCashier(String cashierId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTimeLogs,
      where: '$columnTimeLogCashierId = ? AND $columnTimeLogLogoutTime IS NULL',
      whereArgs: [cashierId],
      orderBy: '$columnTimeLogLoginTime DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return TimeLogModel.fromMap(maps.first);
    }
    return null;
  }
  
  Future<List<TimeLogModel>> getAllTimeLogs({String? orderBy}) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(tableTimeLogs, orderBy: orderBy ?? '$columnTimeLogLoginTime DESC');
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) {
      return TimeLogModel.fromMap(maps[i]);
    });
  }

} 