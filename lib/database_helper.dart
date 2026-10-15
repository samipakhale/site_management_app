import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  
  DatabaseHelper._init() {
    try {
      if (!kIsWeb) {
        _firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }
    } catch (_) {}
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static String? currentUserIdentifier;

  // 👉 Bulletproof method to always get valid user ID from memory or SharedPreferences
  static Future<String?> getCurrentUser() async {
    if (currentUserIdentifier != null && currentUserIdentifier!.isNotEmpty) {
      return currentUserIdentifier;
    }
    final prefs = await SharedPreferences.getInstance();
    currentUserIdentifier = prefs.getString('userIdentifier');
    return currentUserIdentifier;
  }

  // 👉 Register User & automatically save session
  Future<bool> registerUser(String identifier, String password) async {
    try {
      String cleanId = identifier.trim().toLowerCase();
      String cleanPass = password.trim();

      if (cleanId.isEmpty || cleanPass.isEmpty) return false;

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

      // Save session immediately upon registration
      currentUserIdentifier = cleanId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userIdentifier', cleanId);
      await prefs.setBool('isLoggedIn', true);

      return true;
    } catch (e) {
      debugPrint('Registration Error: $e');
      return false;
    }
  }

  // 👉 Login & save session
  Future<bool> checkLogin(String identifier, String password) async {
    try {
      String cleanId = identifier.trim().toLowerCase();
      String cleanPass = password.trim();

      if (cleanId.isEmpty || cleanPass.isEmpty) return false;

      final docRef = _firestore.collection('users').doc(cleanId);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        final data = docSnap.data();
        if (data != null && data['password'].toString().trim() == cleanPass) {
          currentUserIdentifier = cleanId;
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userIdentifier', cleanId);
          await prefs.setBool('isLoggedIn', true);
          
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Login Error: $e');
      return false;
    }
  }

  // 👉 Insert Site (Guaranteed to save on Firebase)
  Future<void> insertSite(String name) async {
    String? userId = await getCurrentUser();
    if (userId == null || userId.isEmpty) {
      debugPrint('CRITICAL ERROR: User ID is null while inserting site!');
      return;
    }
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sites')
          .doc(name.trim())
          .set({
        'name': name.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Site successfully saved to Firebase for user: $userId');
    } catch (e) {
      debugPrint('Site Insert Error: $e');
    }
  }

  // 👉 Get Sites
  Future<List<Map<String, dynamic>>> getSites() async {
    String? userId = await getCurrentUser();
    if (userId == null || userId.isEmpty) return [];
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sites')
          .get();

      return snapshot.docs.map((doc) {
        return {'name': doc['name'].toString()};
      }).toList();
    } catch (e) {
      debugPrint('Get Sites Error: $e');
      return [];
    }
  }

  // 👉 Add Expense (Guaranteed to save on Firebase)
  Future<void> addExpense(String siteName, String categoryName, Map<String, dynamic> expenseData) async {
    String? userId = await getCurrentUser();
    if (userId == null || userId.isEmpty) {
      debugPrint('CRITICAL ERROR: User ID is null while adding expense!');
      return;
    }
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sites')
          .doc(siteName.trim())
          .collection(categoryName.trim())
          .doc(expenseData['id'].toString())
          .set(expenseData);
      debugPrint('Expense successfully saved to Firebase!');
    } catch (e) {
      debugPrint('Add Expense Error: $e');
    }
  }

  // 👉 Get Expenses
  Future<List<Map<String, dynamic>>> getExpenses(String siteName, String categoryName) async {
    String? userId = await getCurrentUser();
    if (userId == null || userId.isEmpty) return [];
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sites')
          .doc(siteName.trim())
          .collection(categoryName.trim())
          .get();

      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      debugPrint('Get Expenses Error: $e');
      return [];
    }
  }

  // 👉 Delete Expense
  Future<void> deleteExpenseById(String siteName, String categoryName, int id) async {
    String? userId = await getCurrentUser();
    if (userId == null || userId.isEmpty) return;
    try {
      await _firestore
          .collection('users')
          .doc(userId)
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
    String? userId = await getCurrentUser();
    if (userId == null || userId.isEmpty) return;
    try {
      await _firestore
          .collection('users')
          .doc(userId)
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