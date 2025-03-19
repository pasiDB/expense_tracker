import 'package:flutter/material.dart';
import 'package:expense_tracker/models/expense.dart';

class DailySummary extends StatelessWidget {
  final List<Expense> expenses;
  final double totalAmount;

  const DailySummary({
    super.key,
    required this.expenses,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate category percentages
    final Map<String, double> categoryTotals = {};
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    for (var expense in expenses) {
      if (categoryTotals.containsKey(expense.category)) {
        categoryTotals[expense.category] =
            categoryTotals[expense.category]! + expense.amount;
      } else {
        categoryTotals[expense.category] = expense.amount;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (expenses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'No expenses today',
                    style: TextStyle(color: colorScheme.tertiary),
                  ),
                ),
              )
            else ...[
              const SizedBox(height: 16.0),
              Text(
                'Expenses by Category:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
              const SizedBox(height: 8.0),
              ...categoryTotals.entries.map((entry) {
                final percentage =
                    totalAmount > 0
                        ? (entry.value / totalAmount * 100).toStringAsFixed(1)
                        : '0.0';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _getCategoryIcon(entry.key),
                              const SizedBox(width: 8),
                              Text(
                                entry.key,
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Text(
                            '\$${entry.value.toStringAsFixed(2)} ($percentage%)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: totalAmount > 0 ? entry.value / totalAmount : 0,
                        backgroundColor: _getCategoryColor(
                          entry.key,
                        ).withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCategoryColor(entry.key),
                        ),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData iconData;
    Color color = _getCategoryColor(category);

    switch (category) {
      case 'Food':
        iconData = Icons.restaurant;
        break;
      case 'Transport':
        iconData = Icons.directions_car;
        break;
      case 'Entertainment':
        iconData = Icons.movie;
        break;
      case 'Shopping':
        iconData = Icons.shopping_bag;
        break;
      case 'Utilities':
        iconData = Icons.water_drop;
        break;
      case 'Health':
        iconData = Icons.favorite;
        break;
      case 'Education':
        iconData = Icons.school;
        break;
      default:
        iconData = Icons.attach_money;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: color, size: 16),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Transport':
        return Colors.blue;
      case 'Entertainment':
        return Colors.purple;
      case 'Shopping':
        return Colors.pink;
      case 'Utilities':
        return Colors.lightBlue;
      case 'Health':
        return Colors.red;
      case 'Education':
        return Colors.brown;
      default:
        return Colors.green;
    }
  }
}
