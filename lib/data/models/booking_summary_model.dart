import 'package:flutter/foundation.dart';
import 'project_model.dart';
import 'customer_model.dart';
import 'payment_model.dart';
import 'bank_details_model.dart';

@immutable
class BookingSummary {
  final Project? selectedProject;
  final Plot? selectedPlot;
  final Customer? selectedCustomer;
  final PaymentDetails? paymentDetails;
  final BankDetails? bankDetails;

  const BookingSummary({
    this.selectedProject,
    this.selectedPlot,
    this.selectedCustomer,
    this.paymentDetails,
    this.bankDetails,
  });

  BookingSummary copyWith({
    Project? selectedProject,
    Plot? selectedPlot,
    Customer? selectedCustomer,
    PaymentDetails? paymentDetails,
    BankDetails? bankDetails,
  }) {
    return BookingSummary(
      selectedProject: selectedProject ?? this.selectedProject,
      selectedPlot: selectedPlot ?? this.selectedPlot,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      bankDetails: bankDetails ?? this.bankDetails,
    );
  }

  @override
  String toString() {
    return 'BookingSummary(selectedProject: $selectedProject, selectedPlot: $selectedPlot, selectedCustomer: $selectedCustomer, paymentDetails: $paymentDetails, bankDetails: $bankDetails)';
  }
}
