import 'package:flutter/material.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:intl/intl.dart';

class ExpenseInsights extends StatelessWidget {
  final List<Expense> expenses;
  final ColorScheme colorScheme;

  const ExpenseInsights({
    super.key,
    required this.expenses,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = _calculateMetrics();

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color:
            colorScheme.brightness == Brightness.dark
                ? colorScheme.surface.withOpacity(0.8)
                : colorScheme.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                colorScheme.brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricColumn(
            'Daily Avg',
            metrics['dailyAvg']!,
            Icons.calendar_today_outlined,
            colorScheme.primary,
          ),
          _buildDivider(),
          _buildMetricColumn(
            'Top Category',
            metrics['topCategory']!,
            Icons.category_outlined,
            colorScheme.secondary,
          ),
          _buildDivider(),
          _buildMetricColumn(
            'Highest Expense',
            metrics['highestExpense']!,
            Icons.arrow_upward_outlined,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: colorScheme.onSurface.withOpacity(0.1),
    );
  }

  Map<String, String> _calculateMetrics() {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 0,
    );

    // Calculate daily average
    double dailyAvg = 0;
    if (expenses.isNotEmpty) {
      final totalAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);

      // Find unique days with expenses
      final uniqueDays =
          expenses
              .map((e) => '${e.date.year}-${e.date.month}-${e.date.day}')
              .toSet();

      if (uniqueDays.isNotEmpty) {
        dailyAvg = totalAmount / uniqueDays.length;
      }
    }

    // Find top category
    String topCategory = 'None';
    if (expenses.isNotEmpty) {
      final categoryMap = <String, double>{};
      for (var expense in expenses) {
        categoryMap[expense.category] =
            (categoryMap[expense.category] ?? 0) + expense.amount;
      }

      var maxAmount = 0.0;
      for (var entry in categoryMap.entries) {
        if (entry.value > maxAmount) {
          maxAmount = entry.value;
          topCategory = entry.key;
        }
      }
    }

    // Find highest expense
    double highestExpense = 0;
    if (expenses.isNotEmpty) {
      for (var expense in expenses) {
        if (expense.amount > highestExpense) {
          highestExpense = expense.amount;
        }
      }
    }

    return {
      'dailyAvg': currencyFormat.format(dailyAvg),
      'topCategory': topCategory,
      'highestExpense': currencyFormat.format(highestExpense),
    };
  }
}
