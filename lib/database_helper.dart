import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // 👉 User Registration with direct document ID
  Future<bool> registerUser(String identifier, String password) async {
    try {
      String cleanId = identifier.trim().toLowerCase();
      String cleanPass = password.trim();

      final docRef = _firestore.collection('users').doc(cleanId);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        return false; // User already exists
      }

      await docRef.set({
        'identifier': cleanId,
        'password': cleanPass,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // 👉 Check Login from Firestore
  Future<bool> checkLogin(String identifier, String password) async {
    try {
      String cleanId = identifier.trim().toLowerCase();
      String cleanPass = password.trim();

      final docRef = _firestore.collection('users').doc(cleanId);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        final data = docSnap.data();
        if (data != null && data['password'] == cleanPass) {
          currentUserIdentifier = cleanId;
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // 👉 Insert Site in Firestore under User
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
      debugPrint('Error inserting site: $e');
    }
  }

  // 👉 Get Sites from Firestore for User
  Future<List<Map<String, dynamic>>> getSites() async {
    if (currentUserIdentifier == null) return [];
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUserIdentifier)
          .collection('sites')
          .get();

      return snapshot.docs.map((doc) {
        return {'name': doc['name'].toString()};
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // 👉 Add Expense to Firestore
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
      debugPrint('Error adding expense: $e');
    }
  }

  // 👉 Get Expenses from Firestore
  Future<List<Map<String, dynamic>>> getExpenses(String siteName, String categoryName) async {
    if (currentUserIdentifier == null) return [];
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUserIdentifier)
          .collection('sites')
          .doc(siteName.trim())
          .collection(categoryName.trim())
          .get();

      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // 👉 Delete Expense by ID from Firestore
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
      debugPrint('Error deleting expense: $e');
    }
  }

  // 👉 Update Expense in Firestore
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
      debugPrint('Error updating expense: $e');
    }
  }
}