import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  static String? currentUserIdentifier;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 👉 Register User with Firebase Auth & Firestore
  Future<bool> registerUser(String identifier, String password) async {
    try {
      String email = identifier.contains('@') 
          ? identifier.trim().toLowerCase() 
          : '${identifier.trim()}@sitemanagement.com';

      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password.trim(),
      );

      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'identifier': identifier.trim().toLowerCase(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Firebase Registration Error: $e');
      return false;
    }
  }

  // 👉 Check Login with Firebase Auth
  Future<bool> checkLogin(String identifier, String password) async {
    try {
      String email = identifier.contains('@') 
          ? identifier.trim().toLowerCase() 
          : '${identifier.trim()}@sitemanagement.com';

      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password.trim(),
      );

      if (credential.user != null) {
        currentUserIdentifier = credential.user!.uid;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', currentUserIdentifier!);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Firebase Login Error: $e');
      return false;
    }
  }

  // 👉 Insert Site to Firestore
  Future<void> insertSite(String name) async {
    if (currentUserIdentifier == null) return;
    try {
      String cleanName = name.trim();
      await _firestore
          .collection('users')
          .doc(currentUserIdentifier)
          .collection('sites')
          .doc(cleanName)
          .set({'name': cleanName, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Site Insert Error: $e');
    }
  }

  // 👉 Get Sites from Firestore
  Future<List<Map<String, dynamic>>> getSites() async {
    if (currentUserIdentifier == null) return [];
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUserIdentifier)
          .collection('sites')
          .get();

      return snapshot.docs.map((doc) => {'name': doc['name'].toString()}).toList();
    } catch (e) {
      debugPrint('Get Sites Error: $e');
      return [];
    }
  }

  // 👉 Add Expense to Firestore
  Future<void> addExpense(String siteName, String categoryName, Map<String, dynamic> expenseData) async {
    if (currentUserIdentifier == null) return;
    try {
      String expenseId = expenseData['id'].toString();
      await _firestore
          .collection('users')
          .doc(currentUserIdentifier)
          .collection('sites')
          .doc(siteName.trim())
          .collection('categories')
          .doc(categoryName.trim())
          .collection('expenses')
          .doc(expenseId)
          .set(expenseData);
    } catch (e) {
      debugPrint('Add Expense Error: $e');
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
          .collection('categories')
          .doc(categoryName.trim())
          .collection('expenses')
          .get();

      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Get Expenses Error: $e');
      return [];
    }
  }

  // 👉 Delete Expense from Firestore
  Future<void> deleteExpenseById(String siteName, String categoryName, int id) async {
    if (currentUserIdentifier == null) return;
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
      debugPrint('Delete Error: $e');
    }
  }

  // 👉 Update Expense
  Future<void> updateExpense(String siteName, String categoryName, Map<String, dynamic> updatedExpense) async {
    await addExpense(siteName, categoryName, updatedExpense);
  }
}