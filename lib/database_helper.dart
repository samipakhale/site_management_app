import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get currentUserIdentifier {
    return _auth.currentUser?.uid;
  }

  String? get currentUserEmail {
    return _auth.currentUser?.email;
  }

  Future<bool> registerUser(String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );

      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email.trim().toLowerCase(),
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

  Future<bool> checkLogin(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );

      return credential.user != null;
    } catch (e) {
      debugPrint('Firebase Login Error: $e');
      return false;
    }
  }

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

  Future<List<Map<String, dynamic>>> getSites() async {
    if (currentUserIdentifier == null) return [];
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUserIdentifier)
          .collection('sites')
          .get(const GetOptions(source: Source.serverAndCache));

      return snapshot.docs.map((doc) => {'name': doc['name'].toString()}).toList();
    } catch (e) {
      debugPrint('Get Sites Error: $e');
      return [];
    }
  }

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

  Future<void> deleteExpenseById(String siteName, String categoryName, dynamic id) async {
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
//adde by me for swipe delete site//
Future<void> deleteSite(String siteName) async {
    if (currentUserIdentifier == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(currentUserIdentifier)
          .collection('sites')
          .doc(siteName.trim())
          .delete();
    } catch (e) {
      debugPrint('Delete Site Error: $e');
    }
  }
  
//changes end here 
  Future<void> updateExpense(String siteName, String categoryName, Map<String, dynamic> updatedExpense) async {
    await addExpense(siteName, categoryName, updatedExpense);
  }
}