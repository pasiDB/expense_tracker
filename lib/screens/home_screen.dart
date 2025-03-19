import 'package:flutter/material.dart' hide RefreshIndicator;
import 'package:flutter/material.dart' as material show RefreshIndicator;
import 'package:expense_tracker/screens/daily_expenses_screen.dart';
import 'package:expense_tracker/screens/monthly_expenses_screen.dart';
import 'package:expense_tracker/screens/summary_screen.dart';
import 'package:expense_tracker/screens/add_expense_screen.dart';
import 'package:expense_tracker/screens/loan_management_screen.dart';
import 'package:expense_tracker/widgets/dashboard_header.dart';
import 'package:expense_tracker/widgets/expense_insights.dart';
import 'package:expense_tracker/widgets/category_spending_chart.dart';
import 'package:expense_tracker/database/database_service.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/user_profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedTabIndex = 0;
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _isHeaderExpanded = false;
  List<Expense> _expenses = [];
  UserProfile? _userProfile;
  bool _isLoading = true;
  double _totalExpenses = 0;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _summaryScrollController = ScrollController();
  final ScrollController _dailyScrollController = ScrollController();
  bool _showFab = true;
  double _monthlyIncome = 0.0;
  double _lastScrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );

    // Add scroll listeners to hide/show FAB
    _setupScrollListeners();

    _loadData();
    _animationController.forward();
    _fabAnimationController.forward(); // Start with FAB visible
  }

  void _setupScrollListeners() {
    // For summary screen
    _summaryScrollController.addListener(() {
      _handleScroll(_summaryScrollController);
    });

    // For daily screen
    _dailyScrollController.addListener(() {
      _handleScroll(_dailyScrollController);
    });
  }

  void _handleScroll(ScrollController controller) {
    // Only update if we're on overview or daily tabs
    if (_selectedTabIndex > 1) return;

    // Simple approach - compare current position with last position
    final currentPosition = controller.position.pixels;

    // Scrolling down (positive delta)
    if (currentPosition > _lastScrollPosition) {
      if (_showFab) {
        setState(() {
          _showFab = false;
        });
        _fabAnimationController.reverse();
      }
    }
    // Scrolling up (negative delta)
    else if (currentPosition < _lastScrollPosition) {
      if (!_showFab) {
        setState(() {
          _showFab = true;
        });
        _fabAnimationController.forward();
      }
    }

    // Update last position
    _lastScrollPosition = currentPosition;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _fabAnimationController.dispose();
    _scrollController.dispose();
    _summaryScrollController.dispose();
    _dailyScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animate FAB when tab changes
    if (_selectedTabIndex <= 1) {
      if (_showFab) {
        _fabAnimationController.forward();
      }
    } else {
      _fabAnimationController.reverse();
    }
  }

  Future<void> _loadData() async {
    // Only show loading indicator if this is the initial load
    bool isInitialLoad = _expenses.isEmpty && _userProfile == null;

    if (isInitialLoad) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Load everything in parallel for better performance
      await Future.wait([_loadUserProfile(), _loadExpenses()]);

      setState(() {
        _isLoading = false;
      });

      // Force refresh of the current tab
      if (_pageController.hasClients) {
        // This will trigger didChangeDependencies in child screens
        setState(() {});
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error refreshing data: $e')));
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final dbService = DatabaseService();
      final userProfile = await dbService.getUserProfile();

      setState(() {
        _userProfile = userProfile;
        _monthlyIncome = userProfile.monthlyIncome;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user profile: $e')),
        );
      }
    }
  }

  Future<void> _loadExpenses() async {
    try {
      final dbService = DatabaseService();
      final expenses = await dbService.getExpenses();

      double total = 0;
      for (var expense in expenses) {
        total += expense.amount;
      }

      setState(() {
        _expenses = expenses;
        _totalExpenses = total;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading expenses: $e')));
      }
    }
  }

  void _toggleHeaderExpand() {
    setState(() {
      _isHeaderExpanded = !_isHeaderExpanded;
    });

    // Scroll to top when expanding for better UX
    if (_isHeaderExpanded) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: DashboardHeader(
                      onExpand: _toggleHeaderExpand,
                      isExpanded: _isHeaderExpanded,
                      totalExpenses: _totalExpenses,
                      colorScheme: colorScheme,
                      userProfile: _userProfile,
                      onProfileUpdated: _loadData,
                      expenses: _expenses,
                    ),
                  ),
                );
              },
            ),
            _buildTabHeaders(),
            Expanded(
              child:
                  _isLoading && (_expenses.isEmpty && _userProfile == null)
                      ? const Center(child: CircularProgressIndicator())
                      : PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _selectedTabIndex = index;
                          });

                          // Animate FAB when tab changes
                          if (index <= 1) {
                            _fabAnimationController.forward();
                          } else {
                            _fabAnimationController.reverse();
                          }
                        },
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // Summary screen
                          material.RefreshIndicator(
                            onRefresh: _loadData,
                            child: SummaryScreen(
                              expenses: _expenses,
                              totalExpenses: _totalExpenses,
                              monthlyIncome: _monthlyIncome,
                              onExpenseUpdated: _loadData,
                              scrollController: _summaryScrollController,
                            ),
                          ),

                          // Daily expenses view with insights
                          _buildDailyView(),

                          // Monthly expenses view with chart
                          _buildMonthlyView(),

                          // Loan management view
                          _buildLoanView(),
                        ],
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          // Always return the animated container, let the animation controller handle visibility
          return Opacity(
            opacity: _fabAnimation.value,
            child: Transform.scale(
              scale: _fabAnimation.value,
              child: FloatingActionButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AddExpenseScreen(
                            onExpenseAdded: () {
                              // Load data immediately when expense is added
                              _loadData();
                            },
                          ),
                    ),
                  );
                },
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTabHeaders() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  // Summary Tab
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color:
                              _selectedTabIndex == 0
                                  ? colorScheme.primaryContainer
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.dashboard,
                                size: 16,
                                color:
                                    _selectedTabIndex == 0
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Overview',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _selectedTabIndex == 0
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Daily Tab
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color:
                              _selectedTabIndex == 1
                                  ? colorScheme.primaryContainer
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.today,
                                size: 16,
                                color:
                                    _selectedTabIndex == 1
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Daily',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _selectedTabIndex == 1
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Monthly Tab
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          2,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color:
                              _selectedTabIndex == 2
                                  ? colorScheme.primaryContainer
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: 16,
                                color:
                                    _selectedTabIndex == 2
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Monthly',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _selectedTabIndex == 2
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Loans Tab
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          3,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color:
                              _selectedTabIndex == 3
                                  ? colorScheme.primaryContainer
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_balance,
                                size: 16,
                                color:
                                    _selectedTabIndex == 3
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Loans',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _selectedTabIndex == 3
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyView() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - _fadeAnimation.value)),
            child: material.RefreshIndicator(
              onRefresh: _loadData,
              child: DailyExpensesScreen(
                onExpenseUpdated: _loadData,
                scrollController: _dailyScrollController,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlyView() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - _fadeAnimation.value)),
            child: material.RefreshIndicator(
              onRefresh: _loadData,
              child: MonthlyExpensesScreen(onExpenseUpdated: _loadData),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoanView() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - _fadeAnimation.value)),
            child: LoanManagementScreen(onLoanUpdated: _loadData),
          ),
        );
      },
    );
  }
}
