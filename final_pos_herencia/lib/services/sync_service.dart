import 'dart:async';
import 'dart:developer' as developer;
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../helpers/database_helper.dart';
import '../models/menu_item_model.dart';
import '../models/sale_model.dart';
import '../models/time_log_model.dart';
import '../models/cashier_model.dart';

class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _timerBasedSyncTimer;
  StreamSubscription? _menuItemsSubscription;

  // Collection names
  static const String _menuItemsCollection = 'menu';
  static const String _salesCollection = 'sales';
  static const String _timeLogsCollection = 'timeLogs';
  static const String _cashiersCollection = 'cashiers';

  Future<void> populateMockMenuData(List<Map<String, dynamic>> mockRawItems) async {
    List<MenuItemModel> menuItemsToSave = [];
    for (var rawItem in mockRawItems) {
      menuItemsToSave.add(MenuItemModel(
        id: rawItem['id'] as String,
        name: rawItem['name'] as String,
        categoryId: rawItem['categoryId'] as String,
        price: (rawItem['price'] as num).toDouble(),
        imageUrl: rawItem['imageUrl'] as String?,
        stock: rawItem['stock'] as int? ?? 0,
        varieties: List<String>.from(rawItem['varieties'] ?? []),
        description: rawItem['description'] as String?,
        firebaseDocId: rawItem['id'] as String,
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      ));
    }
    if (menuItemsToSave.isNotEmpty) {
      try {
        await _dbHelper.batchUpsertMenuItems(menuItemsToSave);
        developer.log("SyncService: Mock menu data populated/updated into sqflite.");
      } catch (e, s) {
        developer.log("SyncService: Error populating mock menu data", error: e, stackTrace: s);
      }
    }
  }

  //Connectivity Check
  Future<bool> _isConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.mobile) || 
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet) ||
        connectivityResult.contains(ConnectivityResult.vpn)) {
      return true;
    }
    developer.log("SyncService: No internet connection detected. Results: $connectivityResult");
    return false;
  }

  Future<void> syncAllData({bool isManualSync = false, bool isBackgroundTask = false }) async {
    developer.log("SyncService: Attempting to sync all data. Manual: $isManualSync");
    
    if (!await _isConnected()) {
      developer.log("SyncService: No internet connection. Sync aborted.");
      return;
    }

    try {
      await fetchCashiersFromFirebase();
      await pushSalesToFirebase();
      await pushTimeLogsToFirebase();
      developer.log("SyncService: All data sync process finished successfully.");
    } catch (e, s) {
      developer.log("SyncService: Error during syncAllData", error: e, stackTrace: s);
    }
  }
  void startPeriodicTimerBasedSync({Duration interval = const Duration(minutes: 15)}) {
    developer.log("SyncService: Starting periodic timer-based sync with interval: ${interval.inMinutes} minutes.");
    _timerBasedSyncTimer?.cancel();
    _timerBasedSyncTimer = Timer.periodic(interval, (timer) {
      developer.log("SyncService: Periodic timer-based sync triggered.");
      syncAllData(isManualSync: false);
    });
  }

  void stopPeriodicTimerBasedSync() {
    developer.log("SyncService: Stopping periodic timer-based sync.");
    _timerBasedSyncTimer?.cancel();
  }
  void listenToMenuUpdatesFromFirebase() async {
    developer.log("SyncService: Starting to listen for real-time menu updates from Firebase.");
    if (!await _isConnected()) {
       developer.log("SyncService: No connection to start listening to menu updates.");
       return;
    }
    _menuItemsSubscription?.cancel();
    _menuItemsSubscription = _firestore.collection(_menuItemsCollection)
      .snapshots().listen((snapshot) async {
        developer.log("SyncService: Received menu data snapshot with ${snapshot.docs.length} documents. Changes: ${snapshot.docChanges.length}");
        List<MenuItemModel> firebaseMenuItems = [];
        bool hasChanges = false;

        for (var docChange in snapshot.docChanges) {
          hasChanges = true;
          Map<String, dynamic>? data = docChange.doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          MenuItemModel item = MenuItemModel.fromMap(data).copyWith(
                                id: docChange.doc.id,
                                firebaseDocId: docChange.doc.id
                              );

          if (docChange.type == DocumentChangeType.added || docChange.type == DocumentChangeType.modified) {
            firebaseMenuItems.add(item);
          } else if (docChange.type == DocumentChangeType.removed) {
            await _dbHelper.deleteMenuItem(item.id);
          }
        }
        
        if (firebaseMenuItems.isNotEmpty) {
          await _dbHelper.batchUpsertMenuItems(firebaseMenuItems);
          developer.log("SyncService: ${firebaseMenuItems.length} menu items processed (added/modified) from real-time updates.");
        } else if (hasChanges) {
           developer.log("SyncService: Menu items removed, no new items/modifications in this snapshot update.");
        } else if (snapshot.metadata.hasPendingWrites) {
            developer.log("SyncService: Menu snapshot has pending writes. Data might be stale locally.");
        } else {
            developer.log("SyncService: No effective changes in menu snapshot or only local writes reflected.");
        }

    }, onError: (error, stackTrace) {
      developer.log("SyncService: Error listening to menu updates", error: error, stackTrace: stackTrace);
    });
  }

  void stopListeningToMenuUpdates() {
    developer.log("SyncService: Stopping real-time menu updates listener.");
    _menuItemsSubscription?.cancel();
    _menuItemsSubscription = null;
  }
  
  Future<void> fetchMenuFromFirebasePaginated({int pageSize = 50}) async {
    developer.log("SyncService: Fetching menu from Firebase with pagination (page size: $pageSize)...");
    if (!await _isConnected()) return;

    try {
      Query query = _firestore.collection(_menuItemsCollection).orderBy('name').limit(pageSize);
      bool moreDataAvailable = true;
      DocumentSnapshot? lastDocument;
      int totalFetched = 0;

      while (moreDataAvailable) {
        QuerySnapshot snapshot;
        if (lastDocument == null) {
          snapshot = await query.get();
        } else {
          snapshot = await query.startAfterDocument(lastDocument).get();
        }

        if (snapshot.docs.isEmpty) {
          moreDataAvailable = false;
          break;
        }
        
        lastDocument = snapshot.docs.last;
        List<MenuItemModel> pageItems = [];
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          pageItems.add(MenuItemModel.fromMap(data).copyWith(
            id: doc.id,
            firebaseDocId: doc.id
          ));
        }

        if (pageItems.isNotEmpty) {
          await _dbHelper.batchUpsertMenuItems(pageItems);
          totalFetched += pageItems.length;
          developer.log("SyncService: Fetched and upserted ${pageItems.length} menu items (page). Total so far: $totalFetched");
        }
        
        if (snapshot.docs.length < pageSize) {
          moreDataAvailable = false;
        }
      }
      developer.log("SyncService: Finished paginated menu fetch. Total items fetched: $totalFetched");

    } catch (e, s) {
      developer.log("SyncService: Error fetching paginated menu from Firebase", error: e, stackTrace: s);
    }
  }


  Future<void> fetchCashiersFromFirebase() async {
    developer.log("SyncService: Fetching cashiers from Firebase...");
    if (!await _isConnected()) return;

    try {
      QuerySnapshot snapshot = await _firestore.collection(_cashiersCollection).get();
      List<CashierModel> firebaseCashiers = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        firebaseCashiers.add(CashierModel.fromMap(data).copyWith(id: doc.id)); 
      }

      if (firebaseCashiers.isNotEmpty) {
        await _dbHelper.batchUpsertCashiers(firebaseCashiers);
        developer.log("SyncService: ${firebaseCashiers.length} cashiers fetched and upserted into local DB.");
      } else {
        developer.log("SyncService: No cashiers to update from Firebase.");
      }
    } catch (e, s) {
      developer.log("SyncService: Error fetching cashiers from Firebase", error: e, stackTrace: s);
    }
  }


  Future<void> pushSalesToFirebase() async {
    developer.log("SyncService: Attempting to push unsynced sales to Firebase...");
    if (!await _isConnected()) return;
    
    List<SaleModel> unsyncedSales = [];
    try {
      unsyncedSales = await _dbHelper.getUnsyncedSales();
    } catch (e,s) {
      developer.log("SyncService: Error fetching unsynced sales from local DB", error: e, stackTrace: s);
      return;
    }
    developer.log("SyncService: Found ${unsyncedSales.length} unsynced sales.");

    if (unsyncedSales.isEmpty) {
      developer.log("SyncService: No unsynced sales to push.");
      return;
    }

    for (SaleModel sale in unsyncedSales) {
      try {
        DocumentReference docRef;
        Map<String, dynamic> saleData = sale.toMap(); 
        saleData.remove('id'); 
        saleData.remove('isSynced'); 

        if (sale.firebaseDocId != null && sale.firebaseDocId!.isNotEmpty) {
          docRef = _firestore.collection(_salesCollection).doc(sale.firebaseDocId);
          await docRef.set(saleData, SetOptions(merge: true)); 
          developer.log("SyncService: Updated sale ${sale.firebaseDocId} in Firebase.");
        } else {
          docRef = await _firestore.collection(_salesCollection).add(saleData);
          developer.log("SyncService: Added new sale to Firebase with ID: ${docRef.id}. Local ID was: ${sale.id}");
        }
        
        await _dbHelper.markSaleAsSynced(sale.id!, docRef.id);
        developer.log("SyncService: Sale ${sale.id} (Firebase: ${docRef.id}) marked as synced locally.");

      } catch (e, s) {
        developer.log("SyncService: Error pushing sale ${sale.id} to Firebase", error: e, stackTrace: s);
      }
    }
    developer.log("SyncService: Finished pushing sales.");
  }

  Future<void> pushTimeLogsToFirebase() async {
    developer.log("SyncService: Attempting to push unsynced time logs to Firebase...");
    if (!await _isConnected()) return;

    List<TimeLogModel> unsyncedTimeLogs = [];
    try {
      unsyncedTimeLogs = await _dbHelper.getUnsyncedTimeLogs();
    } catch(e,s) {
       developer.log("SyncService: Error fetching unsynced time logs from local DB", error: e, stackTrace: s);
      return;
    }
    developer.log("SyncService: Found ${unsyncedTimeLogs.length} unsynced time logs.");

    if (unsyncedTimeLogs.isEmpty) {
      developer.log("SyncService: No unsynced time logs to push.");
      return;
    }

    for (TimeLogModel timeLog in unsyncedTimeLogs) {
      try {
        DocumentReference docRef;
        Map<String, dynamic> timeLogData = timeLog.toMap();
        timeLogData.remove('id'); 
        timeLogData.remove('isSynced');

        if (timeLog.firebaseDocId != null && timeLog.firebaseDocId!.isNotEmpty) {
          docRef = _firestore.collection(_timeLogsCollection).doc(timeLog.firebaseDocId);
          await docRef.set(timeLogData, SetOptions(merge: true));
          developer.log("SyncService: Updated time log ${timeLog.firebaseDocId} in Firebase.");
        } else {
          docRef = await _firestore.collection(_timeLogsCollection).add(timeLogData);
          developer.log("SyncService: Added new time log to Firebase with ID: ${docRef.id}. Local ID was: ${timeLog.id}");
        }
        
        await _dbHelper.markTimeLogAsSynced(timeLog.id!, docRef.id);
        developer.log("SyncService: TimeLog ${timeLog.id} (Firebase: ${docRef.id}) marked as synced locally.");

      } catch (e, s) {
        developer.log("SyncService: Error pushing time log ${timeLog.id} to Firebase", error: e, stackTrace: s);
      }
    }
    developer.log("SyncService: Finished pushing time logs.");
  }

  Future<void> populateMockMenuDataToFirebase() async {
    developer.log("SyncService: Attempting to populate Firebase with mock menu data...");
    if (!await _isConnected()) return;
    
    final List<Map<String, dynamic>> localMockData = [ 
        {'id': 'p1', 'name': 'American Favorite', 'categoryId': 'main', 'price': 4.87, 'imageUrl': 'assets/images/pizza.png', 'stock': 18, 'varieties': ["Regular", "Large", "Extra Large"], 'description': "A classic American pizza", 'last_updated': DateTime.now().millisecondsSinceEpoch},
    ];

    List<MenuItemModel> menuItemsToSave = [];
    for (var rawItem in localMockData) {
         menuItemsToSave.add(MenuItemModel.fromMap(rawItem).copyWith(id: rawItem['id']));
    }

    if (menuItemsToSave.isEmpty) {
        developer.log("SyncService: No mock data provided/formatted to populate Firebase. Skipping.");
        return;
    }

    WriteBatch batch = _firestore.batch();
    int count = 0;
    try {
      for (var itemModel in menuItemsToSave) {
        Map<String, dynamic> itemData = itemModel.copyWith(
        ).toMap(); 
        

        DocumentReference docRef = _firestore.collection(_menuItemsCollection).doc(itemModel.id);
        batch.set(docRef, itemData);
        count++;
        if (count % 499 == 0) { 
          await batch.commit();
          batch = _firestore.batch();
          developer.log("SyncService: Committed a batch of $count items to Firebase menu.");
        }
      }
      if (count % 499 != 0 && count > 0) { 
          await batch.commit();
      }
      developer.log("SyncService: Successfully populated $count mock menu items to Firebase.");
    } catch (e, s) {
       developer.log("SyncService: Error populating mock menu data to Firebase", error: e, stackTrace: s);
    }
  }
  
  void dispose() {
    developer.log("SyncService: Disposing SyncService resources.");
    _timerBasedSyncTimer?.cancel();
    _menuItemsSubscription?.cancel();
  }
} 