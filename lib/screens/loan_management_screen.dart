import 'package:flutter/material.dart';
import 'package:expense_tracker/models/loan.dart';
import 'package:expense_tracker/database/database_service.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/screens/add_loan_screen.dart';

class LoanManagementScreen extends StatefulWidget {
  final VoidCallback? onLoanUpdated;

  const LoanManagementScreen({super.key, this.onLoanUpdated});

  @override
  State<LoanManagementScreen> createState() => _LoanManagementScreenState();
}

class _LoanManagementScreenState extends State<LoanManagementScreen>
    with AutomaticKeepAliveClientMixin {
  late final DatabaseService _databaseService;
  List<Loan> _loans = [];
  bool _isLoading = true;
  bool _initialLoadDone = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _loadLoans();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh data if this is the first load or when returning to this screen
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
      final loans = _databaseService.getAllLoans();
      setState(() {
        _loans = loans;
        _isLoading = false;
      });

      // Notify parent widget if provided
      if (widget.onLoanUpdated != null) {
        widget.onLoanUpdated!();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading loans: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addNewLoan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddLoanScreen()),
    );

    if (result == true) {
      _loadLoans();
    }
  }

  void _updateLoanStatus(Loan loan) async {
    final monthsPassed = loan.getMonthsPassed();
    final remainingBalance = loan.calculateRemainingBalance(monthsPassed);

    try {
      await _databaseService.updateLoanRemainingAmount(
        loan.id,
        remainingBalance,
      );
      _loadLoans();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loan status updated based on schedule'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating loan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateLoanRemainingAmount(String id, double newAmount) async {
    try {
      await _databaseService.updateLoanRemainingAmount(id, newAmount);
      _loadLoans();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Remaining loan amount updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating loan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteLoan(String id) async {
    try {
      await _databaseService.deleteLoan(id);
      _loadLoans();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loan deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting loan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Refresh loans data when building the widget
    // This ensures we always have the latest loan information
    _loadLoans();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Management'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _loans.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 80,
                      color: colorScheme.primary.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No loans yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: colorScheme.onBackground.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first loan to track payments',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onBackground.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _addNewLoan,
                      icon: const Icon(Icons.add),
                      label: const Text('Register New Loan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Swipe left to delete a loan or right to refresh its status',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onBackground.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: _loans.length,
                      itemBuilder: (context, index) {
                        final loan = _loans[index];
                        final monthsPassed = loan.getMonthsPassed();
                        final remainingBalance = loan.calculateRemainingBalance(
                          monthsPassed,
                        );
                        final progress = loan.getRepaymentProgress();
                        final isCompleted = remainingBalance <= 0;

                        // Calculate actual amount paid
                        final amountPaid = loan.amount - loan.remainingAmount;
                        final paymentPercentage =
                            (amountPaid / loan.amount * 100).toStringAsFixed(1);

                        return Dismissible(
                          key: Key(loan.id),
                          background: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          secondaryBackground: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              // Delete
                              return await showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Delete Loan'),
                                      content: Text(
                                        'Are you sure you want to delete "${loan.title}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                              );
                            } else {
                              // Update status
                              _updateLoanStatus(loan);
                              return false;
                            }
                          },
                          onDismissed: (direction) {
                            if (direction == DismissDirection.startToEnd) {
                              _deleteLoan(loan.id);
                            }
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              loan.title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'From ${loan.lender} • ${loan.interestRate}% interest',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isCompleted
                                                  ? Colors.green.withOpacity(
                                                    0.1,
                                                  )
                                                  : colorScheme.primary
                                                      .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          isCompleted ? 'Paid Off' : 'Active',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                isCompleted
                                                    ? Colors.green
                                                    : colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoColumn(
                                        'Loan Amount',
                                        currencyFormat.format(loan.amount),
                                        context,
                                      ),
                                      _buildInfoColumn(
                                        'Monthly Payment',
                                        currencyFormat.format(
                                          loan.monthlyPayment,
                                        ),
                                        context,
                                      ),
                                      _buildInfoColumn(
                                        'Remaining',
                                        currencyFormat.format(
                                          remainingBalance > 0
                                              ? remainingBalance
                                              : 0,
                                        ),
                                        context,
                                        valueColor:
                                            remainingBalance > 0
                                                ? null
                                                : Colors.green,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Repayment Progress',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                          Text(
                                            '${paymentPercentage}% paid',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: colorScheme.primary
                                              .withOpacity(0.1),
                                          color:
                                              progress < 0.3
                                                  ? Colors.red
                                                  : progress < 0.7
                                                  ? Colors.orange
                                                  : Colors.green,
                                          minHeight: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      floatingActionButton:
          _loans.isEmpty
              ? null
              : FloatingActionButton.extended(
                onPressed: _addNewLoan,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                tooltip: 'Register New Loan',
                icon: const Icon(Icons.add),
                label: const Text('Add Loan'),
              ),
    );
  }

  Widget _buildInfoColumn(
    String label,
    String value,
    BuildContext context, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
