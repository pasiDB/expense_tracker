import 'package:flutter/material.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/widgets/category_spending_chart.dart';
import 'package:expense_tracker/widgets/expense_insights.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/database/database_service.dart';
import 'package:expense_tracker/models/loan.dart';

class SummaryScreen extends StatefulWidget {
  final List<Expense> expenses;
  final double totalExpenses;
  final double monthlyIncome;
  final VoidCallback onExpenseUpdated;
  final ScrollController? scrollController;

  const SummaryScreen({
    super.key,
    required this.expenses,
    required this.totalExpenses,
    required this.monthlyIncome,
    required this.onExpenseUpdated,
    this.scrollController,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen>
    with AutomaticKeepAliveClientMixin {
  List<Loan> _activeLoans = [];
  double _totalMonthlyLoanPayments = 0.0;
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  bool _initialLoadDone = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  @override
  void didUpdateWidget(SummaryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload loans when expenses are updated
    if (oldWidget.expenses != widget.expenses ||
        oldWidget.totalExpenses != widget.totalExpenses) {
      _loadLoans();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh data if this is the first load
    if (!_initialLoadDone) {
      _loadLoans();
      _initialLoadDone = true;
    }
  }

  Future<void> _loadLoans() async {
    // Don't set loading state if it's just a background refresh
    if (!_initialLoadDone) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final activeLoans = _databaseService.getActiveLoans();
      final totalPayments = _databaseService.getTotalMonthlyLoanPayments();

      setState(() {
        _activeLoans = activeLoans;
        _totalMonthlyLoanPayments = totalPayments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading loans: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always refresh loan data when building the widget
    // This ensures we have the latest loan information
    _loadLoans();

    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final balance = widget.monthlyIncome - widget.totalExpenses;
    final disposableIncome = balance - _totalMonthlyLoanPayments;

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending By Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CategorySpendingChart(expenses: widget.expenses),
          ),

          const SizedBox(height: 24),
          ExpenseInsights(expenses: widget.expenses, colorScheme: colorScheme),

          if (_activeLoans.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Loan Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Loans',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _activeLoans.length.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFinancialMetric(
                    'Monthly Loan Payments',
                    currencyFormat.format(_totalMonthlyLoanPayments),
                    colorScheme.onSecondaryContainer,
                    Icons.payments,
                  ),
                  const SizedBox(height: 8),
                  _buildFinancialMetric(
                    'Disposable Income After Loans',
                    currencyFormat.format(disposableIncome),
                    disposableIncome >= 0 ? Colors.green : Colors.red,
                    disposableIncome >= 0 ? Icons.thumb_up_alt : Icons.warning,
                  ),

                  if (_activeLoans.length > 0) ...[
                    const Divider(height: 24),
                    Text(
                      'Top ${_activeLoans.length > 2 ? "2" : _activeLoans.length} Active Loans',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(
                      _activeLoans.length > 2 ? 2 : _activeLoans.length,
                      (index) {
                        final loan = _activeLoans[index];
                        final progress = loan.getRepaymentProgress();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width - 80,
                                ),
                                child: Text(
                                  loan.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSecondaryContainer,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      currencyFormat.format(
                                        loan.monthlyPayment,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.secondary,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${(progress * 100).toStringAsFixed(0)}% paid',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: colorScheme
                                    .onSecondaryContainer
                                    .withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress < 0.3
                                      ? Colors.red
                                      : progress < 0.7
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialMetric(
    String label,
    String value,
    Color valueColor,
    IconData icon,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 3,
          child: Row(
            children: [
              Icon(icon, size: 14, color: valueColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Flexible(
          flex: 2,
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
              fontSize: 13,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
