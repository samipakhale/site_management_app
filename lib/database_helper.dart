import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  
  DatabaseHelper._init() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static String? currentUserIdentifier;

  // 👉 Registration (Re-install nantar pn data secure thevayla)
  Future<bool> registerUser(String identifier, String password) async {
    try {
      String cleanId = identifier.trim().toLowerCase();
      String cleanPass = password.trim();

      if (cleanId.isEmpty || cleanPass.isEmpty) return false;

      final docRef = _firestore.collection('users').doc(cleanId);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        return false; 
      }

      await docRef.set({
        'identifier': cleanId,
        'password': cleanPass,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Registration Error: $e');
      return false;
    }
  }

  // 👉 Login (Offline asel tari local cache madhun check hoil)
  Future<bool> checkLogin(String identifier, String password) async {
    try {
      String cleanId = identifier.trim().toLowerCase();
      String cleanPass = password.trim();

      if (cleanId.isEmpty || cleanPass.isEmpty) return false;

      final docRef = _firestore.collection('users').doc(cleanId);
      
      DocumentSnapshot docSnap;
      try {
        docSnap = await docRef.get(const GetOptions(source: Source.serverAndCache));
      } catch (_) {
        docSnap = await docRef.get(const GetOptions(source: Source.cache));
      }

      if (docSnap.exists) {
        final data = docSnap.data() as Map<String, dynamic>?;
        if (data != null && data['password'].toString().trim() == cleanPass) {
          currentUserIdentifier = cleanId;
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Login Error: $e');
      return false;
    }
  }

  // 👉 Insert Site
  Future<void> insertSite(String name) async {
    if (currentUserIdentifier == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(currentUserIdentifier)
          .collection('sites')
          .doc(name.trim())
          .set({
        'name': name.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Site Insert Error: $e');
    }
  }

  // 👉 Get Sites (Offline cache & Server support)
  Future<List<Map<String, dynamic>>> getSites() async {
    if (currentUserIdentifier == null) return [];
    try {
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('users')
            .doc(currentUserIdentifier)
            .collection('sites')
            .get(const GetOptions(source: Source.serverAndCache));
      } catch (_) {
        snapshot = await _firestore
            .collection('users')
            .doc(currentUserIdentifier)
            .collection('sites')
            .get(const GetOptions(source: Source.cache));
      }

      return snapshot.docs.map((doc) {
        return {'name': doc['name'].toString()};
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // 👉 Add Expense
  Future<void> addExpense(String siteName, String categoryName, Map<String, dynamic> expenseData) async {
    if (currentUserIdentifier == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(currentUserIdentifier)
          .collection('sites')
          .doc(siteName.trim())
          .collection(categoryName.trim())
          .doc(expenseData['id'].toString())
          .set(expenseData);
    } catch (e) {
      debugPrint('Add Expense Error: $e');
    }
  }

  // 👉 Get Expenses
  Future<List<Map<String, dynamic>>> getExpenses(String siteName, String categoryName) async {
    if (currentUserIdentifier == null) return [];
    try {
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('users')
            .doc(currentUserIdentifier)
            .collection('sites')
            .doc(siteName.trim())
            .collection(categoryName.trim())
            .get(const GetOptions(source: Source.serverAndCache));
      } catch (_) {
        snapshot = await _firestore
            .collection('users')
            .doc(currentUserIdentifier)
            .collection('sites')
            .doc(siteName.trim())
            .collection(categoryName.trim())
            .get(const GetOptions(source: Source.cache));
      }

      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // 👉 Delete Expense
  Future<void> deleteExpenseById(String siteName, String categoryName, int id) async {
    if (currentUserIdentifier == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(currentUserIdentifier)
          .collection('sites')
          .doc(siteName.trim())
          .collection(categoryName.trim())
          .doc(id.toString())
          .delete();
    } catch (e) {
      debugPrint('Delete Error: $e');
    }
  }

  // 👉 Update Expense
  Future<void> updateExpense(String siteName, String categoryName, Map<String, dynamic> updatedExpense) async {
    if (currentUserIdentifier == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(currentUserIdentifier)
          .collection('sites')
          .doc(siteName.trim())
          .collection(categoryName.trim())
          .doc(updatedExpense['id'].toString())
          .update(updatedExpense);
    } catch (e) {
      debugPrint('Update Error: $e');
    }
  }
}