import 'package:flutter/foundation.dart';
import 'project_model.dart';
import 'customer_model.dart';
import 'payment_model.dart';
import 'bank_details_model.dart';
import 'hold_details_model.dart';

@immutable
class BookingSummary {
  final Project? selectedProject;
  final Plot? selectedPlot;
  final Customer? selectedCustomer;
  final HoldDetails? holdDetails;
  final PaymentDetails? paymentDetails;
  final BankDetails? bankDetails;

  const BookingSummary({
    this.selectedProject,
    this.selectedPlot,
    this.selectedCustomer,
    this.holdDetails,
    this.paymentDetails,
    this.bankDetails,
  });

  BookingSummary copyWith({
    Project? selectedProject,
    Plot? selectedPlot,
    Customer? selectedCustomer,
    HoldDetails? holdDetails,
    PaymentDetails? paymentDetails,
    BankDetails? bankDetails,
  }) {
    return (holdDetails != null) ? BookingSummary(
      selectedProject: selectedProject ?? this.selectedProject,
      selectedPlot: selectedPlot ?? this.selectedPlot,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      holdDetails: holdDetails ?? this.holdDetails,
      bankDetails: bankDetails ?? this.bankDetails,
    ) : BookingSummary(
      selectedProject: selectedProject ?? this.selectedProject,
      selectedPlot: selectedPlot ?? this.selectedPlot,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      bankDetails: bankDetails ?? this.bankDetails,
    );
  }

  @override
  String toString() {
    return 'BookingSummary(selectedProject: $selectedProject, selectedPlot: $selectedPlot, selectedCustomer: $selectedCustomer, holdDetails: $holdDetails, paymentDetails: $paymentDetails, bankDetails: $bankDetails)';
  }
}
