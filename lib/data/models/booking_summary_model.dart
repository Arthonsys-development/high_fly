import 'package:flutter/foundation.dart';
import 'project_model.dart';
import 'customer_model.dart';
import 'payment_model.dart';
import 'bank_details_model.dart';
import 'hold_details_model.dart';

@immutable
class BookingSummary {
  final Project? selectedProject;
  final List<Plot>? selectedPlots;
  final Customer? selectedCustomer;
  final HoldDetails? holdDetails;
  final PaymentDetails? paymentDetails;
  final BankDetails? bankDetails;
  final List<String>? documents;

  const BookingSummary({
    this.selectedProject,
    this.selectedPlots,
    this.selectedCustomer,
    this.holdDetails,
    this.paymentDetails,
    this.bankDetails,
    this.documents,
  });

  /// Convenience getter for the first (or only) selected plot.
  Plot? get selectedPlot =>
      selectedPlots != null && selectedPlots!.isNotEmpty ? selectedPlots!.first : null;

  bool get hasMultiplePlots => (selectedPlots?.length ?? 0) > 1;

  BookingSummary copyWith({
    Project? selectedProject,
    List<Plot>? selectedPlots,
    Customer? selectedCustomer,
    HoldDetails? holdDetails,
    PaymentDetails? paymentDetails,
    BankDetails? bankDetails,
    List<String>? documents,
  }) {
    return (holdDetails != null)
        ? BookingSummary(
            selectedProject: selectedProject ?? this.selectedProject,
            selectedPlots: selectedPlots ?? this.selectedPlots,
            selectedCustomer: selectedCustomer ?? this.selectedCustomer,
            holdDetails: holdDetails,
            bankDetails: bankDetails ?? this.bankDetails,
            documents: documents ?? this.documents,
          )
        : BookingSummary(
            selectedProject: selectedProject ?? this.selectedProject,
            selectedPlots: selectedPlots ?? this.selectedPlots,
            selectedCustomer: selectedCustomer ?? this.selectedCustomer,
            paymentDetails: paymentDetails ?? this.paymentDetails,
            bankDetails: bankDetails ?? this.bankDetails,
            documents: documents ?? this.documents,
          );
  }

  @override
  String toString() {
    return 'BookingSummary(selectedProject: $selectedProject, selectedPlots: $selectedPlots, selectedCustomer: $selectedCustomer, holdDetails: $holdDetails, paymentDetails: $paymentDetails, bankDetails: $bankDetails, documents: $documents)';
  }
}
