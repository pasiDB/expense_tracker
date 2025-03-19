import 'package:flutter/material.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/database/database_service.dart';
import 'package:expense_tracker/widgets/expense_list_item.dart';
import 'package:expense_tracker/widgets/daily_summary.dart';
import 'package:intl/intl.dart';

class DailyExpensesScreen extends StatefulWidget {
  final Function? onExpenseUpdated;
  final ScrollController? scrollController;

  const DailyExpensesScreen({
    super.key,
    this.onExpenseUpdated,
    this.scrollController,
  });

  @override
  State<DailyExpensesScreen> createState() => _DailyExpensesScreenState();
}

class _DailyExpensesScreenState extends State<DailyExpensesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final expenses = _databaseService.getExpensesByDate(_selectedDate);
    final totalExpense = expenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
    final colorScheme = Theme.of(context).colorScheme;

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
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.subtract(
                          const Duration(days: 1),
                        );
                      });
                    },
                  ),
                  Column(
                    children: [
                      Text(
                        DateFormat('EEEE').format(_selectedDate),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        DateFormat('MMMM d, yyyy').format(_selectedDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: colorScheme.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.add(
                          const Duration(days: 1),
                        );
                      });
                    },
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
                            Icons.receipt_long,
                            size: 80,
                            color: colorScheme.tertiary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No expenses for this day',
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
                    : ListView(
                      controller: widget.scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 80),
                      children: [
                        DailySummary(
                          expenses: expenses,
                          totalAmount: totalExpense,
                        ),
                        ...expenses
                            .map(
                              (expense) => ExpenseListItem(
                                expense: expense,
                                onDelete: () {
                                  setState(() {
                                    _databaseService.deleteExpense(expense.id);
                                    if (widget.onExpenseUpdated != null) {
                                      widget.onExpenseUpdated!();
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
