import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 👉 User Registration in Firestore
  Future<bool> registerUser(String identifier, String password) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('identifier', isEqualTo: identifier)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return false; // User already exists
      }

      await _firestore.collection('users').add({
        'identifier': identifier,
        'password': password,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // 👉 Check Login from Firestore
  Future<bool> checkLogin(String identifier, String password) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('identifier', isEqualTo: identifier)
          .where('password', isEqualTo: password)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // 👉 Insert Site in Firestore
  Future<void> insertSite(String name) async {
    try {
      await _firestore.collection('sites').add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Handle error
    }
  }

  // 👉 Get Sites from Firestore
  Future<List<Map<String, dynamic>>> getSites() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('sites').get();
      return snapshot.docs.map((doc) {
        return {'name': doc['name'].toString()};
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // 👉 Add Expense to Firestore
  Future<void> addExpense(String siteName, String categoryName, Map<String, dynamic> expenseData) async {
    try {
      await _firestore
          .collection('sites')
          .doc(siteName)
          .collection(categoryName)
          .doc(expenseData['id'].toString())
          .set(expenseData);
    } catch (e) {
      // Handle error
    }
  }

  // 👉 Get Expenses from Firestore
  Future<List<Map<String, dynamic>>> getExpenses(String siteName, String categoryName) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('sites')
          .doc(siteName)
          .collection(categoryName)
          .get();

      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // 👉 Delete Expense by ID from Firestore
  Future<void> deleteExpenseById(String siteName, String categoryName, int id) async {
    try {
      await _firestore
          .collection('sites')
          .doc(siteName)
          .collection(categoryName)
          .doc(id.toString())
          .delete();
    } catch (e) {
      // Handle error
    }
  }

  // 👉 Update Expense in Firestore
  Future<void> updateExpense(String siteName, String categoryName, Map<String, dynamic> updatedExpense) async {
    try {
      await _firestore
          .collection('sites')
          .doc(siteName)
          .collection(categoryName)
          .doc(updatedExpense['id'].toString())
          .update(updatedExpense);
    } catch (e) {
      // Handle error
    }
  }
}