import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/database/database_service.dart';
import 'package:expense_tracker/models/loan.dart';
import 'package:expense_tracker/models/user_profile.dart';

class AddLoanScreen extends StatefulWidget {
  const AddLoanScreen({super.key});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _durationController = TextEditingController();
  final _monthlyPaymentController = TextEditingController();
  final _lenderController = TextEditingController();

  DateTime _startDate = DateTime.now();
  bool _isCalculating = false;
  bool _isRecommending = false;
  bool _isLoading = false;
  UserProfile? _userProfile;
  final DatabaseService _databaseService = DatabaseService();

  double _recommendedPayment = 0;
  int _recommendedDuration = 0;
  bool _showRecommendation = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _interestRateController.dispose();
    _durationController.dispose();
    _monthlyPaymentController.dispose();
    _lenderController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userProfile = await _databaseService.getUserProfile();
      setState(() {
        _userProfile = userProfile;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  void _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && pickedDate != _startDate) {
      setState(() {
        _startDate = pickedDate;
      });
    }
  }

  void _calculateMonthlyPayment() {
    if (_amountController.text.isEmpty ||
        _interestRateController.text.isEmpty ||
        _durationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in loan amount, interest rate, and duration',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    try {
      final loanAmount = double.parse(_amountController.text);
      final interestRate = double.parse(_interestRateController.text);
      final durationMonths = int.parse(_durationController.text);

      final monthlyPayment = Loan.calculateMonthlyPayment(
        loanAmount,
        interestRate,
        durationMonths,
      );

      setState(() {
        _monthlyPaymentController.text = monthlyPayment.toStringAsFixed(2);
        _isCalculating = false;
      });
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calculating payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _getRecommendedPayment() {
    if (_amountController.text.isEmpty || _userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter loan amount and ensure your profile is set up',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isRecommending = true;
    });

    try {
      final loanAmount = double.parse(_amountController.text);
      final monthlyIncome = _userProfile!.monthlyIncome;

      // For initial recommendation, use 36 months (3 years) as a standard duration
      final initialDuration = 36;

      final recommendedPayment = Loan.recommendPayment(
        loanAmount,
        monthlyIncome,
        initialDuration,
      );

      // Calculate how long it would take to pay off with this payment
      final recommendedDuration = Loan.calculateDuration(
        loanAmount,
        recommendedPayment,
      );

      setState(() {
        _recommendedPayment = recommendedPayment;
        _recommendedDuration = recommendedDuration;
        _showRecommendation = true;
        _isRecommending = false;
      });
    } catch (e) {
      setState(() {
        _isRecommending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting recommendation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _useRecommendation() {
    setState(() {
      _monthlyPaymentController.text = _recommendedPayment.toStringAsFixed(2);
      _durationController.text = _recommendedDuration.toString();
      _showRecommendation = false;
    });
  }

  Future<void> _saveLoan() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _databaseService.addLoan(
          title: _titleController.text,
          amount: double.parse(_amountController.text),
          interestRate: double.parse(_interestRateController.text),
          startDate: _startDate,
          durationMonths: int.parse(_durationController.text),
          monthlyPayment: double.parse(_monthlyPaymentController.text),
          lender: _lenderController.text,
        );

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Loan added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding loan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final dateFormat = DateFormat('MMMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register New Loan'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loan Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Loan Title',
                          hintText: 'e.g., Car Loan, Student Loan',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title for the loan';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lenderController,
                        decoration: const InputDecoration(
                          labelText: 'Lender',
                          hintText: 'e.g., Bank Name, Friend\'s Name',
                          prefixIcon: Icon(Icons.account_balance),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the lender\'s name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Loan Amount',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the loan amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _interestRateController,
                        decoration: const InputDecoration(
                          labelText: 'Interest Rate (%)',
                          prefixIcon: Icon(Icons.percent),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the interest rate';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Date',
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  dateFormat.format(_startDate),
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Repayment Plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration (months)',
                          prefixIcon: Icon(Icons.timelapse),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the loan duration';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _monthlyPaymentController,
                              decoration: const InputDecoration(
                                labelText: 'Monthly Payment',
                                prefixIcon: Icon(Icons.payments),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the monthly payment';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _calculateMonthlyPayment,
                            icon: Icon(
                              Icons.calculate,
                              color: colorScheme.primary,
                            ),
                            tooltip: 'Calculate monthly payment',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_userProfile != null &&
                          _userProfile!.monthlyIncome > 0)
                        Center(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isRecommending ? null : _getRecommendedPayment,
                            icon:
                                _isRecommending
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Icon(Icons.lightbulb_outline),
                            label: const Text('Get Payment Recommendation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.secondary,
                              foregroundColor: colorScheme.onSecondary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      if (_showRecommendation)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer.withOpacity(
                              0.3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.secondary.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb,
                                    color: colorScheme.secondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Payment Recommendation',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Based on your monthly income of ${currencyFormat.format(_userProfile!.monthlyIncome)}, we recommend:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onBackground,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildRecommendationItem(
                                    'Monthly Payment',
                                    currencyFormat.format(_recommendedPayment),
                                    context,
                                  ),
                                  _buildRecommendationItem(
                                    'Duration',
                                    '$_recommendedDuration months',
                                    context,
                                  ),
                                  _buildRecommendationItem(
                                    'Payment % of Income',
                                    '${((_recommendedPayment / _userProfile!.monthlyIncome) * 100).toStringAsFixed(1)}%',
                                    context,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: ElevatedButton(
                                  onPressed: _useRecommendation,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.secondary,
                                    foregroundColor: colorScheme.onSecondary,
                                  ),
                                  child: const Text('Use This Plan'),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveLoan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Add Loan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildRecommendationItem(
    String label,
    String value,
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onBackground.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}
