import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:fund_tracker/models/category.dart';
import 'package:fund_tracker/models/transaction.dart';

class DatabaseService {
  final String uid;

  DatabaseService({this.uid});

  final CollectionReference usersCollection =
      Firestore.instance.collection('users');

  List<Transaction> _transactionsListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.documents.map((tx) {
      return Transaction(
        tid: tx.documentID,
        date:
            new DateTime.fromMillisecondsSinceEpoch(tx['date'].seconds * 1000),
        isExpense: tx['isExpense'],
        payee: tx['payee'],
        amount: tx['amount'].toDouble(),
        category: tx['category'],
      );
    }).toList();
  }

  Stream<List<Transaction>> get transactions {
    return usersCollection
        .document(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map(_transactionsListFromSnapshot);
  }

  Future addTransaction(Transaction tx) async {
    DocumentReference ref =
        await usersCollection.document(uid).collection('transactions').add({
      'date': tx.date,
      'isExpense': tx.isExpense,
      'payee': tx.payee,
      'amount': tx.amount,
      'category': tx.category
    });
    return ref;
  }

  Future updateTransaction(Transaction tx) async {
    print(tx.tid);
    return await usersCollection.document(uid).collection('transactions').document(tx.tid).updateData({
      'date': tx.date,
      'isExpense': tx.isExpense,
      'payee': tx.payee,
      'amount': tx.amount,
      'category': tx.category
    });
  }

  Future deleteTransaction(Transaction tx) async {
    print(tx.tid);
    return await usersCollection.document(uid).collection('transactions').document(tx.tid).delete();
  }

  List<Category> _categoriesListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.documents.map((category) {
      return Category(
        name: category['name'],
      );
    }).toList();
  }

  Stream<List<Category>> get categories {
    return usersCollection
        .document(uid)
        .collection('categories')
        .snapshots()
        .map(_categoriesListFromSnapshot);
  }
}
