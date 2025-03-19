import 'package:flutter/material.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/database/database_service.dart';
import 'package:expense_tracker/widgets/monthly_summary.dart';
import 'package:intl/intl.dart';

class MonthlyExpensesScreen extends StatefulWidget {
  final Function? onExpenseUpdated;

  const MonthlyExpensesScreen({super.key, this.onExpenseUpdated});

  @override
  State<MonthlyExpensesScreen> createState() => _MonthlyExpensesScreenState();
}

class _MonthlyExpensesScreenState extends State<MonthlyExpensesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  DateTime _selectedDate = DateTime.now();

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    });
    if (widget.onExpenseUpdated != null) {
      widget.onExpenseUpdated!();
    }
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    });
    if (widget.onExpenseUpdated != null) {
      widget.onExpenseUpdated!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenses = _databaseService.getExpensesByMonth(
      _selectedDate.year,
      _selectedDate.month,
    );

    final totalExpense = expenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );

    final colorScheme = Theme.of(context).colorScheme;

    // Group expenses by category
    final categoryExpenses = <String, double>{};
    for (var expense in expenses) {
      if (categoryExpenses.containsKey(expense.category)) {
        categoryExpenses[expense.category] =
            categoryExpenses[expense.category]! + expense.amount;
      } else {
        categoryExpenses[expense.category] = expense.amount;
      }
    }

    // Group expenses by day
    final dailyExpenses = <int, double>{};
    for (var expense in expenses) {
      final day = expense.date.day;
      if (dailyExpenses.containsKey(day)) {
        dailyExpenses[day] = dailyExpenses[day]! + expense.amount;
      } else {
        dailyExpenses[day] = expense.amount;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: colorScheme.primary,
                    ),
                    onPressed: _previousMonth,
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedDate),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: colorScheme.primary,
                    ),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child:
                expenses.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart,
                            size: 80,
                            color: colorScheme.tertiary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No expenses for this month',
                            style: TextStyle(
                              fontSize: 18,
                              color: colorScheme.tertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the + button to add an expense',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.tertiary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                    : MonthlySummary(
                      totalAmount: totalExpense,
                      categoryExpenses: categoryExpenses,
                      dailyExpenses: dailyExpenses,
                      daysInMonth:
                          DateTime(
                            _selectedDate.year,
                            _selectedDate.month + 1,
                            0,
                          ).day,
                    ),
          ),
        ],
      ),
    );
  }
}
