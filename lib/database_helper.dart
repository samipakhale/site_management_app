import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  static Database? _database;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get currentUserIdentifier => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;

  // 👉 Local SQLite Database Setup
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('site_management.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        siteName TEXT,
        categoryName TEXT,
        title TEXT,
        amount TEXT,
        desc TEXT,
        date TEXT
      )
    ''');
  }

  // 👉 Insert Site (Local + Firebase)
  Future<void> insertSite(String name) async {
    String cleanName = name.trim();
    
    // Local SQLite save
    final db = await database;
    await db.insert('sites', {'name': cleanName}, conflictAlgorithm: ConflictAlgorithm.replace);

    // Firebase save
    if (currentUserIdentifier != null) {
      try {
        await _firestore
            .collection('users')
            .doc(currentUserIdentifier)
            .collection('sites')
            .doc(cleanName)
            .set({'name': cleanName, 'updatedAt': FieldValue.serverTimestamp()});
      } catch (e) {
        debugPrint('Firebase Site Insert Error: $e');
      }
    }
  }

  // 👉 Get Sites (Local first, then Firebase sync)
  Future<List<Map<String, dynamic>>> getSites() async {
    final db = await database;
    final localResult = await db.query('sites');
    List<Map<String, dynamic>> sites = localResult.map((e) => {'name': e['name'].toString()}).toList();

    // If online, fetch from Firebase and merge
    if (currentUserIdentifier != null) {
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('users')
            .doc(currentUserIdentifier)
            .collection('sites')
            .get();

        for (var doc in snapshot.docs) {
          String sName = doc['name'].toString();
          if (!sites.any((s) => s['name'] == sName)) {
            sites.add({'name': sName});
            await db.insert('sites', {'name': sName}, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      } catch (e) {
        debugPrint('Get Sites Firebase Error: $e');
      }
    }
    return sites;
  }

  // 👉 Add Expense (Local + Firebase)
  Future<void> addExpense(String siteName, String categoryName, Map<String, dynamic> expenseData) async {
    final db = await database;
    await db.insert('expenses', {
      'id': expenseData['id'].toString(),
      'siteName': siteName.trim(),
      'categoryName': categoryName.trim(),
      'title': expenseData['title'],
      'amount': expenseData['amount'],
      'desc': expenseData['desc'],
      'date': expenseData['date'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    if (currentUserIdentifier != null) {
      try {
        await _firestore
            .collection('users')
            .doc(currentUserIdentifier)
            .collection('sites')
            .doc(siteName.trim())
            .collection('categories')
            .doc(categoryName.trim())
            .collection('expenses')
            .doc(expenseData['id'].toString())
            .set(expenseData);
      } catch (e) {
        debugPrint('Add Expense Firebase Error: $e');
      }
    }
  }

  // 👉 Get Expenses (Local + Firebase Sync)
  Future<List<Map<String, dynamic>>> getExpenses(String siteName, String categoryName) async {
    final db = await database;
    final localResult = await db.query(
      'expenses',
      where: 'siteName = ? AND categoryName = ?',
      whereArgs: [siteName.trim(), categoryName.trim()],
    );

    List<Map<String, dynamic>> expenses = localResult.map((e) => {
      'id': e['id'],
      'title': e['title'],
      'amount': e['amount'],
      'desc': e['desc'],
      'date': e['date'],
    }).toList();

    if (currentUserIdentifier != null) {
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('users')
            .doc(currentUserIdentifier)
            .collection('sites')
            .doc(siteName.trim())
            .collection('categories')
            .doc(categoryName.trim())
            .collection('expenses')
            .get();

        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          if (!expenses.any((ex) => ex['id'].toString() == data['id'].toString())) {
            expenses.add(data);
            await db.insert('expenses', {
              'id': data['id'].toString(),
              'siteName': siteName.trim(),
              'categoryName': categoryName.trim(),
              'title': data['title'],
              'amount': data['amount'],
              'desc': data['desc'],
              'date': data['date'],
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      } catch (e) {
        debugPrint('Get Expenses Firebase Error: $e');
      }
    }
    return expenses;
  }

  // 👉 Delete Expense (Local + Firebase)
  Future<void> deleteExpenseById(String siteName, String categoryName, dynamic id) async {
    final db = await database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id.toString()],
    );

    if (currentUserIdentifier != null) {
      try {
        await _firestore
            .collection('users')
            .doc(currentUserIdentifier)
            .collection('sites')
            .doc(siteName.trim())
            .collection('categories')
            .doc(categoryName.trim())
            .collection('expenses')
            .doc(id.toString())
            .delete();
      } catch (e) {
        debugPrint('Delete Expense Firebase Error: $e');
      }
    }
  }

  Future<void> updateExpense(String siteName, String categoryName, Map<String, dynamic> updatedExpense) async {
    await addExpense(siteName, categoryName, updatedExpense);
  }
}