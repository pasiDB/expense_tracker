import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/models/user_profile.dart';
import 'package:expense_tracker/screens/profile_screen.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/database/database_service.dart';
import 'package:expense_tracker/models/loan.dart';

class DashboardHeader extends StatefulWidget {
  final VoidCallback onExpand;
  final bool isExpanded;
  final double totalExpenses;
  final ColorScheme colorScheme;
  final UserProfile? userProfile;
  final VoidCallback? onProfileUpdated;
  final List<Expense>? expenses;

  const DashboardHeader({
    super.key,
    required this.onExpand,
    required this.isExpanded,
    required this.totalExpenses,
    required this.colorScheme,
    this.userProfile,
    this.onProfileUpdated,
    this.expenses,
  });

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _flowAnimation;
  bool _isAnimating = false;
  List<Loan> _activeLoans = [];
  double _totalMonthlyLoanPayments = 0.0;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _flowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Initialize animation controller based on current expanded state
    if (widget.isExpanded) {
      _animationController.value = 1.0;
    }

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
        });
        widget.onExpand();
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          _isAnimating = false;
        });
        widget.onExpand();
      }
    });

    _loadLoans();
  }

  @override
  void didUpdateWidget(DashboardHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update animation controller if isExpanded changes externally
    if (oldWidget.isExpanded != widget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.value = 1.0;
      } else {
        _animationController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _triggerAnimation() {
    setState(() {
      _isAnimating = true;
    });
    if (widget.isExpanded) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  Future<void> _loadLoans() async {
    try {
      final activeLoans = _databaseService.getActiveLoans();
      final totalPayments = _databaseService.getTotalMonthlyLoanPayments();

      setState(() {
        _activeLoans = activeLoans;
        _totalMonthlyLoanPayments = totalPayments;
      });
    } catch (e) {
      print('Error loading loans: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);
    final userName = widget.userProfile?.name ?? 'User';
    final monthlyIncome = widget.userProfile?.monthlyIncome ?? 0.0;
    final showBalance = monthlyIncome > 0;
    final balance = monthlyIncome - widget.totalExpenses;

    // Calculate disposable income after loan payments
    final disposableIncome = balance - _totalMonthlyLoanPayments;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Dashboard',
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                  if (result == true && widget.onProfileUpdated != null) {
                    widget.onProfileUpdated!();
                  }
                },
                child: _buildProfileAvatar(userName),
              ),
            ],
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: _triggerAnimation,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.colorScheme.primary,
                        widget.colorScheme.primary.withBlue(
                          widget.colorScheme.primary.blue + 40,
                        ),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: widget.colorScheme.primary.withOpacity(0.3),
                        offset: const Offset(0, 6),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Spending',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormat.format(widget.totalExpenses),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  _isAnimating
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Transform.rotate(
                              angle: _flowAnimation.value * 3.14159,
                              child: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniMetric(
                            icon: Icons.calendar_today,
                            label: 'This Month',
                            value: currencyFormat.format(widget.totalExpenses),
                          ),
                          _verticalDivider(),
                          _buildMiniMetric(
                            icon: Icons.account_balance_wallet,
                            label: 'Income',
                            value: currencyFormat.format(monthlyIncome),
                          ),
                          _verticalDivider(),
                          _buildMiniMetric(
                            icon: Icons.wallet,
                            label: 'Balance',
                            value:
                                showBalance
                                    ? currencyFormat.format(balance)
                                    : '—',
                          ),
                        ],
                      ),

                      // Expansion animation content
                      SizeTransition(
                        sizeFactor: _flowAnimation,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.5,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  const Divider(
                                    color: Colors.white24,
                                    height: 1,
                                  ),
                                  const SizedBox(height: 16),

                                  // Budget Progress
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Budget Progress',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Linear progress indicator with animation
                                      Stack(
                                        children: [
                                          Container(
                                            height: 8,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 800,
                                            ),
                                            height: 8,
                                            width:
                                                showBalance
                                                    ? (widget.totalExpenses /
                                                                monthlyIncome)
                                                            .clamp(0.0, 1.0) *
                                                        (MediaQuery.of(
                                                              context,
                                                            ).size.width -
                                                            64)
                                                    : 0,
                                            decoration: BoxDecoration(
                                              color:
                                                  showBalance &&
                                                          widget.totalExpenses /
                                                                  monthlyIncome >
                                                              0.8
                                                      ? Colors.redAccent
                                                      : Colors.greenAccent,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Progress percentage
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            showBalance
                                                ? '${((widget.totalExpenses / monthlyIncome) * 100).toStringAsFixed(1)}% of budget used'
                                                : 'Set your monthly income in profile',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.8,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (showBalance)
                                            Text(
                                              '${currencyFormat.format(widget.totalExpenses)} / ${currencyFormat.format(monthlyIncome)}',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.8,
                                                ),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // Savings Target Progress
                                  if (widget.userProfile != null &&
                                      widget.userProfile!.savingsTarget >
                                          0) ...[
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Savings Target Progress',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Calculate savings amount
                                        Builder(
                                          builder: (context) {
                                            final savingsTarget =
                                                widget
                                                    .userProfile!
                                                    .savingsTarget;
                                            final currentSavings =
                                                showBalance ? balance : 0.0;
                                            final savingsProgress =
                                                (currentSavings / savingsTarget)
                                                    .clamp(0.0, 1.0);
                                            final isOnTrack =
                                                currentSavings >= 0;

                                            return Column(
                                              children: [
                                                // Linear progress indicator
                                                Stack(
                                                  children: [
                                                    Container(
                                                      height: 8,
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withOpacity(0.2),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                    ),
                                                    AnimatedContainer(
                                                      duration: const Duration(
                                                        milliseconds: 800,
                                                      ),
                                                      height: 8,
                                                      width:
                                                          savingsProgress *
                                                          (MediaQuery.of(
                                                                context,
                                                              ).size.width -
                                                              64),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            isOnTrack
                                                                ? Colors
                                                                    .greenAccent
                                                                : Colors
                                                                    .redAccent,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),

                                                // Progress percentage
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      isOnTrack
                                                          ? '${(savingsProgress * 100).toStringAsFixed(1)}% of target saved'
                                                          : 'Not on track to meet savings target',
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withOpacity(0.8),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${currencyFormat.format(currentSavings)} / ${currencyFormat.format(savingsTarget)}',
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withOpacity(0.8),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  // Loan Payments Section
                                  if (_activeLoans.isNotEmpty) ...[
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Loan Payments',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Active Loans: ${_activeLoans.length}',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.8,
                                                ),
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              'Monthly Payments: ${currencyFormat.format(_totalMonthlyLoanPayments)}',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.8,
                                                ),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 12),

                                        // Disposable income after loan payments
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white10,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Disposable Income After Loans',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.7),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    currencyFormat.format(
                                                      disposableIncome,
                                                    ),
                                                    style: TextStyle(
                                                      color:
                                                          disposableIncome >= 0
                                                              ? Colors
                                                                  .greenAccent
                                                              : Colors
                                                                  .redAccent,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Icon(
                                                disposableIncome >= 0
                                                    ? Icons.thumb_up_alt
                                                    : Icons.warning,
                                                color:
                                                    disposableIncome >= 0
                                                        ? Colors.greenAccent
                                                        : Colors.redAccent,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  // Recent activity
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Recent Activity',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Recent expenses
                                      if (widget.expenses != null &&
                                          widget.expenses!.isNotEmpty)
                                        SizedBox(
                                          height: 60,
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            scrollDirection: Axis.horizontal,
                                            itemCount:
                                                widget.expenses!.length > 3
                                                    ? 3
                                                    : widget.expenses!.length,
                                            itemBuilder: (context, index) {
                                              final expense =
                                                  widget.expenses![index];
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                  right: 10,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                width: 130,
                                                decoration: BoxDecoration(
                                                  color: Colors.white10,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      expense.title,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 12,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          expense.category,
                                                          style: TextStyle(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                  0.7,
                                                                ),
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                        Text(
                                                          currencyFormat.format(
                                                            expense.amount,
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 11,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      else
                                        Container(
                                          height: 60,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.white10,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            'No recent expenses',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String userName) {
    String initials = '';
    if (userName.isNotEmpty) {
      final nameParts = userName.split(' ');
      if (nameParts.length > 1) {
        initials = nameParts[0][0] + nameParts[1][0];
      } else {
        initials = userName[0];
      }
      initials = initials.toUpperCase();
    } else {
      initials = 'U';
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.colorScheme.primaryContainer,
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: widget.colorScheme.secondaryContainer,
            child: Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.colorScheme.primary,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: widget.colorScheme.secondary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }
}
