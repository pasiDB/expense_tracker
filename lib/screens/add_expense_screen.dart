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
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = [
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Utilities',
    'Health',
    'Education',
    'Housing',
    'Personal Care',
    'Travel',
    'Electronics',
    'Clothing',
    'Gifts',
    'Investments',
    'Subscriptions',
    'Dining Out',
    'Groceries',
    'Insurance',
    'Childcare',
    'Taxes',
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
    'Housing': Icons.home,
    'Personal Care': Icons.spa,
    'Travel': Icons.flight,
    'Electronics': Icons.devices,
    'Clothing': Icons.checkroom,
    'Gifts': Icons.card_giftcard,
    'Investments': Icons.trending_up,
    'Subscriptions': Icons.subscriptions,
    'Dining Out': Icons.dinner_dining,
    'Groceries': Icons.shopping_cart,
    'Insurance': Icons.security,
    'Childcare': Icons.child_care,
    'Taxes': Icons.receipt_long,
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
          date: _selectedDate,
        );
      } else {
        // Normal expense
        databaseService.addExpense(
          _titleController.text,
          amount,
          _selectedCategory,
          date: _selectedDate,
        );
      }

      // Show success message
      if (_selectedCategory == 'Loan Payment' && _selectedLoanId != null) {
        final selectedLoan = _activeLoans.firstWhere(
          (loan) => loan.id == _selectedLoanId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment of \$${amount.toStringAsFixed(2)} applied to ${selectedLoan.title}. Remaining: \$${selectedLoan.remainingAmount - amount > 0 ? (selectedLoan.remainingAmount - amount).toStringAsFixed(2) : "0.00"}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
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
      }

      // Call the callback function if provided - ensures proper refresh
      if (widget.onExpenseAdded != null) {
        widget.onExpenseAdded!();
      }

      Navigator.pop(context, true);
    }
  }

  // Date selection method
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
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
                      const SizedBox(height: 20.0),
                      // Date picker field
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(
                              Icons.calendar_today,
                              color: colorScheme.primary,
                            ),
                            suffixIcon: Icon(
                              Icons.arrow_drop_down,
                              color: colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              _selectedDate.day == DateTime.now().day &&
                                      _selectedDate.month ==
                                          DateTime.now().month &&
                                      _selectedDate.year == DateTime.now().year
                                  ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Today',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  )
                                  : SizedBox(),
                            ],
                          ),
                        ),
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
                      Container(
                        height: 250, // Increased height for the grid
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    2, // Reduced from 3 to 2 columns
                                childAspectRatio:
                                    3.0, // More space for each item
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 8.0,
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _categoryIcons[category],
                                      size: 16,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : colorScheme.primary,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
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
