import 'package:hive_flutter/hive_flutter.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/user_profile.dart';
import 'package:expense_tracker/models/loan.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class DatabaseService {
  static const String _expensesBoxName = 'expenses';
  static const String _userProfileBoxName = 'user_profile';
  static const String _loansBoxName = 'loans';
  static final DatabaseService _instance = DatabaseService._internal();
  final _uuid = Uuid();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<void> initDatabase() async {
    try {
      Directory directory = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(directory.path);

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ExpenseAdapter());
      }

      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(UserProfileAdapter());
      }

      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(LoanAdapter());
      }

      // Open boxes
      await _openBoxes();

      // Create default user profile if it doesn't exist
      await _initializeUserProfile();
    } catch (e) {
      print('Error initializing database: $e');
      // Try a complete reset if there's an error
      await _resetDatabase();
    }
  }

  Future<void> _openBoxes() async {
    try {
      if (!Hive.isBoxOpen(_expensesBoxName)) {
        await Hive.openBox<Expense>(_expensesBoxName);
      }

      if (!Hive.isBoxOpen(_userProfileBoxName)) {
        await Hive.openBox<UserProfile>(_userProfileBoxName);
      }

      if (!Hive.isBoxOpen(_loansBoxName)) {
        await Hive.openBox<Loan>(_loansBoxName);
      }
    } catch (e) {
      print('Error opening boxes: $e');
      throw e;
    }
  }

  Future<void> _initializeUserProfile() async {
    final userProfileBox = getUserProfileBox();
    if (userProfileBox.isEmpty) {
      await userProfileBox.put('user', UserProfile());
    }
  }

  Future<void> _resetDatabase() async {
    try {
      // Close boxes first
      await Hive.close();

      // Delete boxes
      await Hive.deleteBoxFromDisk(_userProfileBoxName);
      await Hive.deleteBoxFromDisk(_expensesBoxName);
      await Hive.deleteBoxFromDisk(_loansBoxName);

      // Re-register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ExpenseAdapter());
      }

      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(UserProfileAdapter());
      }

      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(LoanAdapter());
      }

      // Re-open boxes
      await Hive.openBox<Expense>(_expensesBoxName);
      await Hive.openBox<UserProfile>(_userProfileBoxName);
      await Hive.openBox<Loan>(_loansBoxName);

      // Create new default profile
      final userProfileBox = getUserProfileBox();
      await userProfileBox.put('user', UserProfile());
    } catch (e) {
      print('Error resetting database: $e');
    }
  }

  Box<Expense> getExpensesBox() {
    return Hive.box<Expense>(_expensesBoxName);
  }

  Box<UserProfile> getUserProfileBox() {
    return Hive.box<UserProfile>(_userProfileBoxName);
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

  Future<List<Expense>> getExpenses() async {
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

  Future<UserProfile> getUserProfile() async {
    final userProfileBox = getUserProfileBox();
    return userProfileBox.get('user') ?? UserProfile();
  }

  Future<void> updateUserProfile({
    String? name,
    double? monthlyIncome,
    String? profileImagePath,
    double? savingsTarget,
  }) async {
    final userProfileBox = getUserProfileBox();
    final currentProfile = await getUserProfile();

    final updatedProfile = UserProfile(
      name: name ?? currentProfile.name,
      monthlyIncome: monthlyIncome ?? currentProfile.monthlyIncome,
      profileImagePath: profileImagePath ?? currentProfile.profileImagePath,
      savingsTarget: savingsTarget ?? currentProfile.savingsTarget,
    );

    await userProfileBox.put('user', updatedProfile);
  }

  // LOAN METHODS

  Box<Loan> getLoansBox() {
    return Hive.box<Loan>(_loansBoxName);
  }

  Future<void> addLoan({
    required String title,
    required double amount,
    required double interestRate,
    required DateTime startDate,
    required int durationMonths,
    required double monthlyPayment,
    required String lender,
  }) async {
    final loansBox = getLoansBox();
    final loan = Loan(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      interestRate: interestRate,
      startDate: startDate,
      durationMonths: durationMonths,
      monthlyPayment: monthlyPayment,
      lender: lender,
      remainingAmount: amount,
    );
    await loansBox.add(loan);
  }

  List<Loan> getAllLoans() {
    final loansBox = getLoansBox();
    return loansBox.values.toList();
  }

  List<Loan> getActiveLoans() {
    final loansBox = getLoansBox();
    return loansBox.values.where((loan) => loan.isActive).toList();
  }

  Future<void> updateLoanRemainingAmount(
    String id,
    double remainingAmount,
  ) async {
    final loansBox = getLoansBox();
    final keys = loansBox.keys.toList();
    final loans = loansBox.values.toList();

    bool updated = false;
    for (int i = 0; i < loans.length; i++) {
      if (loans[i].id == id) {
        final loan = loans[i];
        final updatedLoan = Loan(
          id: loan.id,
          title: loan.title,
          amount: loan.amount,
          interestRate: loan.interestRate,
          startDate: loan.startDate,
          durationMonths: loan.durationMonths,
          monthlyPayment: loan.monthlyPayment,
          lender: loan.lender,
          isActive: remainingAmount > 0,
          remainingAmount: remainingAmount,
        );

        await loansBox.put(keys[i], updatedLoan);
        updated = true;
        print(
          'Loan updated: ${loan.title}, remaining: $remainingAmount, active: ${remainingAmount > 0}',
        );
        break;
      }
    }

    if (!updated) {
      print('Failed to update loan with ID: $id');
    }
  }

  Future<void> deleteLoan(String id) async {
    final loansBox = getLoansBox();
    final keys = loansBox.keys.toList();
    final loans = loansBox.values.toList();

    for (int i = 0; i < loans.length; i++) {
      if (loans[i].id == id) {
        await loansBox.delete(keys[i]);
        break;
      }
    }
  }

  // Get total monthly loan payments for active loans
  double getTotalMonthlyLoanPayments() {
    final activeLoans = getActiveLoans();
    return activeLoans.fold(0.0, (sum, loan) => sum + loan.monthlyPayment);
  }
}
