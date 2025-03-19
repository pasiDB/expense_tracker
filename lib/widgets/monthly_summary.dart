import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/widgets/category_spending_chart.dart';

class MonthlySummary extends StatefulWidget {
  final double totalAmount;
  final Map<String, double> categoryExpenses;
  final Map<int, double> dailyExpenses;
  final int daysInMonth;

  const MonthlySummary({
    super.key,
    required this.totalAmount,
    required this.categoryExpenses,
    required this.dailyExpenses,
    required this.daysInMonth,
  });

  @override
  State<MonthlySummary> createState() => _MonthlySummaryState();
}

class _MonthlySummaryState extends State<MonthlySummary>
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalExpenses(context),
          const SizedBox(height: 24.0),
          _buildCategoryPieChart(context),
          const SizedBox(height: 24.0),
          _buildDailyExpensesChart(context),
        ],
      ),
    );
  }

  Widget _buildTotalExpenses(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        children: [
          const Text(
            'Total Expenses',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(
            '\$${widget.totalAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_isReady) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.0),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Opacity(
              opacity: _animation.value,
              child: const Text(
                'Expenses by Category',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
        const SizedBox(height: 8.0),
        Container(
          height: 150,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child:
              widget.categoryExpenses.isEmpty
                  ? Center(
                    child: Text(
                      'No expense data available',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  )
                  : _buildPieChartWithLegend(),
        ),
      ],
    );
  }

  Widget _buildPieChartWithLegend() {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
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
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
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
                    sections: _buildPieSections(),
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
                    widget.categoryExpenses.entries.map((entry) {
                      final index = widget.categoryExpenses.keys
                          .toList()
                          .indexOf(entry.key);
                      final isSelected = index == _touchedIndex;

                      return Opacity(
                        opacity: _animation.value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(
                            20 * (1 - _animation.value.clamp(0.0, 1.0)),
                            0,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
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
                                                color: _getCategoryColor(
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
                                  '\$${entry.value.toStringAsFixed(0)}',
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
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final total = widget.categoryExpenses.values.fold(
      0.0,
      (sum, value) => sum + value,
    );

    return List.generate(widget.categoryExpenses.length, (i) {
      final category = widget.categoryExpenses.keys.elementAt(i);
      final value = widget.categoryExpenses.values.elementAt(i);
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

  Color _getCategoryColor(String category) {
    return _categoryColors[category] ?? Colors.grey;
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

  Widget _buildDailyExpensesChart(BuildContext context) {
    final spots = <FlSpot>[];

    for (int i = 1; i <= widget.daysInMonth; i++) {
      spots.add(FlSpot(i.toDouble(), widget.dailyExpenses[i] ?? 0));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Expenses',
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16.0),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      if (value % 5 == 0) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(value.toInt().toString()),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d), width: 1),
              ),
              minX: 1,
              maxX: widget.daysInMonth.toDouble(),
              minY: 0,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                  ),
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
