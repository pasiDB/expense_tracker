import 'package:hive/hive.dart';
import 'dart:math';

part 'loan.g.dart';

@HiveType(typeId: 3)
class Loan extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final double interestRate;

  @HiveField(4)
  final DateTime startDate;

  @HiveField(5)
  final int durationMonths;

  @HiveField(6)
  final double monthlyPayment;

  @HiveField(7)
  final String lender;

  @HiveField(8)
  final bool isActive;

  @HiveField(9)
  final double remainingAmount;

  Loan({
    required this.id,
    required this.title,
    required this.amount,
    required this.interestRate,
    required this.startDate,
    required this.durationMonths,
    required this.monthlyPayment,
    required this.lender,
    this.isActive = true,
    required this.remainingAmount,
  });

  // Calculate monthly payment based on loan details
  static double calculateMonthlyPayment(
    double principal,
    double annualRate,
    int durationMonths,
  ) {
    // Convert annual rate to monthly rate and decimal form
    double monthlyRate = (annualRate / 100) / 12;

    // If interest rate is 0, simple division
    if (monthlyRate == 0) {
      return principal / durationMonths;
    }

    // Standard amortization formula
    return principal *
        (monthlyRate * pow((1 + monthlyRate), durationMonths)) /
        (pow((1 + monthlyRate), durationMonths) - 1);
  }

  // Calculate the remaining loan balance after a certain number of payments
  double calculateRemainingBalance(int paymentsMade) {
    if (paymentsMade >= durationMonths) return 0;

    double monthlyRate = (interestRate / 100) / 12;

    // If interest rate is 0, simple subtraction
    if (monthlyRate == 0) {
      return amount - (monthlyPayment * paymentsMade);
    }

    // Standard formula for remaining balance
    return amount *
        (pow((1 + monthlyRate), durationMonths) -
            pow((1 + monthlyRate), paymentsMade)) /
        (pow((1 + monthlyRate), durationMonths) - 1);
  }

  // Calculate the number of months passed since loan start
  int getMonthsPassed() {
    final now = DateTime.now();
    return (now.year - startDate.year) * 12 + now.month - startDate.month;
  }

  // Get progress percentage of loan repayment based on actual amount paid
  double getRepaymentProgress() {
    // Calculate based on actual payments made
    double amountPaid = amount - remainingAmount;
    return (amountPaid / amount).clamp(0.0, 1.0);
  }

  // Calculate recommended monthly payment based on income and duration
  static double recommendPayment(
    double loanAmount,
    double monthlyIncome,
    int preferredDurationMonths,
  ) {
    // Typically, loan payments shouldn't exceed 25-30% of monthly income
    double maxRecommendedPayment = monthlyIncome * 0.3;
    double simpleDivision = loanAmount / preferredDurationMonths;

    // If simple division is affordable, recommend it
    if (simpleDivision <= maxRecommendedPayment) {
      return simpleDivision;
    } else {
      // Otherwise, recommend the maximum affordable payment
      return maxRecommendedPayment;
    }
  }

  // Calculate duration based on payment amount
  static int calculateDuration(double loanAmount, double monthlyPayment) {
    return (loanAmount / monthlyPayment).ceil();
  }
}
