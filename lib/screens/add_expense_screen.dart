import 'package:flutter/material.dart';
import 'package:expense_tracker/database/database_service.dart';
import 'package:expense_tracker/models/loan.dart';

class AddExpenseScreen extends StatefulWidget {
  final VoidCallback? onExpenseAdded;

  const AddExpenseScreen({super.key, this.onExpenseAdded});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  String? _selectedLoanId;
  List<Loan> _activeLoans = [];

  final List<String> _categories = [
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Utilities',
    'Health',
    'Education',
    'Loan Payment',
    'Others',
  ];

  final Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Entertainment': Icons.movie,
    'Shopping': Icons.shopping_bag,
    'Utilities': Icons.water_drop,
    'Health': Icons.favorite,
    'Education': Icons.school,
    'Loan Payment': Icons.account_balance,
    'Others': Icons.attach_money,
  };

  @override
  void initState() {
    super.initState();
    _loadActiveLoans();
  }

  Future<void> _loadActiveLoans() async {
    final databaseService = DatabaseService();
    final loans = databaseService.getActiveLoans();
    setState(() {
      _activeLoans = loans;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final databaseService = DatabaseService();
      final double amount = double.parse(_amountController.text);

      // Handle loan payment differently
      if (_selectedCategory == 'Loan Payment' && _selectedLoanId != null) {
        // Find the selected loan
        final selectedLoan = _activeLoans.firstWhere(
          (loan) => loan.id == _selectedLoanId,
          orElse: () => throw Exception('Selected loan not found'),
        );

        // Update remaining amount on the loan
        double newRemainingAmount = selectedLoan.remainingAmount - amount;
        if (newRemainingAmount < 0) newRemainingAmount = 0;
        databaseService.updateLoanRemainingAmount(
          selectedLoan.id,
          newRemainingAmount,
        );

        // Also save as a regular expense
        databaseService.addExpense(
          '${_titleController.text} (${selectedLoan.title})',
          amount,
          _selectedCategory,
        );
      } else {
        // Normal expense
        databaseService.addExpense(
          _titleController.text,
          amount,
          _selectedCategory,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 16),
              Text('Expense added successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(12),
        ),
      );

      // Call the callback function if provided - ensures proper refresh
      if (widget.onExpenseAdded != null) {
        widget.onExpenseAdded!();
      }

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: colorScheme.primary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Expense',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Expense Details',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          prefixIcon: Icon(
                            Icons.title,
                            color: colorScheme.primary,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: Icon(
                            Icons.attach_money,
                            color: colorScheme.primary,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24.0),
                      Text(
                        'Category',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Wrap(
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children:
                            _categories.map((category) {
                              final isSelected = _selectedCategory == category;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = category;

                                    // Reset selected loan when changing category
                                    if (category != 'Loan Payment') {
                                      _selectedLoanId = null;
                                    } else if (_activeLoans.isNotEmpty) {
                                      // Auto-select first loan if available
                                      _selectedLoanId = _activeLoans.first.id;
                                      _titleController.text =
                                          'Payment for ${_activeLoans.first.title}';
                                      _amountController.text =
                                          _activeLoans.first.monthlyPayment
                                              .toString();
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 12.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? colorScheme.primary
                                            : colorScheme.primary.withOpacity(
                                              0.1,
                                            ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? Colors.transparent
                                              : colorScheme.primary.withOpacity(
                                                0.5,
                                              ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _categoryIcons[category],
                                        size: 20,
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        category,
                                        style: TextStyle(
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : colorScheme.primary,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      // Show loan selection when Loan Payment is selected
                      if (_selectedCategory == 'Loan Payment') ...[
                        const SizedBox(height: 24.0),
                        Text(
                          'Select Loan',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        if (_activeLoans.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer.withOpacity(
                                0.3,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: colorScheme.error),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No active loans found. Please add a loan first.',
                                    style: TextStyle(color: colorScheme.error),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.5),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedLoanId,
                                isExpanded: true,
                                hint: const Text('Select a loan'),
                                items:
                                    _activeLoans.map((loan) {
                                      return DropdownMenuItem<String>(
                                        value: loan.id,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.account_balance,
                                              size: 18,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    loan.title,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    'Monthly payment: \$${loan.monthlyPayment.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          colorScheme
                                                              .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (String? loanId) {
                                  if (loanId != null) {
                                    final selectedLoan = _activeLoans
                                        .firstWhere(
                                          (loan) => loan.id == loanId,
                                        );
                                    setState(() {
                                      _selectedLoanId = loanId;
                                      _titleController.text =
                                          'Payment for ${selectedLoan.title}';
                                      _amountController.text =
                                          selectedLoan.monthlyPayment
                                              .toString();
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 40.0),
                      ElevatedButton(
                        onPressed: _saveExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          textStyle: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 12),
                            Text('Save Expense'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
