import 'package:hive_flutter/hive_flutter.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class DatabaseService {
  static const String _expensesBoxName = 'expenses';
  static final DatabaseService _instance = DatabaseService._internal();
  final _uuid = Uuid();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<void> initDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(directory.path);
    Hive.registerAdapter(ExpenseAdapter());
    await Hive.openBox<Expense>(_expensesBoxName);
  }

  Box<Expense> getExpensesBox() {
    return Hive.box<Expense>(_expensesBoxName);
  }

  Future<void> addExpense(String title, double amount, String category) async {
    final expensesBox = getExpensesBox();
    final expense = Expense(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      date: DateTime.now(),
      category: category,
    );
    await expensesBox.add(expense);
  }

  List<Expense> getAllExpenses() {
    final expensesBox = getExpensesBox();
    return expensesBox.values.toList();
  }

  List<Expense> getExpensesByDate(DateTime date) {
    final expensesBox = getExpensesBox();
    return expensesBox.values
        .where(
          (expense) =>
              expense.date.year == date.year &&
              expense.date.month == date.month &&
              expense.date.day == date.day,
        )
        .toList();
  }

  List<Expense> getExpensesByMonth(int year, int month) {
    final expensesBox = getExpensesBox();
    return expensesBox.values
        .where(
          (expense) => expense.date.year == year && expense.date.month == month,
        )
        .toList();
  }

  Future<void> deleteExpense(String id) async {
    final expensesBox = getExpensesBox();
    final keys = expensesBox.keys.toList();
    final expenses = expensesBox.values.toList();

    for (int i = 0; i < expenses.length; i++) {
      if (expenses[i].id == id) {
        await expensesBox.delete(keys[i]);
        break;
      }
    }
  }
}
