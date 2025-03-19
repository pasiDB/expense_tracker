import 'package:flutter/material.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class CategorySpendingChart extends StatefulWidget {
  final List<Expense> expenses;

  const CategorySpendingChart({super.key, required this.expenses});

  @override
  State<CategorySpendingChart> createState() => _CategorySpendingChartState();
}

class _CategorySpendingChartState extends State<CategorySpendingChart>
    with SingleTickerProviderStateMixin {
  int _touchedIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Animation<double> _popAnimation;
  bool _isReady = false;

  final Map<String, Color> _categoryColors = {
    'Food': Colors.orange,
    'Transport': Colors.blue,
    'Entertainment': Colors.purple,
    'Shopping': Colors.pink,
    'Utilities': Colors.lightBlue,
    'Health': Colors.red,
    'Education': Colors.brown,
    'Others': Colors.green,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    _popAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    // Delay initial animation slightly to prevent render errors
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isReady = true;
        });
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Map<String, double> categoryData = _calculateCategoryData();
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    if (!_isReady) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.0),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final safeOpacity = _animation.value.clamp(0.0, 1.0);
            return Opacity(
              opacity: safeOpacity,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  top: 4.0,
                  bottom: 4.0,
                ),
                child: Text(
                  'Spending by Category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onBackground,
                  ),
                ),
              ),
            );
          },
        ),
        Expanded(
          child: Row(
            children: [
              if (categoryData.isNotEmpty && widget.expenses.isNotEmpty) ...[
                Expanded(
                  flex: 5,
                  child: AnimatedBuilder(
                    animation: _popAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.80 + (0.15 * _popAnimation.value),
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (
                                FlTouchEvent event,
                                pieTouchResponse,
                              ) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex =
                                      pieTouchResponse
                                          .touchedSection!
                                          .touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 20 * _animation.value,
                            sections: _showingSections(categoryData),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            categoryData.entries.map((entry) {
                              final index = categoryData.keys.toList().indexOf(
                                entry.key,
                              );
                              final isSelected = index == _touchedIndex;

                              return Opacity(
                                opacity: _animation.value.clamp(0.0, 1.0),
                                child: Transform.translate(
                                  offset: Offset(
                                    20 * (1 - _animation.value.clamp(0.0, 1.0)),
                                    0,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2.0,
                                    ),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          width: isSelected ? 12 : 8,
                                          height: isSelected ? 12 : 8,
                                          decoration: BoxDecoration(
                                            color: _getCategoryColor(entry.key),
                                            shape: BoxShape.circle,
                                            border:
                                                isSelected
                                                    ? Border.all(
                                                      color: Colors.white,
                                                      width: 1,
                                                    )
                                                    : null,
                                            boxShadow:
                                                isSelected
                                                    ? [
                                                      BoxShadow(
                                                        color:
                                                            _getCategoryColor(
                                                              entry.key,
                                                            ).withOpacity(0.2),
                                                        blurRadius: 2,
                                                        spreadRadius: 1,
                                                      ),
                                                    ]
                                                    : null,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          entry.key,
                                          style: TextStyle(
                                            fontSize: isSelected ? 12 : 10,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                            color: colorScheme.onBackground,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          currencyFormat.format(entry.value),
                                          style: TextStyle(
                                            fontSize: isSelected ? 12 : 10,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                            color: colorScheme.onBackground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      );
                    },
                  ),
                ),
              ] else
                Expanded(
                  child: Center(
                    child: Text(
                      'No expense data available',
                      style: TextStyle(
                        color: colorScheme.onBackground.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, double> _calculateCategoryData() {
    final categoryMap = <String, double>{};

    for (var expense in widget.expenses) {
      categoryMap[expense.category] =
          (categoryMap[expense.category] ?? 0) + expense.amount;
    }

    return categoryMap;
  }

  Color _getCategoryColor(String category) {
    return _categoryColors[category] ?? Colors.grey;
  }

  List<PieChartSectionData> _showingSections(Map<String, double> categoryData) {
    final total = categoryData.values.fold(0.0, (sum, value) => sum + value);

    return List.generate(categoryData.length, (i) {
      final category = categoryData.keys.elementAt(i);
      final value = categoryData.values.elementAt(i);
      final percentage = total > 0 ? (value / total) * 100 : 0;
      final isTouched = i == _touchedIndex;
      final radius =
          isTouched ? 55.0 * _animation.value : 45.0 * _animation.value;
      final fontSize = isTouched ? 10.0 : 8.0;
      final badgeSize = isTouched ? 22.0 : 18.0;

      return PieChartSectionData(
        color: _getCategoryColor(category),
        value: value,
        title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
        badgeWidget:
            isTouched
                ? AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getCategoryColor(category).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(category),
                      color: _getCategoryColor(category),
                      size: badgeSize * 0.6,
                    ),
                  ),
                )
                : null,
        badgePositionPercentageOffset: 1.1,
      );
    });
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Entertainment':
        return Icons.movie;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Utilities':
        return Icons.water_drop;
      case 'Health':
        return Icons.favorite;
      case 'Education':
        return Icons.school;
      default:
        return Icons.attach_money;
    }
  }
}
